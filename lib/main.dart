import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'app/routes/route_configs.dart';
import 'app/session_expired_listener.dart';
import 'core/constants/subscription_constants.dart';
import 'core/di/di_configs.dart';
import 'core/providers/app_providers.dart';
import 'core/services/navigation_service.dart';
import 'core/services/notification/notification_service.dart';
import 'core/services/subscription/subscription_service.dart';
import 'firebase_options.dart';

/// One instance for the whole app.
final SubscriptionService subscriptionService = SubscriptionService(
  config: const SubscriptionConfig(
    // Entitlement identifier from RevenueCat → Product catalog → Entitlements.
    entitlementId: entitlementID,
    // RevenueCat → Project settings → API keys (public SDK keys).
    androidApiKey: googleApiKey,
    iosApiKey: 'appl_REPLACE_ME',
    androidPackageName: 'com.biglickenterprises.maintenancegenie',
  ),
);

/// Shared by main() and the background isolate, so it must be const.
const NotificationConfig kNotificationConfig = NotificationConfig(
  channelId: 'high_importance_channel',
  channelName: 'High Importance Notifications',
  channelDescription: 'Used for important notifications.',
  summaryText: 'Maintenance Genie',
);

/// Background / terminated FCM handler.
/// Must be top-level and annotated, and it runs in its own isolate, so
/// Firebase has to be initialized again here.
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    await NotificationService.handleBackgroundMessage(
      message,
      config: kNotificationConfig,
    );
  } catch (e) {
    debugPrint('Background handler failed: $e');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeApp();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Register BEFORE runApp and before NotificationService.initialize().
  FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

  await NotificationService.instance.initialize(
    config: kNotificationConfig,
    onNotificationTap: _handleNotificationTap,

    // Optional: refresh your notification list / unread badge on foreground push.
    // onMessageReceived: (message) async {
    //   final ctx = navigatorKey.currentContext;
    //   if (ctx == null) return;
    //   await ctx.read<NotificationProvider>().fetchNotifications();
    // },

    // Optional: unread count shown as the Android notification number.
    // onGetUnreadCount: () async {
    //   final ctx = navigatorKey.currentContext;
    //   return ctx?.read<NotificationProvider>().unreadCount ?? 1;
    // },

    // Optional: push a rotated token to the backend while logged in.
    // onTokenRefreshed: (token) async {
    //   final loggedIn = await TokenStorageService.instance.getToken() != null;
    //   if (!loggedIn) return;
    //   await authRepository.updateFcmToken(token); // needs a backend endpoint
    // },
  );

  // Not awaited on purpose: a slow network must never delay app start.
  unawaited(subscriptionService.init());

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SubscriptionService>.value(
          value: subscriptionService,
        ),
        ...AppViewModels.viewModels,
      ],
      child: const MyApp(),
    ),
  );
}

Future<void> _initializeApp() async {
  try {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    await ScreenUtil.ensureScreenSize();
    await diConfig();
  } catch (e, stackTrace) {
    debugPrint('Initialization Error: $e');
    debugPrintStack(stackTrace: stackTrace);
  }
}

// -----------------------------------------------------------------------------
// Notification tap → navigation
// -----------------------------------------------------------------------------

/// Called for taps from foreground, background AND terminated state.
/// Adjust the payload keys and routes to match what your backend sends.
void _handleNotificationTap(Map<String, dynamic> data) {
  final type = data['type']?.toString();
  final taskId = (data['task_id'] ?? data['id'])?.toString();

  _runWhenNavigatorReady(() {
    debugPrint('Notification tapped: type=$type id=$taskId');

    // TODO: replace with your real routes + arguments, e.g.
    // if (type == 'task_due' && taskId != null) {
    //   navigatorKey.currentState?.pushNamed(
    //     RouteName.trackingDetailScreen,
    //     arguments: taskId,
    //   );
    // }
  });
}

/// On a cold start the tap fires before the Navigator exists, so wait for it.
void _runWhenNavigatorReady(VoidCallback action) {
  if (navigatorKey.currentState != null) {
    action();
    return;
  }
  Timer.periodic(const Duration(milliseconds: 200), (timer) {
    if (navigatorKey.currentState != null) {
      timer.cancel();
      action();
    } else if (timer.tick > 50) {
      timer.cancel(); // give up after ~10s
    }
  });
}

// -----------------------------------------------------------------------------
// App
// -----------------------------------------------------------------------------

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      rebuildFactor: RebuildFactors.none,
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, __) {
        return MaterialApp(
          theme: ThemeData(
            scaffoldBackgroundColor: Colors.white,
          ),
          themeMode: ThemeMode.light,
          debugShowCheckedModeBanner: false,
          navigatorKey: navigatorKey,
          initialRoute: AppRoutes.initialRoute,
          onGenerateRoute: AppRoutes.onGenerateRoute,
          navigatorObservers: [HeroController()],
          builder: (context, child) {
            return _SubscriptionLifecycleListener(
              child: SessionExpiredListener(child: child!),
            );
          },
        );
      },
    );
  }
}

/// Refreshes subscription state whenever the app returns to the foreground
/// (after the store's manage-subscription page, renewals, expiry, etc.).
class _SubscriptionLifecycleListener extends StatefulWidget {
  const _SubscriptionLifecycleListener({required this.child});

  final Widget child;

  @override
  State<_SubscriptionLifecycleListener> createState() =>
      _SubscriptionLifecycleListenerState();
}

class _SubscriptionLifecycleListenerState
    extends State<_SubscriptionLifecycleListener> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(subscriptionService.onAppResumed());
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}