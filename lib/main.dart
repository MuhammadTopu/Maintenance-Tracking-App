import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'app/controller/auth_session_handler.dart';
import 'app/controller/notification_navigator.dart';
import 'app/routes/route_configs.dart';
import 'core/constants/subscription_constants.dart';
import 'core/di/di_configs.dart';
import 'core/providers/app_providers.dart';
import 'core/services/navigation_service.dart';
import 'core/services/notification/notification_service.dart';
import 'core/services/role/role_service.dart';
import 'core/services/subscription/subscription_service.dart';
import 'firebase_options.dart';
import 'presentation/view_models/notification_provider.dart';

final SubscriptionService subscriptionService = SubscriptionService(
  config: const SubscriptionConfig(
    entitlementId: entitlementID,
    androidApiKey: googleApiKey,
    iosApiKey: 'appl_REPLACE_ME',
    androidPackageName: 'com.biglickenterprises.maintenancegenie',
  ),
);

const NotificationConfig kNotificationConfig = NotificationConfig(
  channelId: 'high_importance_channel',
  channelName: 'High Importance Notifications',
  channelDescription: 'Used for important notifications.',
  summaryText: 'Maintenance Genie',
);

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

    // NOTIFICATIONS: tray tap (foreground / background / terminated).
    onNotificationTap: NotificationNavigator.instance.handleTap,

    // NOTIFICATIONS: a push arrived while the app is open -> the list and the
    // badge update immediately.
    onMessageReceived: (message) async {
      final context = navigatorKey.currentContext;
      if (context == null) return;
      await context.read<NotificationProvider>().onPushReceived();
    },

    // NOTIFICATIONS: number shown on the Android notification. This runs just
    // BEFORE the list refresh, so count the notification being shown too.
    onGetUnreadCount: () async {
      final context = navigatorKey.currentContext;
      if (context == null) return 1;
      final provider = context.read<NotificationProvider>();
      if (!provider.isActive) return 1;
      return (provider.unreadCount + 1).clamp(1, 99).toInt();
    },

    // Optional: push a rotated token to the backend while logged in.
    // onTokenRefreshed: (token) async {
    //   final loggedIn = await TokenStorageService.instance.getToken() != null;
    //   if (!loggedIn) return;
    //   await authRepository.updateFcmToken(token); // needs a backend endpoint
    // },
  );

  final roleService = RoleService(subscription: subscriptionService);
  unawaited(subscriptionService.init());

  AuthSessionHandler.instance.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SubscriptionService>.value(
          value: subscriptionService,
        ),
        ChangeNotifierProvider<RoleService>.value(value: roleService),
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
          builder: (context, child) => _AppLifecycleListener(child: child!),
        );
      },
    );
  }
}

class _AppLifecycleListener extends StatefulWidget {
  const _AppLifecycleListener({required this.child});

  final Widget child;

  @override
  State<_AppLifecycleListener> createState() => _AppLifecycleListenerState();
}

class _AppLifecycleListenerState extends State<_AppLifecycleListener>
    with WidgetsBindingObserver {
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
      unawaited(context.read<NotificationProvider>().refresh());
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}