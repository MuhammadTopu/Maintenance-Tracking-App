import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/item.dart';
import '../../../shared/custom_item_app_bar.dart';
import '../../../shared/empty_state_widget.dart';
import '../../../shared/item_display.dart';
import '../../view_models/all_item_list_provider.dart';
import '../../view_models/item_task_list_by_item_id_provider.dart';
import '../../view_models/user_provider.dart';
import 'widgets/forum_suggestion_card_widget.dart';
import 'widgets/item_tasks_section.dart';

class ItemDetailsScreen extends StatefulWidget {
  final String? itemId;
  const ItemDetailsScreen({super.key, this.itemId});

  @override
  State<ItemDetailsScreen> createState() => _ItemDetailsScreenState();
}

class _ItemDetailsScreenState extends State<ItemDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final tasks = context.read<ItemTaskListByItemIdProvider>();
      final id = widget.itemId;
      if (id != null && id.isNotEmpty) tasks.setItemId(id);
      tasks.loadItemTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    return Scaffold(
      backgroundColor: const Color(0xffFFFFFF),
      body: SafeArea(
        child: Consumer<AllItemListProvider>(
          builder: (context, provider, child) {
            if (provider.itemDetailsLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primaryColor),
              );
            }
            if (provider.errorFetchingOneItem != '') {
              return Center(child: Text(provider.errorFetchingOneItem!));
            }
            final item = provider.oneItemModel?.item;
            if (item == null) {
              return EmptyState(
                icon: Icons.inventory_2_outlined,
                title: 'No item data available',
                subtitle: 'Add an asset to get started.',
              );
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
                      item.name,
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Column(
                      spacing: 4,
                      children: [
                        for (final row in itemInfoRows(item))
                          _buildInfoRow(
                            title: '${row.key} : ',
                            value: row.value,
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
                        child: item.imageUrl == null
                            ? _buildNoImage()
                            : Image.network(
                          item.imageUrl!,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value:
                                loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                    : null,
                                color: AppColors.primaryColor,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) =>
                              _buildNoImage(),
                        ),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    const ItemTasksSection(),
                    SizedBox(height: 12.h),
                    _buildServiceIntervals(item),
                    SizedBox(height: 12.h),
                    _buildContainer(
                      child: ForumSuggestionsCard(
                        response: provider.oneItemModel!,
                        isPremium:
                        userProvider.userResponse?.data.isPremium ?? false,
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

  Widget _buildNoImage() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(Icons.image_outlined, size: 30.h),
        SizedBox(height: 12.h),
        Text('No Image Available!', style: TextStyle(fontSize: 14.sp)),
      ],
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
              ? Text('No service intervals available', style: TextStyle(fontSize: 14.sp))
              : Column(
            children: List.generate(item.serviceIntervals.length, (
                index,
                ) {
              return _buildInfoRow(
                title: "",
                value: item.serviceIntervals[index],
              );
            }),
          ),
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
            color: Colors.grey.shade800,
          ),
        ),
        Expanded(
          child: GptMarkdown(
            value.isNotEmpty ? value : 'N/A',
            style: TextStyle(
              fontWeight: FontWeight.w400,
              fontSize: 14.sp,
              color: Colors.grey.shade800,
            ),
          ),
        ),
      ],
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
      child: Padding(padding: EdgeInsets.all(16.w), child: child),
    );
  }
}