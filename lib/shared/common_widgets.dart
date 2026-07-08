import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:maintenance_genie/core/constants/app_colors.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

enum ButtonVariant {
  filled,
  outlined,
}

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? borderColor;
  final Widget? child;
  final double? fontSize;

  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = ButtonVariant.filled,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
    this.child, this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final isFilled = variant == ButtonVariant.filled;

    return SizedBox(
      width: double.infinity,
      height: 48.h,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: isFilled
              ? (backgroundColor ?? AppColors.primaryColor)
              : Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(90.r),
            side: isFilled
                ? BorderSide.none
                : BorderSide(
              color: borderColor ?? AppColors.primaryColor,
              width: 1.5,
            ),
          ),
        ),
        onPressed: onPressed,
        child: child ??
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isFilled
                    ? (textColor ?? Colors.white)
                    : (borderColor ?? AppColors.primaryColor),
                fontSize: fontSize ?? 16.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
      ),
    );
  }
}

class WaveLoading extends StatelessWidget {
  const WaveLoading({super.key, this.waveColor});

  final Color? waveColor;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: LoadingAnimationWidget.staggeredDotsWave(
        color: waveColor ?? AppColors.primaryColor,
        size: 40.w,
      ),
    );
  }
}