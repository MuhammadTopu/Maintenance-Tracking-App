import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';

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
            Spacer(),
            if (!isInNotificationScreen)
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, RouteName.notifications);
                },
                child: Icon(Icons.notifications_active_outlined, size: 24.w,),
              ),
          ],
        ),
        // SizedBox(height: 20.h),
        // Container(
        //   height: 40.h,
        //   decoration: BoxDecoration(
        //     color: Color(0xffF6F8FA),
        //     borderRadius: BorderRadius.circular(8.r),
        //   ),
        //   child: TextField(
        //     decoration: InputDecoration(
        //       hintText: 'Search',
        //       prefixIcon: const Icon(Icons.search),
        //       border: InputBorder.none,
        //       contentPadding: EdgeInsets.symmetric(vertical: 10.h),
        //     ),
        //   ),
        // ),
      ],
    );
  }
}
