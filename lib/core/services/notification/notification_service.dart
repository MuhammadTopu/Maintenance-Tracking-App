import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart' show openAppSettings;
import 'package:shared_preferences/shared_preferences.dart';

// =============================================================================
// notification service (FCM + flutter_local_notifications v22+).
//
// Handles in one place:
//   * Permissions (request / check / open system settings)
//   * Local notification setup + Android channel
//   * Foreground messages (shown as local notifications)
//   * Background data-only messages (shown as local notifications)
//   * Tap handling: foreground, background, terminated (FCM + local)
//   * FCM token: fetch, cache, refresh, clear on logout, iOS APNs wait/retry
//   * Topics, show/cancel helpers, optional "clear tray on resume"
//
// Depends only on: firebase_core, firebase_messaging, flutter_local_notifications,
// shared_preferences, permission_handler. No project-specific imports, so it
// can be copied between projects as-is.
// =============================================================================

/// Per-app settings. Create ONE const instance and share it between
/// `main()` and the background handler (they run in different isolates).
class NotificationConfig {
  const NotificationConfig({
    this.channelId = 'high_importance_channel',
    this.channelName = 'High Importance Notifications',
    this.channelDescription = 'Used for important notifications.',
    this.androidSmallIcon = '@mipmap/ic_launcher',
    this.accentColor,
    this.summaryText,
    this.defaultTitle = 'Notification',
    this.clearTrayOnResume = false,
    this.requestPermissionOnInit = true,
    this.tokenPrefsKey = 'fcm_token',
  });

  final String channelId;
  final String channelName;
  final String channelDescription;

  /// Android small icon resource. Ideally a white-on-transparent drawable
  /// (e.g. '@drawable/ic_notification'); launcher icon is the fallback.
  final String androidSmallIcon;

  /// Android accent color for the notification.
  final Color? accentColor;

  /// Small summary line under the big text (Android). Usually the app name.
  final String? summaryText;

  final String defaultTitle;

  /// Remove all tray notifications whenever the app returns to foreground.
  final bool clearTrayOnResume;

  /// Ask for notification permission inside [NotificationService.initialize].
  /// Set to false if you want to show your own pre-permission screen and
  /// call [NotificationService.requestPermissions] later.
  final bool requestPermissionOnInit;

  /// SharedPreferences key used to cache the FCM token.
  final String tokenPrefsKey;
}

class NotificationService with WidgetsBindingObserver {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  NotificationConfig _config = const NotificationConfig();

  final FlutterLocalNotificationsPlugin _local =
  FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _localReady = false;
  bool _tokenRefreshAttached = false;

  SharedPreferences? _prefs;
  String? _cachedToken;
  Future<String?>? _syncInFlight;

  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<RemoteMessage>? _openedSub;
  StreamSubscription<String>? _tokenRefreshSub;

  /// A tap that happened before the app registered a tap handler
  /// (cold start). Delivered as soon as [onNotificationTap] is assigned.
  Map<String, dynamic>? _pendingTap;
  void Function(Map<String, dynamic> data)? _onNotificationTap;

  // ---------------------------------------------------------------------------
  // Hooks the app can set (all optional)
  // ---------------------------------------------------------------------------

  /// Called with the notification's data whenever a notification is tapped
  /// (foreground, background or terminated). Use it to navigate.
  void Function(Map<String, dynamic> data)? get onNotificationTap =>
      _onNotificationTap;

  set onNotificationTap(void Function(Map<String, dynamic> data)? handler) {
    _onNotificationTap = handler;
    final pending = _pendingTap;
    if (handler != null && pending != null) {
      _pendingTap = null;
      _safeCall(() => handler(pending), 'onNotificationTap');
    }
  }

  /// Called after a push arrives while the app is in the foreground
  /// (e.g. refresh the notification list / unread badge).
  Future<void> Function(RemoteMessage message)? onMessageReceived;

  /// Returns the unread count, used for the Android notification number.
  Future<int> Function()? onGetUnreadCount;

  /// Called when Firebase rotates the FCM token. Send the new token to your
  /// backend here. NOTE: it can also fire right after [clearFcmToken] (a new
  /// token is generated), so check that a user is logged in before uploading.
  Future<void> Function(String token)? onTokenRefreshed;

  // ---------------------------------------------------------------------------
  // Basics
  // ---------------------------------------------------------------------------

  FirebaseMessaging? get _messaging {
    if (Firebase.apps.isEmpty) {
      debugPrint('[Notifications] Firebase is not initialized. Skipping.');
      return null;
    }
    return FirebaseMessaging.instance;
  }

  AndroidNotificationChannel get _androidChannel => AndroidNotificationChannel(
    _config.channelId,
    _config.channelName,
    description: _config.channelDescription,
    importance: Importance.max,
  );

