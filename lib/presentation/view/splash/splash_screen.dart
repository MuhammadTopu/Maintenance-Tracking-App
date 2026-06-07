import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/controller/splash_controller.dart';
import '../../../app/routes/route_names.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/common_widgets.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _showContent = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -0.2),
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _startSplash();
  }

  void _startSplash() {
    final controller = SplashController(
      onShowContent: () {
        if (!mounted) return;
        setState(() => _showContent = true);
        _controller.forward();
      },
      onNavigateToHome: () {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, RouteName.parent);
      },
      onStayOnSplash: () {},
    );

    controller.init();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Align(
            alignment: Alignment.center,
            child: SlideTransition(
              position: _slideAnimation,
              child: Image.asset(
                'assets/icons/splash.png',
                width: 156.w,
                height: 170.h,
              ),
            ),
          ),

          if (_showContent)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(
                  left: 40.w,
                  right: 40.w,
                  bottom: 60.h,
                ),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Welcome",
                        style: TextStyle(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 10.h),
                      Text(
                        "Welcome to Maintenance Genie. Track all of your home. vehicle, or equipment maintenance in one place!",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppColors.secondaryTextColor,
                        ),
                      ),
                      SizedBox(height: 20.h),

                      PrimaryButton(text: "Log In", onPressed: () {
                        Navigator.pushNamed(context, RouteName.login);
                      }),
                      SizedBox(height: 10.h),
                      PrimaryButton(
                        variant: ButtonVariant.outlined,
                        text: "Sign Up",
                        onPressed: () {
                          Navigator.pushNamed(context, RouteName.signup);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}