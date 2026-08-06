import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:maintenance_genie/core/constants/app_colors.dart';
import 'package:maintenance_genie/presentation/view_models/all_item_list_provider.dart';
import 'package:maintenance_genie/presentation/view_models/parent_screen_provider.dart';
import 'package:provider/provider.dart';
import 'package:redacted/redacted.dart';

import '../../../app/routes/route_names.dart';
import '../../../shared/custom_app_bar.dart';
import '../../../shared/custom_task_card.dart';
import '../../view_models/item_task_list_by_item_id_provider.dart';
import '../../view_models/item_task_list_provider.dart';

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
      await context.read<AllItemListProvider>().getAllItem();
    });
  }

  @override
  Widget build(BuildContext context) {
    final pr = context.watch<AllItemListProvider>();
    final allItems = context.select<AllItemListProvider, dynamic>(
          (provider) => provider.allItemListModel?.items,
    );

    final vehicleCount =
        allItems?.where((item) => item.category == 'Vehicle').length ?? 0;

    final applianceCount =
        allItems?.where((item) => item.category == 'Appliance').length ?? 0;

    final customCount =
        allItems
            ?.where(
              (item) =>
          item.category != 'Vehicle' &&
              item.category != 'Appliance',
        )
            .length ??
            0;

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
                        builder: (_, pr, _) {
                          if (pr.taskListResponse?.tasks.isEmpty ?? true) {
                            return const SizedBox.shrink();
                          }

                          final upcomingTask =
                              pr.taskListResponse?.tasks.first.upcomingTask ??
                              "";
                          return Container(
                            padding: EdgeInsets.all(16.w),
                            margin: EdgeInsets.only(bottom: 4.h),
                            decoration: BoxDecoration(
                              color: Color(0xffF0FAF9),
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                            child:
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Upcoming Task",
                                      style: TextStyle(
                                        color: const Color(0xff1D1F2C),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 18.sp,
                                      ),
                                    ),
                                    SizedBox(height: 8.h),
                                    Divider(color: Color(0xffB2D2E4)),
                                    SizedBox(height: 12.h),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.notifications_outlined,
                                        ),
                                        SizedBox(width: 8.w),
                                        Container(
                                          height: 25,
                                          width: 2,
                                          color: Color(0xffB2D2E4),
                                        ),
                                        SizedBox(width: 8.w),
                                        Expanded(
                                          child: Text(
                                            upcomingTask,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 16.sp,
                                              fontWeight: FontWeight.w400,
                                              color: const Color(0xff1D1F2C),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ).redacted(
                                  context: context,
                                  redact:
                                      pr.taskListResponse?.tasks.isEmpty ??
                                      false,
                                ),
                          );
                        },
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10.w),
                        child: Text(
                          "Assets",
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
                            "assets/images/car.png",
                            color: const Color(0xffF4F8EC),
                            isLoading: pr.loading,
                          ),
                          _buildItemCard(
                            'Home',
                            applianceCount,
                            "assets/images/home.png",
                            color: const Color(0xffEEF5F9),
                            isLoading: pr.loading,
                          ),
                          _buildItemCard(
                            'Custom',
                            customCount,
                            "assets/images/ber.png",
                            color: const Color(0xffF0FAF9),
                            isLoading: pr.loading,
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10.w),
                        child: Row(
                          children: [
                            Text(
                              "Task List",
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            InkWell(
                              onTap: () {
                                context.read<ParentScreensProvider>().onSelectedIndex(2);
                              },
                              child: Text(
                                "View All",
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryColor
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      Consumer<ItemTaskListProvider>(
                        builder: (_, taskListProvider, _) {
                          final isLoading = taskListProvider.loading;
                          final tasks =
                              taskListProvider.taskListResponse?.tasks;

                          if (isLoading) {
                            return ListView.builder(
                              padding: EdgeInsets.all(10.0),
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: 5,
                              itemBuilder: (context, index) {
                                return CustomTaskCard(
                                  index: index + 1,
                                  upcomingTask: "",
                                  itemName: "",
                                  status: "",
                                  lastDate: DateTime.now().toIso8601String(),
                                  taskId: '',
                                  isLoading: true,
                                  onTap: null,
                                );
                              },
                            );
                          }

                          if (tasks == null || tasks.isEmpty) {
                            return Center(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(height: 160.h),
                                  Text(
                                    "No tasks available",
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          final displayCount = tasks.length.clamp(0, 10);
                          return ListView.builder(
                            padding: EdgeInsets.all(10.0),
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: displayCount,
                            itemBuilder: (BuildContext context, int index) {
                              final task = tasks[index];
                              return CustomTaskCard(
                                index: index + 1,
                                upcomingTask: task.upcomingTask,
                                itemName: task.itemName,
                                status: task.status,
                                lastDate: task.nextDueDate ?? "",
                                taskId: task.id,
                                isLoading: false,
                                onTap: () async {
                                  final provider = context.read<ItemTaskListByItemIdProvider>();

                                  final taskId = task.id;
                                  final itemId = task.itemId;

                                  try {
                                    provider.setLoader(true, taskId);

                                    provider.setItemId(itemId);

                                    await provider.setTaskId(
                                      taskId,
                                      itemId,
                                    );

                                    if (!mounted) return;

                                    Navigator.pushNamed(
                                      context,
                                      RouteName.trackingDetail,
                                    );
                                  } finally {
                                    provider.setLoader(false, taskId);
                                  }
                                },
                              );
                            },
                          );
                        },
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

  Widget _buildItemCard(
    String title,
    int count,
    String icon, {
    required Color color,
    bool isLoading = false,
  }) {
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
                    textAlign: TextAlign.end,
                    '$count',
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
          ).redacted(context: context, redact: isLoading),
        ),
      ),
    );
  }
}