  // ---------------------------------------------------------------------------
  // Bootstrap — call once in main(), after Firebase.initializeApp() and after
  // FirebaseMessaging.onBackgroundMessage(...) has been registered.
  // ---------------------------------------------------------------------------

  Future<void> initialize({
    NotificationConfig config = const NotificationConfig(),
    void Function(Map<String, dynamic> data)? onNotificationTap,
    Future<void> Function(RemoteMessage message)? onMessageReceived,
    Future<int> Function()? onGetUnreadCount,
    Future<void> Function(String token)? onTokenRefreshed,
  }) async {
    if (_initialized) return;

    final messaging = _messaging;
    if (messaging == null) return;

    _initialized = true;
    _config = config;
    if (onMessageReceived != null) this.onMessageReceived = onMessageReceived;
    if (onGetUnreadCount != null) this.onGetUnreadCount = onGetUnreadCount;
    if (onTokenRefreshed != null) this.onTokenRefreshed = onTokenRefreshed;
    if (onNotificationTap != null) _onNotificationTap = onNotificationTap;

    _prefs = await SharedPreferences.getInstance();
    _cachedToken = _prefs?.getString(config.tokenPrefsKey);

    await _ensureLocalNotifications();
    if (config.requestPermissionOnInit) await requestPermissions();
    await _setupMessageListeners(messaging);
    await _handleLocalNotificationLaunch();

    if (config.clearTrayOnResume) {
      WidgetsBinding.instance.addObserver(this);
    }

    // Deliberately NOT awaited: on iOS this can wait for the APNs token
    // (up to 15s, never on simulators). It must never delay app start.
    unawaited(syncFcmToken());
  }

