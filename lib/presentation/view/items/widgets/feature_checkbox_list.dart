import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:maintenance_genie/core/constants/app_colors.dart';

class FeatureCheckboxList extends StatelessWidget {
  const FeatureCheckboxList({
    super.key,
    required this.options,
    required this.selected,
    required this.onToggle,
  });

  final List<String> options;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xff9e9e9e)),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Column(
        children: options.map((o) {
          final checked = selected.contains(o);
          return InkWell(
            onTap: () => onToggle(o),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    width: 20.w,
                    height: 20.w,
                    decoration: BoxDecoration(
                      color: checked ? AppColors.primaryColor : Colors.white,
                      borderRadius: BorderRadius.circular(4.r),
                      border: checked
                          ? null
                          : Border.all(
                        color: const Color(0xff9e9e9e),
                        width: 1.5,
                      ),
                    ),
                    child: checked
                        ? Icon(Icons.check, size: 14.sp, color: Colors.white)
                        : null,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(o, style: TextStyle(fontSize: 14.sp)),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}