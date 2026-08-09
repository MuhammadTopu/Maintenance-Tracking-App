import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/task_list_response_model.dart';

class UpcomingTaskCard extends StatelessWidget {
  final TaskResponse task;
  final VoidCallback? onTap;

  const UpcomingTaskCard({super.key, required this.task, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isUrgent = _isUrgent(task.status, task.priority);
    final priorityColor = _priorityColor(task.priority);

    return InkWell(
      borderRadius: BorderRadius.circular(18.r),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: Colors.grey.shade400),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (task.category.isNotEmpty)
                  Expanded(
                    child: Text(
                      task.category.toUpperCase(),
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5.sp,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.6,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (task.priority.isNotEmpty) ...[
                      Container(
                        width: 5.r,
                        height: 5.r,
                        margin: EdgeInsets.only(right: 5.w),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: priorityColor,
                        ),
                      ),
                    ],
                    if (task.status.isNotEmpty)
                      Text(
                        task.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10.5.sp,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.6,
                          color: isUrgent
                              ? AppColors.primaryColor
                              : Colors.grey.shade500,
                        ),
                      ),
                    if (task.status.isNotEmpty && task.nextDueDate.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6.w),
                        child: Text(
                          '·',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ),
                    if (task.nextDueDate.isNotEmpty)
                      Text(
                        task.nextDueDate,
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ],
            ),

            SizedBox(height: 12.h),
            Divider(color: Colors.grey.shade400, height: 1, thickness: 1),
            SizedBox(height: 12.h),

            // ---- Title ----
            Text(
              task.upcomingTask.isNotEmpty ? task.upcomingTask : task.itemName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                height: 1.25,
              ),
            ),

            // ---- Description ----
            if (task.description.isNotEmpty) ...[
              SizedBox(height: 6.h),
              Text(
                task.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13.sp,
                  height: 1.4,
                  color: Colors.grey.shade600,
                ),
              ),
            ],

            // ---- Recommended interval ----
            if (task.recommendedInterval.isNotEmpty) ...[
              SizedBox(height: 10.h),
              Divider(color: Colors.grey.shade100, height: 1, thickness: 1),
              SizedBox(height: 10.h),
              Row(
                children: [
                  Icon(Icons.autorenew, size: 13.h, color: Colors.grey.shade400),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      task.recommendedInterval,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade700),
                    ),
                  ),
                  if (onTap != null)
                    Icon(Icons.arrow_forward_ios_rounded,
                        size: 11.h, color: Colors.grey.shade300),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _isUrgent(String status, String priority) {
    final s = status.toLowerCase();
    final p = priority.toLowerCase();
    return s.contains('overdue') ||
        s.contains('due') ||
        p.contains('high') ||
        p.contains('urgent');
  }

  Color _priorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
      case 'urgent':
        return AppColors.primaryColor;
      case 'medium':
      case 'moderate':
        return AppColors.primaryColor.withValues(alpha: 0.5);
      case 'low':
      default:
        return Colors.grey.shade300;
    }
  }
}