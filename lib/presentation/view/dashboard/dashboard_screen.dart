import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:maintenance_genie/core/constants/app_colors.dart';
import 'package:maintenance_genie/data/models/item.dart';
import 'package:maintenance_genie/data/models/task_list_response_model.dart';
import 'package:maintenance_genie/presentation/view_models/all_item_list_provider.dart';
import 'package:maintenance_genie/presentation/view_models/item_task_list_provider.dart';
import 'package:maintenance_genie/presentation/view_models/parent_screen_provider.dart';
import 'package:maintenance_genie/shared/custom_app_bar.dart';
import 'package:maintenance_genie/shared/custom_task_card.dart';
import 'package:maintenance_genie/shared/empty_state_widget.dart';
import 'package:maintenance_genie/shared/shimmer_skeletons.dart';
import 'package:maintenance_genie/shared/task_display.dart';
import 'package:provider/provider.dart';

import '../../../core/helper/task_actions.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final tasks = context.read<ItemTaskListProvider>();
      // Cheap if the list is already loaded.
      tasks.ensureDashboardLoaded();
      await context.read<AllItemListProvider>().getAllItem();
    });
  }

  @override
  Widget build(BuildContext context) {
    final itemsProvider = context.watch<AllItemListProvider>();
    final items = itemsProvider.allItemListModel?.items ?? const <Item>[];

    final vehicleCount = items.where((i) => i.category == 'Vehicle').length;
    final homeCount = items
        .where((i) => i.category == 'Home' || i.category == 'Appliance')
        .length;
    final otherCount = items.length - vehicleCount - homeCount;

    return Scaffold(
      backgroundColor: const Color(0xffFFFFFF),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CustomAppBar(),
              SizedBox(height: 20.h),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Consumer<ItemTaskListProvider>(
                        builder: (context, provider, _) {
                          if (provider.isDashboardLoading &&
                              provider.upcomingTask == null) {
                            return const UpcomingTaskSkeleton();
                          }
                          final task = provider.upcomingTask;
                          if (task == null) return const SizedBox.shrink();
                          return _UpcomingTaskCard(task: task);
                        },
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10.w),
                        child: Text(
                          'Assets',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(height: 10.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildItemCard(
                            'Vehicles',
                            vehicleCount,
                            'assets/images/car.png',
                            color: const Color(0xffF4F8EC),
                            isLoading: itemsProvider.loading,
                          ),
                          _buildItemCard(
                            'Home',
                            homeCount,
                            'assets/images/home.png',
                            color: const Color(0xffEEF5F9),
                            isLoading: itemsProvider.loading,
                          ),
                          _buildItemCard(
                            'Others',
                            otherCount,
                            'assets/images/ber.png',
                            color: const Color(0xffF0FAF9),
                            isLoading: itemsProvider.loading,
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10.w),
                        child: Row(
                          children: [
                            Text(
                              'Task List',
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            InkWell(
                              // Tab 2 = tracking screen.
                              onTap: () => context
                                  .read<ParentScreensProvider>()
                                  .onSelectedIndex(2),
                              child: Text(
                                'View All',
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Consumer<ItemTaskListProvider>(
                        builder: (context, provider, _) =>
                            _buildTaskList(provider),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 80.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskList(ItemTaskListProvider provider) {
    final tasks = provider.dashboardTasks;

    if (provider.isDashboardLoading && tasks.isEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.all(10),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 5,
        itemBuilder: (_, _) => const TaskCardSkeleton(),
      );
    }

    if (tasks.isEmpty) {
      final failed = provider.hasDashboardError;
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 40.h),
        child: EmptyState(
          icon: failed ? Icons.cloud_off_outlined : Icons.task_alt_outlined,
          title: failed ? 'Could not load tasks' : 'No tasks available',
          subtitle: failed
              ? 'Check your connection and try again.'
              : 'Upcoming maintenance tasks will show up here.',
          onRetry: provider.getItemTasks,
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(10.w),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tasks.length, // at most 20
      itemBuilder: (context, index) {
        final task = tasks[index];
        return CustomTaskCard(
          key: ValueKey<String>(task.id),
          index: index + 1,
          task: task,
          onTap: () => openTaskDetails(context, task),
        );
      },
    );
  }

  Widget _buildItemCard(
      String title,
      int count,
      String icon, {
        required Color color,
        bool isLoading = false,
      }) {
    if (isLoading) return ItemCardSkeleton(color: color);
    return Expanded(
      child: Card(
        color: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: 30.w,
                    child: Image.asset(
                      icon,
                      color: const Color(0xff43BCAC),
                      height: 24.h,
                      width: 24.w,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    '$count',
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Center(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UpcomingTaskCard extends StatelessWidget {
  const _UpcomingTaskCard({required this.task});

  final TaskResponse task;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Material(
        color: const Color(0xffF0FAF9),
        borderRadius: BorderRadius.circular(16.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: () => openTaskDetails(context, task),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Upcoming Task',
                  style: TextStyle(
                    color: const Color(0xff1D1F2C),
                    fontWeight: FontWeight.w600,
                    fontSize: 18.sp,
                  ),
                ),
                SizedBox(height: 4.h),
                const Divider(color: Color(0xffB2D2E4)),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    const Icon(Icons.notifications_outlined),
                    SizedBox(width: 8.w),
                    Container(
                      height: 36,
                      width: 2,
                      color: const Color(0xffB2D2E4),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.upcomingTask,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xff1D1F2C),
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            '${task.itemName} · ${task.dueDateLabel}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}