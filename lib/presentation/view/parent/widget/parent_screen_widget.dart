import 'dart:ui';

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
    {'iconPath': 'assets/icons/user.png', 'title': 'Profile'},
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ParentScreensProvider>();
    final radius = BorderRadius.circular(30.r);

    return Material(
      elevation: 12,
      color: Colors.transparent,
      shadowColor: Colors.black.withValues(alpha: 0.35),
      borderRadius: radius,
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
          child: Container(
            height: 80.h,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.38),
                  Colors.white.withValues(alpha: 0.08),
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.9),
                width: 1.5,
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final cellWidth = constraints.maxWidth / _tabs.length;

                final bubbleWidth = (72.w).clamp(0.0, cellWidth - 8);
                final bubbleHeight = (62.h).clamp(0.0, constraints.maxHeight);

                final left = cellWidth * provider.selectedIndex +
                    (cellWidth - bubbleWidth) / 2;
                final top = (constraints.maxHeight - bubbleHeight) / 2;

                return Stack(
                  children: [
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 450),
                      curve: Curves.easeOutBack,
                      left: left,
                      top: top,
                      width: bubbleWidth,
                      height: bubbleHeight,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20.r),
                          color: Colors.white.withValues(alpha: 0.6),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.9),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    Row(
                      children: List.generate(_tabs.length, (index) {
                        return Expanded(
                          child: _TabButton(
                            index: index,
                            iconPath: _tabs[index]['iconPath']!,
                            title: _tabs[index]['title']!,
                            isSelected: provider.selectedIndex == index,
                            onTap: provider.onSelectedIndex,
                          ),
                        );
                      }),
                    ),
                  ],
                );
              },
            ),
          ),
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
    const activeColor = Color(0xff589DC4);
    const inactiveColor = Color(0xff4A4C54);
    final color = isSelected ? activeColor : inactiveColor;
    const duration = Duration(milliseconds: 300);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTap(index),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<Color?>(
              tween: ColorTween(end: color),
              duration: duration,
              builder: (_, c, _) => Image.asset(
                iconPath,
                width: 24.w,
                height: 24.h,
                color: c,
              ),
            ),
            SizedBox(height: 4.h),
            AnimatedDefaultTextStyle(
              duration: duration,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: color,
              ),
              child: Text(title),
            ),
          ],
        ),
      ),
    );
  }
}