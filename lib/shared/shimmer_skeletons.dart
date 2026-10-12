import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

const _base = Color(0xffDCEBE9);
const _highlight = Color(0xffF8FDFC);

/// Wraps skeleton content with the shimmer sweep.
class AppShimmer extends StatelessWidget {
  const AppShimmer({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: _base,
      highlightColor: _highlight,
      period: const Duration(milliseconds: 1400),
      child: child,
    );
  }
}

/// A solid rounded block. Must be opaque (white) so the shimmer shader paints it.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({super.key, this.width, this.height, this.radius = 6});
  final double? width;
  final double? height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Skeleton for the Assets cards (Vehicles / Home / Custom).
class ItemCardSkeleton extends StatelessWidget {
  const ItemCardSkeleton({super.key, required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        color: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: AppShimmer(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SkeletonBox(width: 24.w, height: 24.h, radius: 6),
                    SkeletonBox(width: 22.w, height: 20.h, radius: 5),
                  ],
                ),
                SizedBox(height: 12.h),
                Center(child: SkeletonBox(width: 56.w, height: 14.h, radius: 5)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Skeleton for the "Upcoming Task" banner on the dashboard.
class UpcomingTaskSkeleton extends StatelessWidget {
  const UpcomingTaskSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      margin: EdgeInsets.only(bottom: 4.h),
      decoration: BoxDecoration(
        color: const Color(0xffF0FAF9),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: AppShimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(width: 130.w, height: 20.h),
            SizedBox(height: 4.h),
            // stands in for the Divider (1px + its default padding)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 7.5.h),
              child: SkeletonBox(height: 1, radius: 0),
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                SkeletonBox(width: 24.w, height: 24.w, radius: 12),
                SizedBox(width: 8.w),
                SkeletonBox(width: 2, height: 25, radius: 1),
                SizedBox(width: 8.w),
                Expanded(child: SkeletonBox(height: 16.h)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton for CustomTaskCard. Same padding / row heights as the real card.
class TaskCardSkeleton extends StatelessWidget {
  const TaskCardSkeleton({super.key});

  Widget _row({required double valueWidth}) {
    return Row(
      children: [
        SkeletonBox(width: 20.w, height: 20.w, radius: 5),
        SizedBox(width: 8.w),
        SkeletonBox(width: 56.w, height: 14.h),
        const Spacer(),
        SkeletonBox(width: valueWidth, height: 14.h),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xffF0FAF9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: AppShimmer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(width: 220.w, height: 18.h),
              SizedBox(height: 16.h),
              _row(valueWidth: 110.w),
              SizedBox(height: 12.h),
              _row(valueWidth: 70.w),
              SizedBox(height: 12.h),
              _row(valueWidth: 90.w),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: SkeletonBox(width: 84.w, height: 36.h, radius: 30),
              ),
            ],
          ),
        ),
      ),
    );
  }
}