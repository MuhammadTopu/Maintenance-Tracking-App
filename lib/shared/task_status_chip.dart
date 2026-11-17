import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:maintenance_genie/data/models/task_list_response_model.dart';

extension TaskStatusStyle on TaskStatus {
  Color get foreground => switch (this) {
    TaskStatus.overdue => const Color(0xffC62828),
    TaskStatus.dueNow => const Color(0xffE65100),
    TaskStatus.upcoming => const Color(0xff1565C0),
    TaskStatus.future => const Color(0xff546E7A),
    TaskStatus.complete => const Color(0xff2E7D32),
    TaskStatus.unknown => const Color(0xff546E7A),
  };

  Color get background => switch (this) {
    TaskStatus.overdue => const Color(0xffFDECEA),
    TaskStatus.dueNow => const Color(0xffFFF3E0),
    TaskStatus.upcoming => const Color(0xffE3F2FD),
    TaskStatus.future => const Color(0xffECEFF1),
    TaskStatus.complete => const Color(0xffE8F5E9),
    TaskStatus.unknown => const Color(0xffECEFF1),
  };

  IconData get icon => switch (this) {
    TaskStatus.overdue => Icons.error_outline,
    TaskStatus.dueNow => Icons.alarm,
    TaskStatus.upcoming => Icons.event_outlined,
    TaskStatus.future => Icons.event_available_outlined,
    TaskStatus.complete => Icons.check_circle_outline,
    TaskStatus.unknown => Icons.help_outline,
  };
}

class TaskStatusChip extends StatelessWidget {
  const TaskStatusChip({super.key, required this.status, this.dense = false});

  final TaskStatus status;

  final bool dense;

  @override
  Widget build(BuildContext context) {
    final color = status.foreground;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 10.w,
        vertical: dense ? 3.h : 5.h,
      ),
      decoration: BoxDecoration(
        color: status.background,
        borderRadius: BorderRadius.circular(99.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 14.sp, color: color),
          SizedBox(width: 4.w),
          Text(
            status.label,
            style: TextStyle(
              color: color,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}