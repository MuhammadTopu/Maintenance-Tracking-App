import 'package:flutter/material.dart';
import 'package:maintenance_genie/presentation/view/auth/login/login_screen.dart';

import '../../presentation/view/splash/splash_screen.dart';
import 'route_names.dart';

class AppRoutes {
  static String initialRoute = RouteName.splash;

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteName.splash:
        return _buildRoute(const SplashScreen());

      case RouteName.login:
        return _buildRoute(const LoginScreen());

      default:
        return _buildRoute(const UnknownRouteScreen());
    }
  }

  static PageRouteBuilder _buildRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,

      transitionDuration: const Duration(milliseconds: 350),

      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        );

        return FadeTransition(
          opacity: curvedAnimation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(curvedAnimation),
            child: child,
          ),
        );
      },
    );
  }
}

class UnknownRouteScreen extends StatelessWidget {
  final String? routeName;

  const UnknownRouteScreen({super.key, this.routeName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Route Error')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'No route defined for:\n$routeName',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    RouteName.splash, // or RouteName.login
                        (route) => false,
                  );
                },
                child: const Text('Go to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
