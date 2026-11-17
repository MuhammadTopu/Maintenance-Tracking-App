import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:maintenance_genie/core/constants/app_colors.dart';
import 'package:maintenance_genie/data/models/task_list_response_model.dart';
import 'package:maintenance_genie/shared/app_toast.dart';
import 'package:maintenance_genie/shared/task_display.dart';
import 'package:url_launcher/url_launcher.dart';

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: const Color(0xff1D1F2C),
        fontWeight: FontWeight.w600,
        fontSize: 18.sp,
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Details
// -----------------------------------------------------------------------------

class TaskInfoSection extends StatelessWidget {
  const TaskInfoSection({super.key, required this.task});

  final TaskResponse task;

  @override
  Widget build(BuildContext context) {
    final rows = taskDetailRows(task);
    final hasDescription = isMeaningful(task.description);
    if (!hasDescription && rows.isEmpty) return const SizedBox.shrink();

    final showEstimateNote =
        task.manufacturerIntervalUncertain &&
            isMeaningful(task.recommendedInterval);

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasDescription) ...[
            const _SectionTitle('About this task'),
            SizedBox(height: 6.h),
            Text(
              task.description,
              style: TextStyle(
                color: const Color(0xff4A4C56),
                fontSize: 14.sp,
                height: 1.4,
              ),
            ),
            if (rows.isNotEmpty) ...[
              SizedBox(height: 12.h),
              Divider(color: Colors.grey.shade400, height: 1),
              SizedBox(height: 12.h),
            ],
          ],
          for (var i = 0; i < rows.length; i++) ...[
            _DetailRow(row: rows[i]),
            if (i != rows.length - 1) SizedBox(height: 10.h),
          ],
          if (showEstimateNote) ...[
            SizedBox(height: 12.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16.sp,
                  color: Colors.grey.shade600,
                ),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    'The interval is an estimate. Confirm it with the '
                        "manufacturer's guidance.",
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.row});

  final TaskDetailRow row;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140.w,
          child: Text(
            row.label,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: row.isPriority
              ? Align(
            alignment: Alignment.centerLeft,
            child: _PriorityPill(priority: row.value),
          )
              : Text(
            row.value,
            style: TextStyle(
              color: const Color(0xff1D1F2C),
              fontSize: 13.sp,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}

class _PriorityPill extends StatelessWidget {
  const _PriorityPill({required this.priority});

  final String priority;

  @override
  Widget build(BuildContext context) {
    final color = priorityColor(priority);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99.r),
      ),
      child: Text(
        priority,
        style: TextStyle(
          color: color,
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Maintenance history
// -----------------------------------------------------------------------------

class MaintenanceHistorySection extends StatelessWidget {
  const MaintenanceHistorySection({super.key, required this.history});

  final List<String> history;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Maintenance History'),
          SizedBox(height: 12.h),
          if (history.isEmpty)
            Text(
              'No maintenance history available',
              style: TextStyle(
                color: const Color(0xff4A4C56),
                fontSize: 14.sp,
              ),
            )
          else
            for (final line in history)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 5.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: 2.h),
                      child: Icon(
                        Icons.history,
                        size: 16.sp,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        line,
                        style: TextStyle(
                          color: const Color(0xff4A4C56),
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Shop suggestions
// -----------------------------------------------------------------------------

class ShopSuggestionsSection extends StatelessWidget {
  const ShopSuggestionsSection({super.key, required this.shops});

  final List<ShopSuggestion> shops;

  Future<void> _openMaps(ShopSuggestion shop) async {
    final uri = Uri.tryParse(shop.mapUrl);
    if (uri != null && (uri.scheme == 'https' || uri.scheme == 'http')) {
      try {
        if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
      } catch (_) {
        // fall through to the toast
      }
    }
    AppToast.showToast('Could not open Google Maps');
  }

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Shop Suggestions'),
          SizedBox(height: 4.h),
          Text(
            'Tap a shop to find the nearest location on Google Maps.',
            style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600),
          ),
          SizedBox(height: 12.h),
          if (shops.isEmpty)
            Text(
              'No shop suggestions available for this task',
              style: TextStyle(
                color: const Color(0xff4A4C56),
                fontSize: 14.sp,
              ),
            )
          else
            for (var i = 0; i < shops.length; i++) ...[
              _ShopCard(shop: shops[i], onOpenMaps: () => _openMaps(shops[i])),
              if (i != shops.length - 1) SizedBox(height: 10.h),
            ],
        ],
      ),
    );
  }
}

class _ShopCard extends StatelessWidget {
  const _ShopCard({required this.shop, required this.onOpenMaps});

  final ShopSuggestion shop;
  final VoidCallback onOpenMaps;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xffE9E9EA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  shop.name,
                  style: TextStyle(
                    color: const Color(0xff1D1F2C),
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (shop.aiSuggested) ...[
                SizedBox(width: 8.w),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: const Color(0xffEEF5F9),
                    borderRadius: BorderRadius.circular(99.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 12.sp,
                        color: const Color(0xff589DC4),
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        'AI suggested',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: const Color(0xff589DC4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          if (shop.description.isNotEmpty) ...[
            SizedBox(height: 6.h),
            Text(
              shop.description,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13.sp),
            ),
          ],
          SizedBox(height: 10.h),
          InkWell(
            onTap: onOpenMaps,
            borderRadius: BorderRadius.circular(12.r),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 14.w),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: const Color(0xffE9E9EA)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('See on Google Maps'),
                  SizedBox(width: 7.w),
                  const Icon(
                    Icons.location_pin,
                    size: 17,
                    color: Color(0xff589DC4),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}