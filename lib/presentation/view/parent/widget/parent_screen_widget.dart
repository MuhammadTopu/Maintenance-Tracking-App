import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../view_models/parent_screen_provider.dart';

class ParentScreenWidget extends StatelessWidget {
  const ParentScreenWidget({super.key});

  static const _tabs = [
    {'iconPath': 'assets/icons/dashboard.png', 'title': 'Dashboard'},
    {'iconPath': 'assets/icons/items.png', 'title': 'Items'},
    {'iconPath': 'assets/icons/tracking.png', 'title': 'Tracking'},
    {'iconPath': 'assets/icons/profile.png', 'title': 'Profile'},
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ParentScreensProvider>();

    return Container(
      height: 80.h,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30.r),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
          _tabs.length,
              (index) {
            final isSelected = provider.selectedIndex == index;

            return _TabButton(
              index: index,
              iconPath: _tabs[index]['iconPath']!,
              title: _tabs[index]['title']!,
              isSelected: isSelected,
              onTap: provider.onSelectedIndex,
            );
          },
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final int index;
  final String iconPath;
  final String title;
  final bool isSelected;
  final Function(int) onTap;

  const _TabButton({
    required this.index,
    required this.iconPath,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTap(index),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              iconPath,
              width: 24.w,
              height: 24.h,
              color: isSelected
                  ? const Color(0xff589DC4)
                  : const Color(0xff777980),
            ),
            SizedBox(height: 4.h),
            Text(
              title,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight:
                isSelected ? FontWeight.w600 : FontWeight.w400,
                color: const Color(0xff777980),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
