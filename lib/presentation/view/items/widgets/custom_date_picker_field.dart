import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_colors.dart';

class CustomDatePickerField extends StatelessWidget {
  const CustomDatePickerField({
    super.key,
    required this.context,
    required this.title,
    required this.hint,
    this.selectedDate,
    required this.onDatePicked,
  });

  final BuildContext context;
  final String title;
  final String hint;
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDatePicked;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title),
        SizedBox(height: 4.h),
        InkWell(
          borderRadius: BorderRadius.circular(10.r),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: selectedDate ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    dialogTheme: const DialogThemeData(
                      backgroundColor: Colors.white,
                    ),
                    datePickerTheme: const DatePickerThemeData(
                      backgroundColor: Colors.white,
                    ),
                    colorScheme: ColorScheme.light(
                      primary: AppColors.primaryColor,
                      onPrimary: Colors.white,
                      surface: Colors.white,
                      onSurface: Colors.black,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) onDatePicked(picked);
          },
          child: Container(
            height: 46.h,
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xff8e8e91)),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selectedDate != null
                        ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                        : hint,
                    style: TextStyle(
                      color: selectedDate != null
                          ? Colors.black
                          : const Color(0xffA5A5AB),
                      fontSize: 14.sp,
                    ),
                  ),
                ),
                const Icon(Icons.calendar_month_outlined),
              ],
            ),
          ),
        ),
      ],
    );
  }
}