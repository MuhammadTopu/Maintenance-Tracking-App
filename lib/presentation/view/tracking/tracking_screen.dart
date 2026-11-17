import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:maintenance_genie/app/routes/route_names.dart';
import 'package:maintenance_genie/core/constants/app_colors.dart';
import 'package:maintenance_genie/data/models/task_list_response_model.dart';
import 'package:maintenance_genie/presentation/view_models/item_task_list_provider.dart';
import 'package:maintenance_genie/shared/custom_app_bar.dart';
import 'package:maintenance_genie/shared/custom_task_card.dart';
import 'package:maintenance_genie/shared/empty_state_widget.dart';
import 'package:maintenance_genie/shared/shimmer_skeletons.dart';
import 'package:provider/provider.dart';

import '../../../core/helper/task_actions.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isFabVisible = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ItemTaskListProvider>().ensureSelectedLoaded();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;

    var visible = _isFabVisible;
    if (position.userScrollDirection == ScrollDirection.reverse) {
      visible = false;
    } else if (position.userScrollDirection == ScrollDirection.forward) {
      visible = true;
    }
    if (position.pixels <= 0) visible = true;

    if (visible != _isFabVisible && mounted) {
      setState(() => _isFabVisible = visible);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffFFFFFF),
      floatingActionButton: AnimatedSlide(
        offset: _isFabVisible ? Offset.zero : const Offset(0, 2),
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        child: AnimatedOpacity(
          opacity: _isFabVisible ? 1 : 0,
          duration: const Duration(milliseconds: 250),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 110, right: 10),
            child: FloatingActionButton(
              backgroundColor: const Color(0xff589DC4),
              onPressed: () => Navigator.pushNamed(context, RouteName.addItem),
              child: Icon(Icons.add, size: 24.sp, color: Colors.white),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.w),
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
                      'Task List',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    _buildFilterDropdown(),
                  ],
                ),
              ),
              Expanded(
                child: Consumer<ItemTaskListProvider>(
                  builder: (context, provider, _) => _buildBody(provider),
                ),
              ),
              SizedBox(height: 80.h),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Filter dropdown
  // ---------------------------------------------------------------------------

  Widget _buildFilterDropdown() {
    return Consumer<ItemTaskListProvider>(
      builder: (context, provider, _) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
          decoration: BoxDecoration(
            color: const Color(0xffF6F8FA),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButton<TaskFilter>(
            value: provider.selectedFilter,
            onChanged: (filter) {
              if (filter == null) return;
              if (_scrollController.hasClients) _scrollController.jumpTo(0);
              provider.selectFilter(filter);
            },
            icon: const Icon(
              Icons.keyboard_arrow_down,
              color: Color(0xffA5A5AB),
            ),
            underline: const SizedBox(),
            dropdownColor: const Color(0xffF6F8FA),
            borderRadius: BorderRadius.circular(12.r),
            items: [
              for (final filter in TaskFilter.values)
                DropdownMenuItem<TaskFilter>(
                  value: filter,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.calendar_month_rounded,
                        size: 20,
                        color: Colors.grey,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        _filterLabel(filter, provider),
                        style: const TextStyle(color: Color(0xff4A4C56)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String _filterLabel(TaskFilter filter, ItemTaskListProvider provider) {
    if (!provider.hasCounts) return filter.label;
    return '${filter.label} (${provider.counts.of(filter)})';
  }

  // ---------------------------------------------------------------------------
  // Body
  // ---------------------------------------------------------------------------

  Widget _buildBody(ItemTaskListProvider provider) {
    final tasks = provider.tasks;

    if (provider.isLoading && tasks.isEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.all(10),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 5,
        itemBuilder: (_, _) => const TaskCardSkeleton(),
      );
    }

    if (provider.hasError) {
      return EmptyState(
        icon: Icons.cloud_off_outlined,
        title: 'Could not load tasks',
        subtitle: 'Check your connection and try again.',
        onRetry: provider.refreshSelected,
      );
    }

    if (tasks.isEmpty) return _buildEmptyState(provider.selectedFilter);

    final showFooter = provider.hasNextPage || provider.isLoadingMore;

    return RefreshIndicator(
      color: AppColors.primaryColor,
      onRefresh: provider.refreshSelected,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(10),
        itemCount: tasks.length + (showFooter ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == tasks.length) return _buildFooter(provider);

          final task = tasks[index];
          return CustomTaskCard(
            key: ValueKey<String>(task.id),
            index: index + 1,
            task: task,
            onTap: () => openTaskDetails(context, task),
          );
        },
      ),
    );
  }

  Widget _buildFooter(ItemTaskListProvider provider) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Column(
        children: [
          Text(
            'Showing ${provider.tasks.length} of ${provider.total}',
            style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600),
          ),
          SizedBox(height: 10.h),
          if (provider.isLoadingMore)
            SizedBox(
              height: 28.h,
              width: 28.h,
              child: const CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.primaryColor,
              ),
            )
          else
            OutlinedButton(
              onPressed: provider.loadMore,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryColor,
                side: const BorderSide(color: AppColors.primaryColor),
                shape: const StadiumBorder(),
                padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 10.h),
              ),
              child: const Text('Load more'),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(TaskFilter filter) {
    final (IconData icon, String title, String subtitle) = switch (filter) {
      TaskFilter.overdue => (
        Icons.event_busy_outlined,
        'No overdue tasks',
        'Tasks that passed their due date will appear here.',
      ),
      TaskFilter.dueNow => (
        Icons.alarm_outlined,
        'Nothing due right now',
        'Tasks that are due today will appear here.',
      ),
      TaskFilter.upcoming => (
        Icons.event_outlined,
        'No upcoming tasks',
        'Tasks that are coming up soon will appear here.',
      ),
      TaskFilter.future => (
        Icons.event_available_outlined,
        'No future tasks',
        'Tasks scheduled further ahead will appear here.',
      ),
      TaskFilter.completed => (
        Icons.task_alt_rounded,
        'No completed tasks',
        'Tasks you finish will appear here.',
      ),
      TaskFilter.all => (
        Icons.assignment_outlined,
        'No tasks available',
        'Tap the + button to add an item and start tracking its service tasks.',
      ),
    };

    return EmptyState(
      icon: icon,
      title: title,
      subtitle: subtitle,
      onRetry: () => context.read<ItemTaskListProvider>().refreshSelected(),
    );
  }
}
