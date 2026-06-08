import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../shared/custom_item_app_bar.dart';


class TermsAndConditions extends StatelessWidget {
  const TermsAndConditions({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Set background color to white

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.all(8.0),
                child: CustomItemAppBar(
                  title: 'Terms and Conditions',
                  onTap: Navigator.of(context).pop,
                ),
              ),
              SizedBox(height: 8.h),
              Divider(color: Color(0xffE9E9EA), thickness: 1),              const Text(
                'By using Maintenance Genie, you agree to the following terms. Please read them carefully.',
                style: TextStyle(color: Colors.black54, fontSize: 16.0),
              ),
              const SizedBox(height: 24.0),

              const Text(
                'User Accounts',
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8.0),
              _buildBulletPoint('You must provide accurate information during registration'),
              _buildBulletPoint('You are responsible for keeping your login credentials secure'),
              _buildBulletPoint('You agree not to share your account with others'),
              const SizedBox(height: 24.0),

              const Text(
                'Premium Features',
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8.0),
              const Text(
                'Certain features (like service provider suggestions and forums) are available only through a paid subscription. Payment terms are handled securely by our payment processor.',
                style: TextStyle(color: Colors.black54, fontSize: 16.0),
              ),
              const SizedBox(height: 24.0),

              const Text(
                'Data Usage',
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8.0),
              const Text(
                'We collect and store information you enter to improve your experience. See our Privacy Policy for details on how we protect and use your data.',
                style: TextStyle(color: Colors.black54, fontSize: 16.0),
              ),
              const SizedBox(height: 24.0),

              const Text(
                'Limitations',
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8.0),
              const Text(
                'We do not guarantee that all maintenance suggestions or service intervals will be 100% accurate. Always consult your owner\'s manual or a certified professional when needed.',
                style: TextStyle(color: Colors.black54, fontSize: 16.0),
              ),
              const SizedBox(height: 16.0),
            ],
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
            style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Colors.black54),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16.0, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}
