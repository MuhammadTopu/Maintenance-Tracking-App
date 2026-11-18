import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:maintenance_genie/core/constants/app_colors.dart';
import 'package:maintenance_genie/data/models/notification_response_model.dart';
import 'package:maintenance_genie/shared/shimmer_skeletons.dart';

// -----------------------------------------------------------------------------
// Per-type look
// -----------------------------------------------------------------------------

extension NotificationTypeStyle on NotificationType {
  IconData get icon => switch (this) {
    NotificationType.login => Icons.login_rounded,
    NotificationType.welcome => Icons.celebration_outlined,
    NotificationType.itemAdded => Icons.add_box_outlined,
    NotificationType.tasksCreated => Icons.checklist_rounded,
    NotificationType.taskReminder => Icons.alarm_rounded,
    NotificationType.premiumActivated => Icons.workspace_premium_outlined,
    NotificationType.premiumRenewed => Icons.autorenew_rounded,
    NotificationType.premiumCancelled => Icons.cancel_outlined,
    NotificationType.premiumPaymentIssue => Icons.credit_card_off_outlined,
    NotificationType.premiumExpired => Icons.hourglass_bottom_rounded,
    NotificationType.premiumRefunded => Icons.currency_exchange,
    NotificationType.reportUpdate => Icons.support_agent_rounded,
    NotificationType.system => Icons.campaign_outlined,
    NotificationType.unknown => Icons.notifications_none_rounded,
  };

  Color get color => switch (this) {
    NotificationType.login => const Color(0xFF3A83AD),
    NotificationType.welcome => const Color(0xFF8E5BD0),
    NotificationType.itemAdded => const Color(0xFF2E9E6B),
    NotificationType.tasksCreated => AppColors.primaryColor,
    NotificationType.taskReminder => const Color(0xFFE08A00),
    NotificationType.premiumActivated ||
    NotificationType.premiumRenewed => const Color(0xFFB7791F),
    NotificationType.premiumCancelled ||
    NotificationType.premiumExpired => const Color(0xFF8A6D3B),
    NotificationType.premiumPaymentIssue => const Color(0xFFD64545),
    NotificationType.premiumRefunded => const Color(0xFF5B7083),
    NotificationType.reportUpdate => const Color(0xFF6C5CE7),
    NotificationType.system => const Color(0xFF4A8DB5),
    NotificationType.unknown => const Color(0xFF7A8794),
  };
}

String formatNotificationTime(DateTime? created) {
  if (created == null) return '';
  final now = DateTime.now();
  final local = created.toLocal();
  final diff = now.difference(local);

  if (diff.isNegative || diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays == 1) return 'Yesterday';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return DateFormat(
    local.year == now.year ? 'MMM d' : 'MMM d, yyyy',
  ).format(local);
}

// -----------------------------------------------------------------------------
// Tile
// -----------------------------------------------------------------------------

class NotificationTile extends StatelessWidget {
  const NotificationTile({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onMarkRead,
    required this.onDelete,
    this.busy = false,
  });

  final AppNotification notification;
  final bool busy;
  final VoidCallback onTap;
  final VoidCallback onMarkRead;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final n = notification;
    final accent = n.type.color;
    final unread = !n.isRead;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: onTap,
        child: Ink(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: unread ? const Color(0xffF0FAF9) : Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: unread
                  ? AppColors.primaryColor.withValues(alpha: 0.35)
                  : Colors.grey.shade200,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(n.type.icon, size: 20.sp, color: accent),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            n.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: unread
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: const Color(0xff1D1F2C),
                            ),
                          ),
                        ),
                        if (unread) ...[
                          SizedBox(width: 8.w),
                          Padding(
                            padding: EdgeInsets.only(top: 4.h),
                            child: Container(
                              width: 8.w,
                              height: 8.w,
                              decoration: BoxDecoration(
                                color: AppColors.primaryColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (n.body.isNotEmpty) ...[
                      SizedBox(height: 4.h),
                      Text(
                        n.body,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.sp,
                          height: 1.35,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                    SizedBox(height: 10.h),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 13.sp,
                          color: Colors.grey.shade500,
                        ),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: Text(
                            formatNotificationTime(n.createdAt),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ),
                        if (unread) ...[
                          _MiniAction(
                            icon: Icons.done_all_rounded,
                            label: 'Mark read',
                            color: AppColors.primaryColor,
                            onPressed: busy ? null : onMarkRead,
                          ),
                          SizedBox(width: 8.w),
                        ],
                        _MiniAction(
                          icon: Icons.delete_outline_rounded,
                          label: 'Delete',
                          color: const Color(0xFFD64545),
                          onPressed: busy ? null : onDelete,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniAction extends StatelessWidget {
  const _MiniAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final foreground = enabled ? color : Colors.grey.shade400;

    return InkWell(
      borderRadius: BorderRadius.circular(20.r),
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
        decoration: BoxDecoration(
          color: foreground.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14.sp, color: foreground),
            SizedBox(width: 4.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Skeleton
// -----------------------------------------------------------------------------

class NotificationTileSkeleton extends StatelessWidget {
  const NotificationTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: const Color(0xffF0FAF9),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: AppShimmer(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(width: 40.w, height: 40.w, radius: 20),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 150.w, height: 14.h),
                  SizedBox(height: 8.h),
                  SkeletonBox(height: 12.h),
                  SizedBox(height: 6.h),
                  SkeletonBox(width: 190.w, height: 12.h),
                  SizedBox(height: 12.h),
                  Align(
                    alignment: Alignment.centerRight,
                    child: SkeletonBox(width: 90.w, height: 24.h, radius: 20),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}