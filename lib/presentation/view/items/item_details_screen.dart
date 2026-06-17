import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/api_end_points.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/one_item_model.dart';
import '../../../shared/custom_item_app_bar.dart';
import '../../view_models/all_item_list_provider.dart';
import '../../view_models/item_task_list_by_item_id_provider.dart';
import 'widgets/forum_suggestion_card_widget.dart';

class ItemDetailsScreen extends StatefulWidget {
  final String? itemId;
  const ItemDetailsScreen({super.key, this.itemId});

  @override
  State<ItemDetailsScreen> createState() => _ItemDetailsScreenState();
}

class _ItemDetailsScreenState extends State<ItemDetailsScreen> {
  
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<ItemTaskListByItemIdProvider>().getAllTaskListByItemId();
    });
    super.initState();
  }
  
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xffFFFFFF),
      body: SafeArea(
        child: Consumer<AllItemListProvider>(
          builder: (context, provider, child) {
            if (provider.itemDetailsLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (provider.errorFetchingOneItem != '') {
              return Center(child: Text(provider.errorFetchingOneItem!));
            }
            final item = provider.oneItemModel?.item;
            if (item == null) {
              return const Center(child: Text('No item data available'));
            }
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomItemAppBar(
                      title: 'Item Details',
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    SizedBox(height: 20.h),
                    Text(
                      item.name ?? 'Unnamed Item',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Column(
                      spacing: 4,
                      children: [
                        _buildInfoRow(
                          title: 'Category : ',
                          value: item.category ?? 'N/A',
                        ),
                        _buildInfoRow(
                          title: 'Brand : ',
                          value: item.brand ?? 'N/A',
                        ),
                        _buildInfoRow(
                          title: 'Model : ',
                          value: item.model ?? 'N/A',
                        ),
                        // _buildInfoRow(
                        //   title: 'VIN : ',
                        //   value: item.vin ?? 'N/A',
                        // ),
                        _buildInfoRow(
                          title: 'Purchase Date : ',
                          value: DateFormat("yyyy-MM-dd").format(DateTime.parse(item.purchaseDate)) ?? 'N/A',
                        ),
                        _buildInfoRow(
                          title: 'Total Mileage : ',
                          value:
                              '${item.totalMileage} miles',
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12.r),
                      child: Container(
                        height: 250.h,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: Colors.grey.shade400),
                        ),
                        child:
                            Image.network(
                                  ApiEndPoints.imagePath(item.imageUrl.replaceFirst("undefined/uploads/", "")),
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                        : null,
                                    color: const Color(0xFF6359FF),
                                  ),
                                );
                              },
                                  errorBuilder:
                                      (context, error, stackTrace) => Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Icon(Icons.image_outlined, size: 30.h,),
                                          SizedBox(height: 12.h,),
                                          Text('No Image Available!')
                                        ],
                                      ),
                                ),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Consumer<ItemTaskListByItemIdProvider>(
                      builder: (_, prov, __) {
                        if (prov.taskListResponse?.tasks.isEmpty ?? true) {
                          return _buildContainer(child: Text('No Upcoming Tasks found'));
                        }
                        return Column(
                          spacing: 12.h,
                          children: List.generate(prov.taskListResponse?.tasks.length ?? 0, (index) {
                            return _buildUpcomingTask(
                              prov.taskListResponse!.tasks[index].upcomingTask,
                              prov.taskListResponse!.tasks[index].lastDate!,
                              prov.taskListResponse!.tasks[index].status,
                            );
                          }),
                        );
                      }
                    ),
                    SizedBox(height: 12.h),
                    _buildServiceIntervals(item),
                    SizedBox(height: 12.h),
                    _buildContainer(
                      child: ForumSuggestionsCard(
                        response: provider.oneItemModel!,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildServiceIntervals(Item item) {
    return _buildContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Service Intervals',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18.sp),
          ),
          const Divider(color: Colors.grey, thickness: 1.07),
          item.serviceIntervals.isEmpty
              ? const Text('No service intervals available')
              : Column(
            children: List.generate(item.serviceIntervals.length, (index) {
              return _buildInfoRow(
                title: "",
                value: item.serviceIntervals[index],
              );
            }),
          )
        ],
      ),
    );
  }

  Widget _buildInfoRow({required String title, required String value}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 14.sp,
            color: Colors.grey.shade700,
          ),
        ),
        Expanded(
          child: GptMarkdown(
            value.isNotEmpty ? value : '',
            style: TextStyle(
              fontWeight: FontWeight.w400,
              fontSize: 14.sp,
              color: Colors.grey.shade700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingTask(String task, String lastDate, status) {
    DateTime lastServiceDate = DateTime.parse(lastDate);
    String lastDateFormatted = DateFormat('hh:mm a, dd-MM-yy').format(lastServiceDate);
    return _buildContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Upcoming Task',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18.sp),
              ),
              Spacer(),
              Text(
                '$status, ',
              ),
              Text(lastDateFormatted)
            ],
          ),
          const Divider(color: Colors.grey, thickness: 1.07),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.notifications_none_outlined),
              SizedBox(width: 8.w),
              Text(
                '|',
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 16.sp,
                  color: Colors.grey.shade400,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  task,
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    fontSize: 16.sp,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContainer({required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade400),
        color: AppColors.cardColor,
      ),
      child: Padding(padding: const EdgeInsets.all(16.0), child: child),
    );
  }
}
