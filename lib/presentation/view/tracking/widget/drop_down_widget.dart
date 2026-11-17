import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:maintenance_genie/data/models/task_list_response_model.dart';
import 'package:maintenance_genie/presentation/view_models/item_task_list_by_item_id_provider.dart';
import 'package:maintenance_genie/shared/app_toast.dart';
import 'package:maintenance_genie/shared/task_status_chip.dart';
import 'package:provider/provider.dart';

import '../../../../core/helper/task_actions.dart';

class DropDownWidget extends StatelessWidget {
  const DropDownWidget({super.key, required this.task});

  final TaskResponse task;

  Future<void> _toggle(BuildContext context) async {
    final wasComplete = task.isComplete;
    final success = await toggleSelectedTask(context);
    if (!success || !context.mounted) return;
    AppToast.showToast(
      wasComplete ? 'Task reopened' : 'Task marked as completed',
    );
  }

  @override
  Widget build(BuildContext context) {
    final toggling = context.select<ItemTaskListByItemIdProvider, bool>(
          (provider) => provider.isToggling,
    );
    final isComplete = task.isComplete;

    return PopupMenuButton<String>(
      enabled: !toggling,
      tooltip: 'Change status',
      offset: const Offset(0, 44),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      onSelected: (_) => _toggle(context),
      surfaceTintColor: Colors.white,
      color: Colors.white,
      itemBuilder: (_) => [
        PopupMenuItem<String>(
          value: 'toggle',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isComplete ? Icons.replay : Icons.check_circle_outline,
                size: 20.sp,
                color: isComplete
                    ? const Color(0xff4A4C56)
                    : TaskStatus.complete.foreground,
              ),
              SizedBox(width: 10.w),
              Text(isComplete ? 'Reopen task' : 'Mark as Completed'),
            ],
          ),
        ),
      ],
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: task.status.background,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(color: Colors.grey.shade400),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              task.status.label,
              style: TextStyle(
                color: task.status.foreground,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 6.w),
            if (toggling)
              SizedBox(
                height: 16.w,
                width: 16.w,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: task.status.foreground,
                ),
              )
            else
              SvgPicture.asset(
                'assets/icons/arrow-down.svg',
                height: 16.w,
                width: 16.w,
              ),
          ],
        ),
      ),
    );
  }
}