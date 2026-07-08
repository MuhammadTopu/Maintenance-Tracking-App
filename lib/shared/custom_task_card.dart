import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:maintenance_genie/core/constants/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:redacted/redacted.dart';

import '../presentation/view_models/item_task_list_by_item_id_provider.dart';

class CustomTaskCard extends StatelessWidget {
  const CustomTaskCard({
    super.key,
    required this.upcomingTask,
    required this.itemName,
    required this.status,
    required this.lastDate,
    required this.index,
    this.onTap,
    required this.taskId,
    required this.isLoading,
  });

  final int index;
  final String upcomingTask;
  final String itemName;
  final String status;
  final String lastDate;
  final VoidCallback? onTap;
  final String taskId;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: Container(
        padding: EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: Color(0xffF0FAF9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "$index. $upcomingTask",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 16.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: 20.w,
                  child: Image.asset("assets/images/item.png", height: 18.sp),
                ),
                SizedBox(width: 8.w),
                Text("Item :"),
                Spacer(),
                Expanded(
                  child: Text(
                    itemName,
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: 20.w,
                  child: Icon(Icons.check_box_outlined, color: Colors.grey, size: 20.sp),
                ),
                SizedBox(width: 8.w),
                Text("Status :"),
                Spacer(),
                Expanded(
                  child: Text(
                    status,
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w400),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: 20.w,
                  child: Icon(Icons.calendar_month, color: Colors.grey, size: 20.sp),
                ),
                SizedBox(width: 8.w),

                Text("Last date :"),
                Spacer(),
                Expanded(
                  child: Text(
                    DateFormat("MM/dd/yyyy").format(DateTime.parse(lastDate)),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    textAlign: TextAlign.end,
                    style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w400),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: onTap,
                child: Container(
                  width: 84.w,
                  height: 36.h,
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey,
                        //   width: 1.0,
                      ),
                    ),
                  ),
                  child:
                      context.watch<ItemTaskListByItemIdProvider>().loader &&
                              taskId ==
                                  context
                                      .watch<ItemTaskListByItemIdProvider>()
                                      .loaderTaskId
                          ? Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primaryColor,
                              constraints: BoxConstraints(
                                maxHeight: 20,
                                maxWidth: 20,
                                minHeight: 20,
                                minWidth: 20,
                              ),
                            ),
                          )
                          : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("Detail"),
                              SizedBox(width: 8),
                              Image.asset("assets/icons/arrow.png"),
                            ],
                          ),
                ),
              ),
            ),
          ],
        ).redacted(context: context, redact: isLoading),
      ),
    );
  }
}
