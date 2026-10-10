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
    androidPackageName: 'com.biglickenterprises.maintenancegenie', // your applicationId
  ),
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeApp();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await NotificationService.instance.initialize();

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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
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