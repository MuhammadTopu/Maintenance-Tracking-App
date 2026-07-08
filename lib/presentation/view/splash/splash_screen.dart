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

  bool _showContent = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

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
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final screenHeight = constraints.maxHeight;

            final isTablet = screenWidth >= 600;
            final isLargeTablet = screenWidth >= 900;

            // Cap content width on tablets so text/buttons don't stretch
            final maxContentWidth = isLargeTablet
                ? 480.0
                : isTablet
                ? 420.0
                : screenWidth;

            // Logo size
            final imageHeight = (screenHeight * 0.28).clamp(160.0, 320.0);
            final imageWidth = imageHeight * (156 / 170); // aspect ratio

            final titleFontSize = (screenWidth * 0.06).clamp(20.0, 30.0);
            final bodyFontSize = (screenWidth * 0.035).clamp(13.0, 17.0);

            final horizontalPadding = isTablet ? 0.0 : 40.w;
            final bottomPadding = isTablet ? 40.h : 60.h;

            // Vertical center position for the logo (before content shows)
            final centeredTop = (screenHeight - imageHeight) / 2;
            // Final position once content is shown: 100.h padding from top
            final topPositionAfter = 100.h;

            debugPrint('------------> $screenHeight');

            return Stack(
              fit: StackFit.expand,
              children: [
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final curvedValue =
                    Curves.easeInOut.transform(_controller.value);

                    final currentTop = centeredTop +
                        (topPositionAfter - centeredTop) * curvedValue;

                    return Positioned(
                      top: currentTop,
                      left: 0,
                      right: 0,
                      child: Center(child: child),
                    );
                  },
                  child: Image.asset(
                    'assets/icons/splash.png',
                    width: 225,
                    height: 245,
                  ),
                ),

                if (_showContent)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: horizontalPadding,
                        right: horizontalPadding,
                        bottom: bottomPadding,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxContentWidth),
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "Welcome",
                                style: TextStyle(
                                  fontSize: titleFontSize,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 10.h),
                              Text(
                                "Welcome to Maintenance Genie. Track all your home, vehicle, or equipment maintenance in one place!",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: bodyFontSize,
                                  color: AppColors.secondaryTextColor,
                                ),
                              ),
                              SizedBox(height: 20.h),
                              PrimaryButton(
                                text: "Log In",
                                onPressed: () {
                                  Navigator.pushNamed(context, RouteName.login);
                                },
                              ),
                              SizedBox(height: 10.h),
                              PrimaryButton(
                                variant: ButtonVariant.outlined,
                                text: "Sign Up",
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context,
                                    RouteName.signup,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}