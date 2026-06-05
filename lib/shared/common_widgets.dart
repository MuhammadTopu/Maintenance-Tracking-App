import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:maintenance_genie/core/constants/app_colors.dart';

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

  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = ButtonVariant.filled,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
    this.child,
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
              style: TextStyle(
                color: isFilled
                    ? (textColor ?? Colors.white)
                    : (borderColor ?? AppColors.primaryColor),
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
      ),
    );
  }
}