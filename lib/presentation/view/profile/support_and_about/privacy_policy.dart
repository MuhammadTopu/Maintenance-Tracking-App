import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../shared/custom_item_app_bar.dart';


class PrivacyPolicy extends StatefulWidget {
  const PrivacyPolicy({super.key});

  @override
  State<PrivacyPolicy> createState() => _PrivacyPolicyState();
}

class _PrivacyPolicyState extends State<PrivacyPolicy> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: SafeArea(
        child: Container(
          color: Colors.white, // Set the background color to white here
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                  'At Maintenance Genie, we value your privacy. This policy explains how we collect, use, and protect your data when you use our app.',
                  style: TextStyle(color: Colors.black54, fontSize: 16.0),
                ),
                const SizedBox(height: 24.0),

                const Text(
                  'Information We Collect',
                  style: TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8.0),
                _buildBulletPoint(
                  'Personal Info: Name, email, phone number (only when you sign up)',
                ),
                _buildBulletPoint(
                  'Asset Data: Vehicle/home/equipment details you enter',
                ),
                _buildBulletPoint(
                  'Usage Data: App interactions and preferences (to improve user experience)',
                ),
                const SizedBox(height: 24.0),

                const Text(
                  'How We Use Your Information',
                  style: TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8.0),
                _buildBulletPoint('To send you reminders and notifications'),
                _buildBulletPoint(
                  'To improve features and personalize your experience',
                ),
                _buildBulletPoint(
                  'To offer relevant service provider suggestions',
                ),
                _buildBulletPoint('For customer support and updates'),
                const SizedBox(height: 24.0),

                const Text(
                  'Data Protection',
                  style: TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8.0),
                const Text(
                  'We store your data securely and do not sell it to third parties. All sensitive data is encrypted and access-controlled.',
                  style: TextStyle(color: Colors.black54, fontSize: 16.0),
                ),
              ],
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
              color: Colors.black87,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16.0,
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
