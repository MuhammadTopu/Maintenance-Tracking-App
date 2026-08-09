

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:maintenance_genie/core/constants/app_colors.dart';
import 'package:provider/provider.dart';

import '../../../app/routes/route_names.dart';
import '../../../data/models/all_item_list_model.dart';
import '../../../shared/common_widgets.dart';
import '../../../shared/custom_app_bar.dart';
import '../../view_models/all_item_list_provider.dart';
import '../../view_models/item_task_list_by_item_id_provider.dart';

class ItemsMenuScreen extends StatefulWidget {
  const ItemsMenuScreen({super.key});

  @override
  State<ItemsMenuScreen> createState() => _ItemsMenuScreenState();
}

class _ItemsMenuScreenState extends State<ItemsMenuScreen> {
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AllItemListProvider>().getAllItem();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffFFFFFF),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: RefreshIndicator(
            onRefresh: () async {
              await context.read<AllItemListProvider>().getAllItem();
            },
            child: Column(
              children: [
                const CustomAppBar(),
                SizedBox(height: 20.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Assets List",
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      GestureDetector(
                        onTap: () => Navigator.pushNamed(
                          context,
                          RouteName.addItem,
                        ),
                        child: Container(
                          height: 48.h,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(90.r),
                            color: AppColors.primaryColor,
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 24.w),
                          child: Center(
                            child: Text(
                              'Add Assets',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20.h),
                Expanded(
                  child: Consumer<AllItemListProvider>(
                    builder: (context, provider, child) {
                      if (provider.loading) {
                        return const Center(child: CircularProgressIndicator(color: AppColors.primaryColor,));
                      }

                      if (provider.errorFetchingAllItems != '') {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(provider.errorFetchingAllItems ?? 'Something went wrong', style: TextStyle(fontSize: 16.sp)),
                              SizedBox(height: 16.h),
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.3,
                                height: 40.h,
                                child: PrimaryButton(
                                  text: 'Retry',
                                  onPressed: () => provider.getAllItem(),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final items = provider.allItemListModel?.items ?? [];
                      if (items.isEmpty) {
                        return const Center(child: Text('No items available'));
                      }

                      return DefaultTabController(
                        length: 4,
                        child: Column(
                          children: [
                            const TabBar(
                              tabAlignment: TabAlignment.center,
                              labelColor: Colors.teal,
                              unselectedLabelColor: Colors.black,
                              indicatorColor: Colors.teal,
                              indicatorSize: TabBarIndicatorSize.tab,
                              indicatorWeight: 1,
                              tabs: [
                                Tab(text: 'All'),
                                Tab(text: 'Vehicle'),
                                Tab(text: 'Home'),
                                Tab(text: 'Custom'),
                              ],
                            ),
                            SizedBox(height: 16.h),

                            Expanded(
                              child: TabBarView(
                                children: [
                                  buildTable(context, items, provider),
                                  buildTable(
                                    context,
                                    items.where((item) => item.category == 'Vehicle').toList(),
                                    provider,
                                  ),
                                  buildTable(
                                    context,
                                    items.where((item) => item.category == 'Appliance').toList(),
                                    provider,
                                  ),
                                  buildTable(
                                    context,
                                    items
                                        .where((item) =>
                                    item.category != 'Vehicle' &&
                                        item.category != 'Appliance')
                                        .toList(),
                                    provider,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 80.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildTable(BuildContext context, List<Items> data, provider) {
    if (data.isEmpty) {
      return const Center(child: Text('No items in this category'));
    }

    const int columnCount = 4;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double columnSpacing = 0;
            final double availableWidth = constraints.maxWidth;
            final double columnWidth = availableWidth / columnCount;

            Widget cellText(String text) {
              return SizedBox(
                width: columnWidth,
                child: Text(
                  text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }

            Widget headerText(String text) {
              return SizedBox(
                width: columnWidth,
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    fontSize: 12.sp,
                    color: Colors.grey.shade700,
                  ),
                ),
              );
            }

            return SingleChildScrollView(
              child: SizedBox(
                width: constraints.maxWidth,
                child: DataTable(
                  showCheckboxColumn: false,
                  dataRowMinHeight: 56,
                  dataRowMaxHeight: 72,
                  columnSpacing: columnSpacing,
                  headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
                  dataRowColor: WidgetStateProperty.resolveWith<Color?>(
                        (Set<WidgetState> states) => Colors.white,
                  ),
                  columns: [
                    DataColumn(label: headerText('Category')),
                    DataColumn(label: headerText('Make')),
                    DataColumn(label: headerText('Model')),
                    DataColumn(label: headerText('Name')),
                  ],
                  rows: data.map((item) {
                    return DataRow(
                      selected: false,
                      onSelectChanged: (selected) async {
                        if (selected ?? false) {
                          Navigator.pushNamed(
                            context,
                            RouteName.itemDetails,
                            arguments: item.id,
                          );
                          provider.setId(item.id);
                          context
                              .read<ItemTaskListByItemIdProvider>()
                              .setItemId(item.id);
                        }
                      },
                      cells: [
                        DataCell(cellText(item.category)),
                        DataCell(cellText(item.brand)),
                        DataCell(cellText(item.model)),
                        DataCell(cellText(item.name)),
                      ],
                    );
                  }).toList(),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
