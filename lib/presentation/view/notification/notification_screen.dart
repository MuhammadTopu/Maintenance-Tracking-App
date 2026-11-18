import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:maintenance_genie/app/controller/notification_navigator.dart';
import 'package:maintenance_genie/core/constants/app_colors.dart';
import 'package:maintenance_genie/data/models/notification_response_model.dart';
import 'package:maintenance_genie/presentation/view/notification/widget/notification_tile.dart';
import 'package:maintenance_genie/presentation/view_models/notification_provider.dart';
import 'package:maintenance_genie/shared/custom_item_app_bar.dart';
import 'package:maintenance_genie/shared/empty_state_widget.dart';
import 'package:provider/provider.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  static const double _loadMoreThreshold = 240;

  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(context.read<NotificationProvider>().refresh());
    });
  }

  @override
  void dispose() {
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final position = _scroll.position;
    if (position.pixels >= position.maxScrollExtent - _loadMoreThreshold) {
      unawaited(context.read<NotificationProvider>().loadMore());
    }
  }

  void _fillViewportIfNeeded() {
    if (!mounted || !_scroll.hasClients) return;
    final provider = context.read<NotificationProvider>();
    final canLoad =
        provider.hasMore &&
            !provider.isLoading &&
            !provider.isLoadingMore &&
            !provider.loadMoreFailed;
    if (canLoad && _scroll.position.maxScrollExtent <= 0) {
      unawaited(provider.loadMore());
    }
  }

  Future<void> _open(AppNotification notification) async {
    final provider = context.read<NotificationProvider>();
    unawaited(provider.markAsRead(notification.id));

    final target = NotificationTarget.fromNotification(notification);
    if (target.opensTask) {
      await NotificationNavigator.instance.openTask(
        itemId: target.itemId!,
        taskId: target.taskId!,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 12.h),
              CustomItemAppBar(
                title: 'Notifications',
                onTap: () => Navigator.maybePop(context),
              ),
              SizedBox(height: 8.h),
              const _MarkAllRow(),
              SizedBox(height: 4.h),
              Expanded(
                child: Consumer<NotificationProvider>(
                  builder: (context, provider, _) {
                    WidgetsBinding.instance.addPostFrameCallback(
                          (_) => _fillViewportIfNeeded(),
                    );
                    return _buildBody(provider);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(NotificationProvider provider) {
    if (provider.isLoading) {
      return ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.only(top: 8.h, bottom: 16.h),
        itemCount: 6,
        separatorBuilder: (_, __) => SizedBox(height: 10.h),
        itemBuilder: (_, __) => const NotificationTileSkeleton(),
      );
    }

    if (provider.hasError) {
      return _scrollable(
        EmptyState(
          icon: Icons.cloud_off_outlined,
          title: 'Could not load notifications',
          subtitle: 'Check your connection and try again.',
          onRetry: provider.loadInitial,
        ),
        provider,
      );
    }

    if (provider.items.isEmpty) {
      return _scrollable(
        const EmptyState(
          icon: Icons.notifications_none_rounded,
          title: 'No notifications yet',
          subtitle: 'Reminders and updates about your assets will show up here.',
        ),
        provider,
      );
    }

    final items = provider.items;
    return RefreshIndicator(
      color: AppColors.primaryColor,
      onRefresh: () => provider.refresh(userInitiated: true),
      child: ListView.separated(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(top: 8.h, bottom: 16.h),
        itemCount: items.length + 1, // +1 = footer
        separatorBuilder: (_, __) => SizedBox(height: 10.h),
        itemBuilder: (context, index) {
          if (index == items.length) {
            return _ListFooter(provider: provider);
          }
          final notification = items[index];
          return NotificationTile(
            key: ValueKey(notification.id),
            notification: notification,
            busy: provider.isBusy(notification.id),
            onTap: () => _open(notification),
            onMarkRead: () => provider.markAsRead(notification.id),
            onDelete: () => provider.delete(notification.id),
          );
        },
      ),
    );
  }

  Widget _scrollable(Widget child, NotificationProvider provider) {
    return RefreshIndicator(
      color: AppColors.primaryColor,
      onRefresh: () => provider.refresh(userInitiated: true),
      child: LayoutBuilder(
        builder: (context, constraints) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [SizedBox(height: constraints.maxHeight, child: child)],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// "n unread" + Mark all as read
// -----------------------------------------------------------------------------

class _MarkAllRow extends StatelessWidget {
  const _MarkAllRow();

  @override
  Widget build(BuildContext context) {
    final (unread, marking) = context
        .select<NotificationProvider, (int, bool)>(
          (p) => (p.unreadCount, p.isMarkingAll),
    );
    final enabled = unread > 0 && !marking;

    return Row(
      children: [
        Expanded(
          child: Text(
            unread > 0 ? '$unread unread' : 'You are all caught up',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        TextButton(
          onPressed: enabled
              ? () => unawaited(
            context.read<NotificationProvider>().markAllAsRead(),
          )
              : null,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primaryColor,
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            minimumSize: Size(0, 32.h),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: marking
              ? SizedBox(
            width: 16.w,
            height: 16.w,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primaryColor,
            ),
          )
              : Text(
            'Mark all as read',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Footer: spinner while loading more, retry on failure
// -----------------------------------------------------------------------------

class _ListFooter extends StatelessWidget {
  const _ListFooter({required this.provider});

  final NotificationProvider provider;

  @override
  Widget build(BuildContext context) {
    if (provider.isLoadingMore) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: Center(
          child: SizedBox(
            width: 22.w,
            height: 22.w,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: AppColors.primaryColor,
            ),
          ),
        ),
      );
    }

    if (provider.loadMoreFailed) {
      return Center(
        child: TextButton.icon(
          onPressed: () => unawaited(provider.loadMore()),
          icon: Icon(Icons.refresh_rounded, size: 18.sp),
          label: Text(
            'Could not load more. Tap to retry',
            style: TextStyle(fontSize: 13.sp),
          ),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primaryColor,
          ),
        ),
      );
    }

    return SizedBox(height: 8.h);
  }
}