import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:maintenance_genie/presentation/view_models/notification_provider.dart';
import 'package:provider/provider.dart';

import '../app/routes/route_names.dart';

class CustomAppBar extends StatelessWidget {
  const CustomAppBar({super.key, this.isInNotificationScreen = false});

  final bool isInNotificationScreen;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Image.asset('assets/icons/app_logo.png', height: 54.h),
            SizedBox(width: 8.w),
            Text(
              'Maintenance\nGenie',
              style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            if (!isInNotificationScreen) const _NotificationBell(),
          ],
        ),
      ],
    );
  }
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell();

  @override
  Widget build(BuildContext context) {
    final unread = context.select<NotificationProvider, int>(
          (p) => p.unreadCount,
    );
    final hasUnread = unread > 0;

    return Semantics(
      button: true,
      label: hasUnread ? 'Notifications, $unread unread' : 'Notifications',
      child: InkResponse(
        radius: 24.r,
        onTap: () => Navigator.pushNamed(context, RouteName.notifications),
        child: Padding(
          padding: EdgeInsets.all(8.w),
          child: Badge(
            isLabelVisible: hasUnread,
            backgroundColor: const Color(0xFFE5484D),
            textColor: Colors.white,
            label: Text(unread > 99 ? '99+' : '$unread'),
            child: Icon(
              hasUnread
                  ? Icons.notifications_active
                  : Icons.notifications_active_outlined,
              size: 24.w,
            ),
          ),
        ),
      ),
    );
  }
}