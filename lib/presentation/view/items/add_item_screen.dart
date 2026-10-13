import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:maintenance_genie/core/constants/app_colors.dart';
import '../../../shared/custom_item_app_bar.dart';
import 'tab_forms/home_form.dart';
import 'tab_forms/other_form.dart';
import 'tab_forms/vehicle_form.dart';

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen>
    with SingleTickerProviderStateMixin {
  static const List<String> _tabLabels = ['Vehicle', 'Home', 'Other'];
  static const List<String> _categories = ['Vehicle', 'Home', 'Custom'];

  late final TabController _tabController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabLabels.length, vsync: this)
      ..addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tabController.index == _currentIndex) return;
    setState(() => _currentIndex = _tabController.index);
  }

  @override
  void dispose() {
    _tabController
      ..removeListener(_onTabChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffFFFFFF),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            children: [
              CustomItemAppBar(
                title: 'Add Asset',
                onTap: () => Navigator.pop(context),
              ),

              SizedBox(height: 20.h),

              /// TAB BAR
              Container(
                width: double.infinity,
                height: 42.h,
                padding: EdgeInsets.symmetric(horizontal: 2.5.w),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30.r),
                  color: Colors.white,
                  border: Border.all(color: AppColors.primaryColor, width: 1),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.transparent,
                  labelPadding: EdgeInsets.zero,
                  indicatorPadding: EdgeInsets.zero,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorWeight: 0.1,
                  dividerColor: Colors.transparent,
                  tabs: List.generate(
                    _tabLabels.length,
                        (i) => Tab(
                      height: 36.h,
                      child: _buildTab(_tabLabels[i], _currentIndex == i),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 20.h),

              /// TAB CONTENT
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    VehicleForm(category: _categories[0]),
                    HomeForm(category: _categories[1]),
                    OtherForm(category: _categories[2]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTab(String title, bool isSelected) {
    return Container(
      width: double.infinity,
      height: 36.h,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryColor : Colors.white,
        borderRadius: BorderRadius.circular(30.r),
      ),
      padding: EdgeInsets.all(4.w),
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: isSelected ? Colors.white : const Color(0xff4A4C56),
          fontWeight: FontWeight.w600,
          fontSize: 14.sp,
        ),
      ),
    );
  }
}