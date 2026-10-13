import 'package:flutter/material.dart';
import 'package:maintenance_genie/presentation/view/auth/forget_pass/forget_password_screen.dart';
import 'package:maintenance_genie/presentation/view/auth/forget_pass/reset_pass_otp_screen.dart';
import 'package:maintenance_genie/presentation/view/auth/forget_pass/reset_password_screen.dart';
import 'package:maintenance_genie/presentation/view/auth/login/login_screen.dart';
import 'package:maintenance_genie/presentation/view/auth/sign_up/sign_up_info_screen.dart';
import 'package:maintenance_genie/presentation/view/auth/sign_up/sign_up_screen.dart';
import 'package:maintenance_genie/presentation/view/auth/sign_up/verify_email_otp_screen.dart';
import 'package:maintenance_genie/presentation/view/items/add_item_screen.dart';
import 'package:maintenance_genie/presentation/view/items/item_details_screen.dart';
import 'package:maintenance_genie/presentation/view/parent/screen/parent_screen.dart';
import 'package:maintenance_genie/presentation/view/profile/general/edit_profile.dart';
import 'package:maintenance_genie/presentation/view/profile/general/security.dart';
import 'package:maintenance_genie/presentation/view/profile/support_and_about/about.dart';
import 'package:maintenance_genie/presentation/view/profile/support_and_about/frequently_asked_questions.dart';
import 'package:maintenance_genie/presentation/view/profile/support_and_about/privacy_policy.dart';
import 'package:maintenance_genie/presentation/view/profile/support_and_about/support.dart';
import 'package:maintenance_genie/presentation/view/profile/support_and_about/support_next.dart';
import 'package:maintenance_genie/presentation/view/profile/support_and_about/terms_and_conditions.dart';
import 'package:maintenance_genie/presentation/view/tracking/tracking_detail_screen.dart';

import '../../presentation/view/items/item_add_question_screen.dart';
import '../../presentation/view/profile/subscription/subscription_screen.dart';
import '../../presentation/view/splash/splash_screen.dart';
import 'route_names.dart';

class AppRoutes {
  static String initialRoute = RouteName.splash;

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteName.splash:
        return _buildRoute(const SplashScreen(), settings);

      case RouteName.login:
        return _buildRoute(const LoginScreen(), settings);

      case RouteName.signup:
        return _buildRoute(const SignUpScreen(), settings);

      case RouteName.verifyEmailOtp:
        return _buildRoute(const VerifyEmailOtpScreen(), settings);

      case RouteName.signupInfo:
        return _buildRoute(const SignUpInfoScreen(), settings);

      case RouteName.forgetPassword:
        return _buildRoute(const ForgetPasswordScreen(), settings);

      case RouteName.resetPasswordOtp:
        return _buildRoute(const ResetPassOtpScreen(), settings);

      case RouteName.resetPassword:
        return _buildRoute(const SetPasswordScreen(), settings);

      case RouteName.parent:
        return _buildRoute(const ParentScreen(), settings);

      case RouteName.addItem:
        return _buildRoute(AddItemScreen(), settings);

      case RouteName.editProfile:
        return _buildRoute(const EditProfile(), settings);

      case RouteName.security:
        return _buildRoute(const Security(), settings);

      case RouteName.about:
        return _buildRoute(const About(), settings);

      case RouteName.faq:
        return _buildRoute(const FrequentlyAskedQuestions(), settings);

      case RouteName.privacyPolicy:
        return _buildRoute(const PrivacyPolicy(), settings);

      case RouteName.support:
        return _buildRoute(const Support(), settings);

      case RouteName.terms:
        return _buildRoute(const TermsAndConditions(), settings);

      case RouteName.supportNext:
        return _buildRoute(const SupportNext(), settings);

      case RouteName.trackingDetail:
        return _buildRoute(const TrackingDetailScreen(), settings);

      case RouteName.itemDetails:
        return _buildRoute(const ItemDetailsScreen(), settings);

      case RouteName.itemAddQuestion:
        return _buildRoute(const ItemAddQuestionScreen(), settings);

      case RouteName.subscriptionScreen:
        return _buildRoute(const SubscriptionScreen(), settings);

      default:
        return _buildRoute(UnknownRouteScreen(routeName: settings.name), settings);
    }
  }

  static PageRouteBuilder _buildRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,

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
