import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:maintenance_genie/core/constants/app_colors.dart';
import 'package:maintenance_genie/data/models/item.dart';
import 'package:maintenance_genie/shared/item_display.dart';
import 'package:provider/provider.dart';
import '../../../app/routes/route_names.dart';
import '../../../shared/custom_app_bar.dart';
import '../../../shared/empty_state_widget.dart';
import '../../view_models/all_item_list_provider.dart';
import '../../view_models/item_task_list_by_item_id_provider.dart';

class _Palette {
  _Palette._();

  static const Color headerRow = Color(0xFFE6F1F8);
  static const Color zebra = Color(0xFFF7FBFD);
  static const Color rowHighlight = Color(0xFFEAF4FA);
  static const Color border = Color(0xFFD3E5F0);
  static const Color divider = Color(0xFFE0ECF4);
  static const Color headerText = Color(0xFF3F7FA5);
  static const Color buttonEnd = Color(0xFF4A8DB5);
}

class ItemsMenuScreen extends StatefulWidget {
  const ItemsMenuScreen({super.key});

  @override
  State<ItemsMenuScreen> createState() => _ItemsMenuScreenState();
}

class _ItemsMenuScreenState extends State<ItemsMenuScreen> {
  static const List<double> _columnFractions = [0.22, 0.33, 0.45];

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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: RefreshIndicator(
            color: AppColors.primaryColor,
            backgroundColor: Colors.white,
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
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.primaryColor,
                                _Palette.buttonEnd,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryColor.withValues(
                                  alpha: 0.28,
                                ),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
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
                        return EmptyState(
                          icon: Icons.error_outline_rounded,
                          title: 'Unable to load assets',
                          subtitle: provider.errorFetchingAllItems,
                          onRetry: () => provider.getAllItem(),
                        );
                      }

                      final items = provider.allItemListModel?.items ?? <Item>[];
                      if (items.isEmpty) {
                        return EmptyState(
                          icon: Icons.inventory_2_outlined,
                          title: 'No assets yet',
                          subtitle: 'Add your first asset to start tracking its maintenance.',
                          retryText: 'Add Assets',
                          onRetry: () => Navigator.pushNamed(context, RouteName.addItem),
                        );
                      }

                      return DefaultTabController(
                        length: 4,
                        child: Column(
                          children: [
                            TabBar(
                              tabAlignment: TabAlignment.center,
                              labelColor: AppColors.primaryColor,
                              unselectedLabelColor: AppColors.secondaryTextColor,
                              indicatorColor: AppColors.primaryColor,
                              dividerColor: _Palette.border,
                              indicatorSize: TabBarIndicatorSize.tab,
                              indicatorWeight: 1.5,
                              splashFactory: NoSplash.splashFactory,
                              overlayColor: WidgetStateProperty.all(Colors.transparent),
                              labelStyle: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                              ),
                              unselectedLabelStyle: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w400,
                              ),
                              tabs: [
                                Tab(text: 'All'),
                                Tab(text: 'Vehicle'),
                                Tab(text: 'Home'),
                                Tab(text: 'Others'),
                              ],
                            ),
                            SizedBox(height: 16.h),

                            Expanded(
                              child: TabBarView(
                                children: [
                                  buildTable(context, items, provider),
                                  buildTable(
                                    context,
                                    items.whereType<VehicleItem>().toList(),
                                    provider,
                                    categoryLabel: 'vehicle',
                                  ),
                                  buildTable(
                                    context,
                                    items.whereType<HomeItem>().toList(),
                                    provider,
                                    categoryLabel: 'home',
                                  ),
                                  buildTable(
                                    context,
                                    items
                                        .where((item) =>
                                    item is! VehicleItem && item is! HomeItem)
                                        .toList(),
                                    provider,
                                    categoryLabel: 'other',
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

  Widget buildTable(
      BuildContext context,
      List<Item> data,
      AllItemListProvider provider, {
        String categoryLabel = 'matching',
      }) {
    if (data.isEmpty) {
      return EmptyState(
        icon: Icons.category_outlined,
        title: 'No $categoryLabel assets',
        subtitle: 'Assets you add in this category will appear here.',
      );
    }

    final int columnCount = _columnFractions.length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: _Palette.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: LayoutBuilder(
          builder: (context, constraints) {
            double columnWidth(int col) =>
                constraints.maxWidth * _columnFractions[col];

            Widget divider(double height) => Container(
              width: 1,
              height: height,
              color: _Palette.divider,
            );

            Widget cell(Widget child, int col, double dividerHeight) {
              final isLast = col == columnCount - 1;
              return SizedBox(
                width: columnWidth(col),
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12.w),
                        child: child,
                      ),
                    ),
                    if (!isLast) divider(dividerHeight),
                  ],
                ),
              );
            }

            Widget cellText(
                String text,
                int col, {
                  bool bold = false,
                  Color color = AppColors.primaryTextColor,
                }) => cell(
              Text(
                text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontWeight: bold ? FontWeight.w600 : null,
                ),
              ),
              col,
              28.h,
            );

            Widget headerText(String text, int col) => cell(
              Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12.sp,
                  color: _Palette.headerText,
                ),
              ),
              col,
              20.h,
            );

            // Same table, same rows – only the colours differ. The Theme only
            // recolours the thin lines DataTable draws between rows.
            return Theme(
              data: Theme.of(context).copyWith(
                dividerColor: _Palette.divider,
                dividerTheme: const DividerThemeData(color: _Palette.divider),
              ),
              child: SingleChildScrollView(
                child: SizedBox(
                  width: constraints.maxWidth,
                  child: DataTable(
                    showCheckboxColumn: false,
                    horizontalMargin: 0,
                    columnSpacing: 0,
                    dataRowMinHeight: 56.h,
                    dataRowMaxHeight: 72.h,
                    headingRowColor: WidgetStateProperty.all(_Palette.headerRow),
                    columns: [
                      DataColumn(label: headerText('Category', 0)),
                      DataColumn(label: headerText('Name', 1)),
                      DataColumn(label: headerText('Details', 2)),
                    ],
                    rows: List<DataRow>.generate(data.length, (index) {
                      final item = data[index];
                      final base = index.isEven ? Colors.white : _Palette.zebra;

                      return DataRow(
                        selected: false,
                        color: WidgetStateProperty.resolveWith<Color?>(
                              (states) =>
                          states.contains(WidgetState.hovered) ||
                              states.contains(WidgetState.focused)
                              ? _Palette.rowHighlight
                              : base,
                        ),
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
                          DataCell(
                            cellText(
                              item.category,
                              0,
                              color: AppColors.primaryTextColor,
                            ),
                          ),
                          DataCell(cellText(item.name, 1, bold: false)),
                          DataCell(
                            cellText(
                              itemSummary(item),
                              2,
                              color: AppColors.secondaryTextColor,
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}