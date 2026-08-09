import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../shared/custom_item_app_bar.dart';

class About extends StatefulWidget {
  const About({super.key});

  @override
  State<About> createState() => _AboutState();
}

class _AboutState extends State<About> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Container(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CustomItemAppBar(
                      title: 'About',
                      onTap: Navigator.of(context).pop,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Divider(color: Color(0xffE9E9EA), thickness: 1),
                  const Text(
                    'Maintenance Genie is your all-in-one maintenance assistant for bikes, homes, and equipment. We help you stay on top of every oil change, filter replacement, or seasonal checkup so your things last longer and perform better. From smart reminders to expert-backed service intervals, Maintenance Genie takes the guesswork out of upkeep.',
                    style: TextStyle(color: Colors.black54, fontSize: 16.0),
                  ),
                  const SizedBox(height: 30),
              
                  const Text(
                    'Why Us',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8.0), // Spacing after "Why Us" title
                  _buildBulletPoint('Track all your assets in one place'),
                  _buildBulletPoint('Get reminders before things go wrong'),
                  _buildBulletPoint(
                    'Follow manufacturer-recommended service intervals',
                  ),
                  _buildBulletPoint(
                    'Discover trusted service providers near you',
                  ),
                  _buildBulletPoint(
                    'Learn from real users in our maintenance forum',
                  ),
                  const SizedBox(height: 24.0),
              
                  const Text(
                    'Our Mission',
                    style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8.0),
                  const Text(
                    'We believe that smart maintenance saves money, time, and stress. Our goal is to make upkeep simple, organized, and accessible for everyone.',
                    style: TextStyle(color: Colors.black54, fontSize: 16.0),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16.0, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}
