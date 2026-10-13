import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PasswordRequirement extends StatelessWidget {
  final String text;
  final bool isValid;

  const PasswordRequirement({
    super.key,
    required this.text,
    required this.isValid,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.check_circle,
          size: 18.w,
          color: isValid ? Colors.green : Colors.red,
        ),
        SizedBox(width: 10.w),
        Text(
          text,
          style: TextStyle(
            color: isValid ? Colors.green : Colors.red,
            fontSize: 14.sp,
          ),
        ),
      ],
    );
  }
}