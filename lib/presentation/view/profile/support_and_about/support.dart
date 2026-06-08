import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../shared/custom_item_app_bar.dart';

class Support extends StatefulWidget {
  const Support({super.key});

  @override
  State<Support> createState() => _SupportState();
}

class _SupportState extends State<Support> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Container(
          color: Colors.white, // Set the background color to white here
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(16.0),
                child: CustomItemAppBar(
                  title: 'Support',
                  onTap: Navigator.of(context).pop,
                ),
              ),
              SizedBox(height: 8.h),
              Container(
                width: double.infinity,
                height: 40,
                color: Color(0xffEEF5F9),
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: const Text(
                  'Support',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
              ListTile(
                leading: Image.asset("assets/icons/faq.png", scale: 2.5,),
                title: Text('FAQ'),
                trailing: Image.asset("assets/icons/arrow_right.png", scale: 2.5,),
                onTap: () {
                  Navigator.pushNamed(context, RouteName.faq);
                }

              ),
              ListTile(
                leading: Image.asset("assets/icons/mail.png", scale: 2.5,),
                title: Text('Mail'),
                trailing: Image.asset("assets/icons/arrow_right.png", scale: 2.5,),
                onTap: () {
                  Navigator.pushNamed(context, RouteName.supportNext);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