  /// Cancel listeners. Rarely needed (the service lives as long as the app).
  Future<void> dispose() async {
    await _onMessageSub?.cancel();
    await _openedSub?.cancel();
    await _tokenRefreshSub?.cancel();
    _onMessageSub = _openedSub = null;
    _tokenRefreshSub = null;
    _tokenRefreshAttached = false;
    WidgetsBinding.instance.removeObserver(this);
    _initialized = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _config.clearTrayOnResume) {
      unawaited(cancelAllNotifications());
    }
  }

  // ---------------------------------------------------------------------------
  // Permissions
  // ---------------------------------------------------------------------------

  /// Requests notification permission (iOS prompt / Android 13+ prompt).
  /// Returns true if authorized or provisional.
  Future<bool> requestPermissions() async {
    final messaging = _messaging;
    if (messaging == null) return false;

    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    final granted =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional;
    debugPrint('[Notifications] Permission granted: $granted '
        '(${settings.authorizationStatus.name})');
    return granted;
  }

  /// Current permission state without prompting.
  Future<bool> areNotificationsEnabled() async {
    final messaging = _messaging;
    if (messaging == null) return false;
    final settings = await messaging.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  /// Opens the app's system settings page (use when permission is denied).
  Future<void> openNotificationSettings() async {
    await openAppSettings();
  }

  // ---------------------------------------------------------------------------
  // Local notifications setup
  // ---------------------------------------------------------------------------

  Future<void> _ensureLocalNotifications() async {
    if (_localReady) return;

    await _local.initialize(
      settings: InitializationSettings(
        android: AndroidInitializationSettings(_config.androidSmallIcon),
        // Permission is requested through FCM, not here.
        iOS: const DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: _onLocalNotificationResponse,
    );

    await _local
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);

    _localReady = true;
  }

  void _onLocalNotificationResponse(NotificationResponse response) {
    debugPrint('[Notifications] Local notification tapped.');
    _dispatchTap(_decodePayload(response.payload));
  }

  /// App was killed and launched by tapping a *local* notification
  /// (e.g. one we displayed for a data-only background message).
  Future<void> _handleLocalNotificationLaunch() async {
    final details = await _local.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp ?? false) {
      _dispatchTap(_decodePayload(details!.notificationResponse?.payload));
    }
  }

  // ---------------------------------------------------------------------------
  // FCM listeners: foreground / opened-from-background / opened-from-terminated
  // ---------------------------------------------------------------------------

  Future<void> _setupMessageListeners(FirebaseMessaging messaging) async {
    // We show foreground messages ourselves (local notification), so the
    // system must not also show one on iOS (would duplicate).
    await messaging.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: false,
      sound: false,
    );

    _onMessageSub = FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // Backgrounded app, user tapped the system notification.
    _openedSub = FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('[Notifications] Opened from background: ${message.messageId}');
      _dispatchTap(Map<String, dynamic>.from(message.data));
    });

    // Terminated app, user tapped the system notification.
    final initial = await messaging.getInitialMessage();
    if (initial != null) {
      debugPrint('[Notifications] Launched from terminated: '
          '${initial.messageId}');
      _dispatchTap(Map<String, dynamic>.from(initial.data));
    }
  }

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    await _showFromRemoteMessage(message);
    final hook = onMessageReceived;
    if (hook != null) {
      await _safeCallAsync(() => hook(message), 'onMessageReceived');
    }
  }

  // ---------------------------------------------------------------------------
  // Background messages
  //
  // Register in main.dart with a top-level function (see main.dart):
  //
  //   @pragma('vm:entry-point')
  //   Future<void> _bgHandler(RemoteMessage m) async {
  //     await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  //     await NotificationService.handleBackgroundMessage(m, config: kNotificationConfig);
  //   }
  //
  // This runs in a separate isolate, so nothing set in main() exists here.
  // ---------------------------------------------------------------------------

  static Future<void> handleBackgroundMessage(
      RemoteMessage message, {
        NotificationConfig config = const NotificationConfig(),
      }) async {
    debugPrint('[Notifications] Background message: ${message.messageId}');

    // Messages with a `notification` block are displayed by the OS itself.
    // Showing them again here would create duplicates.
    if (message.notification != null) return;

    final service = instance;
    service._config = config;
    await service._showFromRemoteMessage(message);
  }

  // ---------------------------------------------------------------------------
  // Showing notifications
  // ---------------------------------------------------------------------------

  static int _idFromServerId(String serverId) => serverId.hashCode & 0x7FFFFFFF;

  Future<void> _showFromRemoteMessage(RemoteMessage message) async {
    final remote = message.notification;
    final title = remote?.title ?? message.data['title']?.toString();
    final body = remote?.body ?? message.data['body']?.toString();

    if ((title == null || title.isEmpty) && (body == null || body.isEmpty)) {
      return;
    }

    final serverId = message.data['id']?.toString();
    final id = serverId != null && serverId.isNotEmpty
        ? _idFromServerId(serverId)
        : DateTime.now().millisecondsSinceEpoch & 0x7FFFFFFF;

    await _show(
      id: id,
      title: (title == null || title.isEmpty) ? _config.defaultTitle : title,
      body: body ?? '',
      payload: jsonEncode(message.data),
    );
  }

  /// Show a notification manually (e.g. a local reminder, or a custom event).
  /// [data] is delivered to [onNotificationTap] when the user taps it.
  Future<void> showLocalNotification({
    int? id,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) {
    return _show(
      id: id ?? (DateTime.now().millisecondsSinceEpoch & 0x7FFFFFFF),
      title: title,
      body: body,
      payload: data == null ? null : jsonEncode(data),
    );
  }

  Future<void> _show({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _ensureLocalNotifications();

    int badge = 1;
    final unread = onGetUnreadCount;
    if (unread != null) {
      try {
        badge = await unread();
      } catch (e) {
        debugPrint('[Notifications] onGetUnreadCount failed: $e');
      }
    }

    await _local.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _config.channelId,
          _config.channelName,
          channelDescription: _config.channelDescription,
          importance: Importance.max,
          priority: Priority.high,
          icon: _config.androidSmallIcon,
          color: _config.accentColor,
          number: badge,
          styleInformation: BigTextStyleInformation(
            body,
            contentTitle: title,
            summaryText: _config.summaryText,
          ),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  // ---------------------------------------------------------------------------
  // Tap dispatching
  // ---------------------------------------------------------------------------

  Map<String, dynamic>? _decodePayload(String? payload) {
    if (payload == null || payload.isEmpty) return null;
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {
      // Not JSON: treat the raw string as a notification id.
    }
    return {'id': payload};
  }

  void _dispatchTap(Map<String, dynamic>? data) {
    if (data == null) return;
    final handler = _onNotificationTap;
    if (handler == null) {
      _pendingTap = data; // delivered when a handler is assigned
      return;
    }
    _safeCall(() => handler(data), 'onNotificationTap');
  }

  // ---------------------------------------------------------------------------
  // FCM token
  // ---------------------------------------------------------------------------

  /// Token cached on this device (null before the first successful fetch
  /// and after [clearFcmToken]). Synchronous.
  String? get currentFcmToken => _cachedToken;

  /// Fetches the current FCM token, caches it and returns it. Concurrent
  /// calls share one in-flight request. Safe to call any time.
  Future<String?> syncFcmToken() {
    return _syncInFlight ??= _doSyncFcmToken().whenComplete(() {
      _syncInFlight = null;
    });
  }

  /// Use this in the login request. Never blocks longer than [timeout] and
  /// falls back to the cached token.
  Future<String?> getTokenForLogin({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    try {
      final token = await syncFcmToken().timeout(timeout);
      return token ?? _cachedToken;
    } catch (e) {
      debugPrint('[Notifications] getTokenForLogin fallback: $e');
      return _cachedToken;
    }
  }

  Future<String?> _doSyncFcmToken() async {
    final messaging = _messaging;
    if (messaging == null) return _cachedToken;

    try {
      await messaging.setAutoInitEnabled(true);
      _attachTokenRefreshListener(messaging);

      if (Platform.isIOS) {
        final apnsReady = await _waitForApnsToken(messaging);
        if (!apnsReady) {
          debugPrint('[Notifications] APNs token not ready (iOS). '
              'Retrying in background.');
          unawaited(_retryTokenFetchAfterApnsReady(messaging));
          return _cachedToken;
        }
      }
      return await _fetchAndPersistFcmToken(messaging);
    } catch (e) {
      debugPrint('[Notifications] FCM token sync failed: $e');
      return _cachedToken;
    }
  }

  Future<bool> _waitForApnsToken(FirebaseMessaging messaging) async {
    const timeout = Duration(seconds: 15);
    const pollInterval = Duration(milliseconds: 500);
    final startedAt = DateTime.now();

    while (DateTime.now().difference(startedAt) < timeout) {
      final apns = await messaging.getAPNSToken();
      if (apns != null && apns.isNotEmpty) return true;
      await Future.delayed(pollInterval);
    }
    return false;
  }

  Future<void> _retryTokenFetchAfterApnsReady(
      FirebaseMessaging messaging,
      ) async {
    const maxAttempts = 12;
    for (var i = 0; i < maxAttempts; i++) {
      await Future.delayed(const Duration(seconds: 5));
      final apns = await messaging.getAPNSToken();
      if (apns != null && apns.isNotEmpty) {
        final token = await _fetchAndPersistFcmToken(messaging);
        // First token on iOS arrived late: let the app upload it.
        final hook = onTokenRefreshed;
        if (token != null && hook != null) {
          await _safeCallAsync(() => hook(token), 'onTokenRefreshed');
        }
        return;
      }
    }
    debugPrint('[Notifications] APNs retry stopped: token still unavailable.');
  }

  Future<String?> _fetchAndPersistFcmToken(FirebaseMessaging messaging) async {
    final token = await messaging.getToken();
    if (kDebugMode) dev.log('FCM token: $token', name: 'Notifications');

    if (token == null || token.isEmpty) {
      debugPrint('[Notifications] FCM token is empty. Check Firebase/APNs '
          'configuration and connectivity.');
      return token;
    }
    await _persistToken(token);
    return token;
  }

  Future<void> _persistToken(String token) async {
    _cachedToken = token;
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    await prefs.setString(_config.tokenPrefsKey, token);
  }

  void _attachTokenRefreshListener(FirebaseMessaging messaging) {
    if (_tokenRefreshAttached) return;
    _tokenRefreshAttached = true;
    _tokenRefreshSub = messaging.onTokenRefresh.listen((token) async {
      if (token.isEmpty) return;
      await _persistToken(token);
      debugPrint('[Notifications] FCM token refreshed.');
      final hook = onTokenRefreshed;
      if (hook != null) {
        await _safeCallAsync(() => hook(token), 'onTokenRefreshed');
      }
    });
  }

  /// Call on logout so the old token isn't tied to the previous user.
  /// The next [syncFcmToken] / [getTokenForLogin] generates a fresh token.
  Future<void> clearFcmToken() async {
    try {
      await _messaging?.deleteToken();
    } catch (e) {
      debugPrint('[Notifications] deleteToken failed: $e');
    }
    _cachedToken = null;
    _syncInFlight = null;
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    await prefs.remove(_config.tokenPrefsKey);
  }

  // ---------------------------------------------------------------------------
  // Topics
  // ---------------------------------------------------------------------------

  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging?.subscribeToTopic(topic);
    } catch (e) {
      debugPrint('[Notifications] subscribeToTopic($topic) failed: $e');
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging?.unsubscribeFromTopic(topic);
    } catch (e) {
      debugPrint('[Notifications] unsubscribeFromTopic($topic) failed: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Cancel tray notifications
  // ---------------------------------------------------------------------------

  Future<void> cancelNotification(String serverId) async {
    await _ensureLocalNotifications();
    await _local.cancel(id: _idFromServerId(serverId));
  }

  Future<void> cancelNotifications(List<String> serverIds) async {
    await _ensureLocalNotifications();
    for (final id in serverIds) {
      await _local.cancel(id: _idFromServerId(id));
    }
  }

  Future<void> cancelAllNotifications() async {
    await _ensureLocalNotifications();
    await _local.cancelAll();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  void _safeCall(void Function() fn, String label) {
    try {
      fn();
    } catch (e, st) {
      debugPrint('[Notifications] $label failed: $e\n$st');
    }
  }

  Future<void> _safeCallAsync(Future<void> Function() fn, String label) async {
    try {
      await fn();
    } catch (e, st) {
      debugPrint('[Notifications] $label failed: $e\n$st');
    }
  }
}