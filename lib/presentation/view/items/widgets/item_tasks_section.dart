import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:maintenance_genie/core/constants/app_colors.dart';
import 'package:maintenance_genie/data/models/task_list_response_model.dart';
import 'package:maintenance_genie/presentation/view_models/item_task_list_by_item_id_provider.dart';
import 'package:maintenance_genie/shared/task_display.dart';
import 'package:maintenance_genie/shared/task_status_chip.dart';
import 'package:provider/provider.dart';

import '../../../../core/helper/task_actions.dart';

class ItemTasksSection extends StatelessWidget {
  const ItemTasksSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ItemTaskListByItemIdProvider>(
      builder: (context, provider, _) {
        if (!provider.hasTasks) {
          if (provider.isLoading) {
            return const _Panel(child: _LoadingRow());
          }
          if (provider.hasError) {
            return _Panel(
              child: _ErrorRow(onRetry: () => provider.loadItemTasks()),
            );
          }
          return _Panel(
            child: Text(
              'No Upcoming Tasks found',
              style: TextStyle(fontSize: 14.sp),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12.h,
          children: [
            if (provider.activeTasks.isNotEmpty)
              _ActiveTasks(tasks: provider.activeTasks),
            if (provider.completedTasks.isNotEmpty)
              _CompletedTasks(tasks: provider.completedTasks),
          ],
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade400),
        color: AppColors.cardColor,
      ),
      child: child,
    );
  }
}

class _LoadingRow extends StatelessWidget {
  const _LoadingRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          height: 18.h,
          width: 18.h,
          child: const CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primaryColor,
          ),
        ),
        SizedBox(width: 12.w),
        Text('Loading tasks…', style: TextStyle(fontSize: 14.sp)),
      ],
    );
  }
}

class _ErrorRow extends StatelessWidget {
  const _ErrorRow({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Could not load tasks',
            style: TextStyle(fontSize: 14.sp),
          ),
        ),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Open tasks
// -----------------------------------------------------------------------------

class _ActiveTasks extends StatelessWidget {
  const _ActiveTasks({required this.tasks});

  final List<TaskResponse> tasks;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 10.h,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Text(
            'Upcoming Tasks (${tasks.length})',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
          ),
        ),
        for (final task in tasks)
          _TaskTile(key: ValueKey<String>(task.id), task: task),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Completed tasks
// -----------------------------------------------------------------------------

class _CompletedTasks extends StatefulWidget {
  const _CompletedTasks({required this.tasks});

  final List<TaskResponse> tasks;

  @override
  State<_CompletedTasks> createState() => _CompletedTasksState();
}

class _CompletedTasksState extends State<_CompletedTasks> {
  static const Color _green = Color(0xff2E7D32);

  /// A short list is shown open; a long one starts collapsed.
  late bool _expanded = widget.tasks.length <= 3;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xffF1F8F2),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xffB7DDBB)),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12.r),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: EdgeInsets.all(14.w),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: _green),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      'Completed Tasks (${widget.tasks.length})',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: _green,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down, color: _green),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            alignment: Alignment.topCenter,
            child: _expanded
                ? Padding(
              padding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 12.h),
              child: Column(
                spacing: 8.h,
                children: [
                  for (final task in widget.tasks)
                    _TaskTile(
                      key: ValueKey<String>(task.id),
                      task: task,
                      completed: true,
                    ),
                ],
              ),
            )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------

class _TaskTile extends StatelessWidget {
  const _TaskTile({super.key, required this.task, this.completed = false});

  final TaskResponse task;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    final subtitleParts = <String>[
      if (isMeaningful(task.category)) task.category,
      completed
          ? 'Completed ${task.completedOnLabel ?? ''}'.trim()
          : 'Due ${task.dueDateLabel}',
    ];

    return Material(
      color: completed ? Colors.white : const Color(0xffF0FAF9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(
          color: completed ? const Color(0xffD5E8D7) : Colors.grey.shade300,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: () => openTaskDetails(context, task),
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.upcomingTask,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w500,
                        color: completed
                            ? Colors.grey.shade700
                            : const Color(0xff1D1F2C),
                        decoration: completed
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      subtitleParts.join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              if (completed)
                const Icon(Icons.check_circle, color: Color(0xff2E7D32))
              else
                TaskStatusChip(status: task.status, dense: true),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}