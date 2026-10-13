import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:maintenance_genie/core/constants/app_colors.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    this.icon = Icons.inbox_outlined,
    this.subtitle,
    this.onRetry,
    this.retryText = 'Retry',
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onRetry; // button is shown only when this is set
  final String retryText;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: const BoxDecoration(
                color: Color(0xffF0FAF9),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40.sp, color: AppColors.primaryColor),
            ),
            SizedBox(height: 16.h),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xff1D1F2C),
              ),
            ),
            if (subtitle != null) ...[
              SizedBox(height: 6.h),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
            if (onRetry != null) ...[
              SizedBox(height: 20.h),
              GestureDetector(
                onTap: onRetry,
                child: Container(
                  height: 40.h,
                  padding: EdgeInsets.symmetric(horizontal: 28.w),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    borderRadius: BorderRadius.circular(90.r),
                  ),
                  child: Center(
                    child: Text(
                      retryText,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}