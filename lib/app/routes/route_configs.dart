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

      case RouteName.signup:
        return _buildRoute(const SignUpScreen());

      case RouteName.verifyEmailOtp:
        return _buildRoute(const VerifyEmailOtpScreen());

      case RouteName.signupInfo:
        return _buildRoute(const SignUpInfoScreen());

      case RouteName.forgetPassword:
        return _buildRoute(const ForgetPasswordScreen());

      case RouteName.resetPasswordOtp:
        return _buildRoute(const ResetPassOtpScreen());

      case RouteName.resetPassword:
        return _buildRoute(const SetPasswordScreen());

      case RouteName.parent:
        return _buildRoute(const ParentScreen());

      case RouteName.addItem:
        return _buildRoute(AddItemScreen());

      case RouteName.editProfile:
        return _buildRoute(const EditProfile());

      case RouteName.security:
        return _buildRoute(const Security());

      case RouteName.about:
        return _buildRoute(const About());

      case RouteName.faq:
        return _buildRoute(const FrequentlyAskedQuestions());

      case RouteName.privacyPolicy:
        return _buildRoute(const PrivacyPolicy());

      case RouteName.support:
        return _buildRoute(const Support());

      case RouteName.terms:
        return _buildRoute(const TermsAndConditions());

      case RouteName.supportNext:
        return _buildRoute(const SupportNext());

      case RouteName.trackingDetail:
        return _buildRoute(const TrackingDetailScreen());

      case RouteName.itemDetails:
        return _buildRoute(const ItemDetailsScreen());

      case RouteName.itemAddQuestion:
        return _buildRoute(const ItemAddQuestionScreen());

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
