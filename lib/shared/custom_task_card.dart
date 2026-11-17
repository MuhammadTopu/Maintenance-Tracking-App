import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:maintenance_genie/data/models/task_list_response_model.dart';
import 'package:maintenance_genie/shared/task_display.dart';
import 'package:maintenance_genie/shared/task_status_chip.dart';

class CustomTaskCard extends StatelessWidget {
  const CustomTaskCard({
    super.key,
    required this.task,
    required this.index,
    this.onTap,
  });

  final TaskResponse task;
  final int index;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isComplete = task.isComplete;
    final dateLabel = isComplete ? 'Completed on :' : 'Due date :';
    final dateValue = isComplete
        ? (task.completedOnLabel ?? task.dueDateLabel)
        : task.dueDateLabel;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: const Color(0xffF0FAF9),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$index. ${task.upcomingTask}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 16.h),
                _CardRow(
                  leading: Image.asset(
                    'assets/images/item.png',
                    height: 18.sp,
                  ),
                  label: 'Item :',
                  value: Text(
                    task.itemName,
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
                _CardRow(
                  leading: Icon(
                    Icons.check_box_outlined,
                    color: Colors.grey,
                    size: 20.sp,
                  ),
                  label: 'Status :',
                  value: Align(
                    alignment: Alignment.centerRight,
                    child: TaskStatusChip(status: task.status, dense: true),
                  ),
                ),
                SizedBox(height: 12.h),
                _CardRow(
                  leading: Icon(
                    Icons.calendar_month,
                    color: Colors.grey,
                    size: 20.sp,
                  ),
                  label: dateLabel,
                  value: Text(
                    dateValue,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    width: 84.w,
                    height: 36.h,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      border: const Border(
                        bottom: BorderSide(color: Colors.grey),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Detail'),
                        const SizedBox(width: 8),
                        Image.asset('assets/icons/arrow.png'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CardRow extends StatelessWidget {
  const _CardRow({
    required this.leading,
    required this.label,
    required this.value,
  });

  final Widget leading;
  final String label;
  final Widget value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 20.w, child: leading),
        SizedBox(width: 8.w),
        Text(label),
        SizedBox(width: 8.w),
        Expanded(child: value),
      ],
    );
  }
}