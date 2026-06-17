

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
                        "Task List",
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(
                        width: 120.w,
                        child: PrimaryButton(
                          text: 'Add Items',
                          onPressed:
                              () => Navigator.pushNamed(
                                context,
                                RouteName.addItem,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20.h),
                Consumer<AllItemListProvider>(
                  builder: (context, provider, child) {
                    if (provider.loading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (provider.errorFetchingAllItems != '') {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(height: 30.h),
                            Text(provider.errorFetchingAllItems ?? 'Something went wrong', style: TextStyle(fontSize: 16.sp)),
                            SizedBox(height: 16.h),
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.3,
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
                      child: Expanded(
                        child: SingleChildScrollView(
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
                              SizedBox(
                                height: 380.h,
                                child: TabBarView(
                                  children: [
                                    buildTable(context, items, provider),
                                    buildTable(context, items.where((item) => item.category == 'Vehicle',).toList(), provider,),
                                    buildTable(context, items.where((item) => item.category == 'Appliance',).toList(), provider,),
                                    buildTable(context, items.where((item) => item.category != 'Vehicle' && item.category != 'Appliance',).toList(), provider,),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
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

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: SingleChildScrollView(
          child: DataTable(
            showCheckboxColumn: false,
            dataRowMinHeight: 56,
            dataRowMaxHeight: 72,
            headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
            columns: [
              DataColumn(
                label: Text(
                  'Category',
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    fontSize: 12.sp,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Name',
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    fontSize: 12.sp,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Model',
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    fontSize: 12.sp,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ],
            rows:
                data.map((item) {
                  return DataRow(
                    selected: false,
                    onSelectChanged: (selected) async {
                      if (selected ?? false) {
                        Navigator.pushNamed(context, RouteName.itemDetails, arguments: item.id,);
                        provider.setId(item.id);
                        context.read<ItemTaskListByItemIdProvider>().setItemId(item.id ?? '');
                      }
                    },
                    cells: [
                      DataCell(Text(item.category ?? 'N/A')),
                      DataCell(Text(item.name ?? 'N/A')),
                      DataCell(Text(item.model ?? 'N/A', maxLines: 3, overflow: TextOverflow.ellipsis,),
                      ),
                    ],
                  );
                }).toList(),
          ),
        ),
      ),
    );
  }
}
