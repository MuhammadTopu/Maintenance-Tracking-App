import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../navigation_service.dart';
import '../storage/shared_pref_service.dart';

/// Top-level background handler — REQUIRED by firebase_messaging to be a
/// top-level (or static) function, and must be registered before runApp().
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // No UI work here — the OS shows the notification automatically for
  // data+notification payloads. Use this only for background data sync,
  // e.g. updating a local badge count or a lightweight cache write.
  debugPrint('Background message received: ${message.messageId}');
}

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const String _fcmTokenPrefsKey = 'fcm_token';

  static final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _androidChannel =
  AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'Used for important notifications.',
    importance: Importance.max,
  );

  bool _isLocalNotificationInitialized = false;
  bool _isTokenRefreshListenerAttached = false;

  /// Optional hooks the app can set from outside (e.g. to refresh an
  /// unread-count badge or refetch a list after a push arrives).
  Future<void> Function()? onMessageReceived;
  Future<int> Function()? onGetUnreadCount;

  FirebaseMessaging? get _messaging {
    if (Firebase.apps.isEmpty) {
      debugPrint('Firebase is not initialized. Skipping notification setup.');
      return null;
    }
    return FirebaseMessaging.instance;
  }

  // ---------------------------------------------------------------------
  // Bootstrap — call once from main.dart after Firebase.initializeApp()
  // ---------------------------------------------------------------------

  Future<void> initialize() async {
    final messaging = _messaging;
    if (messaging == null) return;

    await _initializeLocalNotifications();
    await _requestPermissions(messaging);
    await _initializeForegroundHandlers(messaging);
    await syncFcmToken();
  }

  // ---------------------------------------------------------------------
  // Permissions
  // ---------------------------------------------------------------------

  Future<void> _requestPermissions(FirebaseMessaging messaging) async {
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    switch (settings.authorizationStatus) {
      case AuthorizationStatus.authorized:
        debugPrint('Notification permission granted.');
        break;
      case AuthorizationStatus.provisional:
        debugPrint('Notification permission granted provisionally.');
        break;
      default:
        debugPrint('Notification permission denied.');
    }
  }

  // ---------------------------------------------------------------------
  // Local notifications setup
  // ---------------------------------------------------------------------

  Future<void> _initializeLocalNotifications() async {
    if (_isLocalNotificationInitialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // v22+ API: `initialize()` now takes fully named parameters.
    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTapped,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);

    _isLocalNotificationInitialized = true;
  }

  void _onLocalNotificationTapped(NotificationResponse response) {
    debugPrint('Local notification tapped: ${response.payload}');
    _handleNotificationNavigation(payload: response.payload);
  }

  // ---------------------------------------------------------------------
  // Foreground / opened-app / terminated-state handling
  // ---------------------------------------------------------------------

  Future<void> _initializeForegroundHandlers(FirebaseMessaging messaging) async {
    // Foreground messages are shown via flutter_local_notifications instead
    // of Firebase's default banner, to avoid duplicate notifications on iOS.
    await messaging.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: false,
      sound: false,
    );

    FirebaseMessaging.onMessage.listen((message) async {
      await _showNotificationFromRemoteMessage(message);
      try {
        await onMessageReceived?.call();
      } catch (e, st) {
        debugPrint('onMessageReceived callback failed: $e\n$st');
      }
    });

    // App was backgrounded, user tapped a system notification to reopen it.
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('Notification opened app: ${message.messageId}');
      _handleNotificationNavigation(data: message.data);
    });

    // App was fully killed, user tapped a system notification to launch it.
    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint(
        'App launched from terminated state via notification: '
            '${initialMessage.messageId}',
      );
      _handleNotificationNavigation(data: initialMessage.data);
    }
  }

  /// Central place for "what screen should a tapped notification open".
  /// Adjust the keys/routes to match your actual payload + route names.
  void _handleNotificationNavigation({Map<String, dynamic>? data, String? payload}) {
    // Example convention: backend sends {"type": "task_due", "task_id": "..."}
    final type = data?['type'] as String?;
    final taskId = data?['task_id'] as String?;

    if (type == 'task_due' && taskId != null) {
      // TODO: replace with your real route + arguments.
      // navigatorKey.currentState?.pushNamed(
      //   RouteName.trackingDetailScreen,
      //   arguments: taskId,
      // );
    }
  }

  // ---------------------------------------------------------------------
  // FCM token management
  // ---------------------------------------------------------------------

  /// The token currently cached on-device. Read this when building your
  /// login request body — the backend receives the token as part of login,
  /// not via a separate upload call.
  String? get currentFcmToken => SharedPrefService.getString(_fcmTokenPrefsKey);

  /// Fetches the current FCM token and persists it locally.
  /// Safe to call on every app start, before or after login.
  Future<String?> syncFcmToken() async {
    final messaging = _messaging;
    if (messaging == null) {
      debugPrint('FCM skipped: Firebase app not initialized.');
      return null;
    }

    try {
      await messaging.setAutoInitEnabled(true);
      _attachTokenRefreshListener(messaging);

      if (Platform.isIOS) {
        final apnsReady = await _waitForApnsToken(messaging);
        if (!apnsReady) {
          debugPrint('FCM skipped: APNS token not available yet on iOS.');
          unawaited(_retryTokenFetchAfterApnsReady(messaging));
          return currentFcmToken;
        }
      }

      return await _fetchAndPersistFcmToken(messaging);
    } catch (e) {
      debugPrint('FCM token sync failed: $e');
      return null;
    }
  }

  Future<bool> _waitForApnsToken(FirebaseMessaging messaging) async {
    const timeout = Duration(seconds: 15);
    const pollInterval = Duration(milliseconds: 500);
    final startedAt = DateTime.now();

    while (DateTime.now().difference(startedAt) < timeout) {
      final apnsToken = await messaging.getAPNSToken();
      if (apnsToken != null && apnsToken.isNotEmpty) return true;
      await Future.delayed(pollInterval);
    }
    return false;
  }

  Future<void> _retryTokenFetchAfterApnsReady(FirebaseMessaging messaging) async {
    const maxAttempts = 12;
    for (var i = 0; i < maxAttempts; i++) {
      await Future.delayed(const Duration(seconds: 5));
      final apnsToken = await messaging.getAPNSToken();
      if (apnsToken != null && apnsToken.isNotEmpty) {
        await _fetchAndPersistFcmToken(messaging);
        return;
      }
    }
    debugPrint('FCM retry stopped: APNS token still unavailable.');
  }

  Future<String?> _fetchAndPersistFcmToken(FirebaseMessaging messaging) async {
    final token = await messaging.getToken();
    log('FCM token: $token');

    if (token == null || token.isEmpty) {
      debugPrint('FCM token is null/empty — check Firebase/APNS config.');
      return token;
    }

    await SharedPrefService.setString(_fcmTokenPrefsKey, token);
    debugPrint('FCM token saved locally.');
    return token;
  }

  void _attachTokenRefreshListener(FirebaseMessaging messaging) {
    if (_isTokenRefreshListenerAttached) return;
    _isTokenRefreshListenerAttached = true;
    messaging.onTokenRefresh.listen((token) async {
      if (token.isEmpty) return;
      await SharedPrefService.setString(_fcmTokenPrefsKey, token);
      debugPrint('FCM token refreshed and saved.');
      // NOTE: if a user can already be logged in when this fires (i.e. the
      // token rotates mid-session, not just at login), you'll want to push
      // the new token to the backend here too — e.g. via a dedicated
      // "update fcm token" endpoint or by re-hitting your profile update
      // call, guarded by checking there's an active auth session.
    });
  }

  /// Call this on logout so the old token isn't tied to the wrong user.
  Future<void> clearFcmToken() async {
    try {
      await _messaging?.deleteToken();
    } catch (e) {
      debugPrint('Failed to delete FCM token on logout: $e');
    }
    await SharedPrefService.remove(_fcmTokenPrefsKey);
  }

  // ---------------------------------------------------------------------
  // Show notification (foreground)
  // ---------------------------------------------------------------------

  static int _idFromServerId(String serverId) => serverId.hashCode & 0x7FFFFFFF;

  Future<void> _showNotificationFromRemoteMessage(RemoteMessage message) async {
    await _initializeLocalNotifications();

    final remoteNotification = message.notification;
    final title = remoteNotification?.title ?? message.data['title']?.toString();
    final body = remoteNotification?.body ?? message.data['body']?.toString();

    if ((title == null || title.isEmpty) && (body == null || body.isEmpty)) {
      return;
    }

    final serverId = message.data['id']?.toString();
    final notificationId = serverId != null
        ? _idFromServerId(serverId)
        : DateTime.now().millisecondsSinceEpoch & 0x7FFFFFFF;

    final badgeCount = await onGetUnreadCount?.call() ?? 1;

    // v22+ API: `show()` now takes fully named parameters
    // (id, title, body, notificationDetails, payload).
    await _localNotifications.show(
      id: notificationId,
      title: title ?? 'Notification',
      body: body ?? '',
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          number: badgeCount,
          styleInformation: BigTextStyleInformation(
            body ?? '',
            contentTitle: title ?? 'Notification',
          ),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: message.data['id']?.toString(),
    );
  }

  // ---------------------------------------------------------------------
  // Cancel tray notifications
  // ---------------------------------------------------------------------

  Future<void> cancelNotification(String serverId) async {
    await _initializeLocalNotifications();
    // v22+ API: `cancel()` now takes a named `id` parameter.
    await _localNotifications.cancel(id: _idFromServerId(serverId));
  }

  Future<void> cancelNotifications(List<String> serverIds) async {
    await _initializeLocalNotifications();
    for (final id in serverIds) {
      await _localNotifications.cancel(id: _idFromServerId(id));
    }
  }

  Future<void> cancelAllNotifications() async {
    await _initializeLocalNotifications();
    await _localNotifications.cancelAll();
  }
}