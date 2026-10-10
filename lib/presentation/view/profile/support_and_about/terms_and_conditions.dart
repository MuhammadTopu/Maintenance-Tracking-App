import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../shared/custom_item_app_bar.dart';

/// Content will never grow wider than this, so text stays readable
/// on tablets, foldables, and desktop/web instead of stretching edge-to-edge.
const double _kMaxContentWidth = 700.0;

class TermsAndConditions extends StatelessWidget {
  const TermsAndConditions({super.key});

  @override
  Widget build(BuildContext context) {
    final double horizontalPadding = _responsiveHorizontalPadding(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 8.h,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _kMaxContentWidth),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.all(8.w),
                    child: CustomItemAppBar(
                      title: 'Terms and Conditions',
                      onTap: Navigator.of(context).pop,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Divider(color: const Color(0xffE9E9EA), thickness: 1.h),
                  SizedBox(height: 16.h),

                  Text(
                    'By using Maintenance Genie, you agree to the following terms. Please read them carefully.',
                    style: TextStyle(color: Colors.black54, fontSize: 16.sp),
                  ),
                  SizedBox(height: 24.h),

                  _buildSectionTitle('User Accounts'),
                  SizedBox(height: 8.h),
                  _buildBulletPoint('You must provide accurate information during registration, including your name, email, phone number, and address'),
                  _buildBulletPoint('You are responsible for keeping your login credentials secure'),
                  _buildBulletPoint('You agree not to share your account with others'),
                  _buildBulletPoint('You must be at least 13 years old to create an account'),
                  SizedBox(height: 24.h),

                  _buildSectionTitle('Account Deletion'),
                  SizedBox(height: 8.h),
                  Text(
                    'You can delete your account and associated data at any time from within the app. Deletion takes up to 30 days to complete, and logging in during this period cancels the deletion request and restores your account. After 30 days, your account and associated data are permanently deleted. See our Privacy Policy for details on what data is deleted and what may be retained for legal purposes.',
                    style: TextStyle(color: Colors.black54, fontSize: 16.sp),
                  ),
                  SizedBox(height: 24.h),

                  _buildSectionTitle('Description of Service'),
                  SizedBox(height: 8.h),
                  Text(
                    'Maintenance Genie allows users to document, track, and manage maintenance-related tasks for vehicles, homes, and equipment, including the ability to capture and upload photos, receive AI-generated maintenance suggestions, view curated third-party maintenance discussions, and get AI-suggested nearby service providers based on your address. Features and functionality may be updated, modified, or discontinued at our discretion, with or without notice.',
                    style: TextStyle(color: Colors.black54, fontSize: 16.sp),
                  ),
                  SizedBox(height: 24.h),

                  _buildSectionTitle('Premium Features and Subscriptions'),
                  SizedBox(height: 8.h),
                  Text(
                    'Certain features, such as service provider suggestions and community forum content, are available only through a paid subscription. Subscription and purchase management is handled by our third-party provider, RevenueCat, together with your app store account (Google Play or Apple App Store). Subscriptions may renew automatically unless cancelled before the renewal date through your app store account settings. Fees are non-refundable except where required by applicable law.',
                    style: TextStyle(color: Colors.black54, fontSize: 16.sp),
                  ),
                  SizedBox(height: 24.h),

                  _buildSectionTitle('Community Forum Content'),
                  SizedBox(height: 8.h),
                  Text(
                    'You cannot post content to a forum through this app. Instead, the app displays maintenance-related posts sourced from third-party public forums, collected and summarized using AI technology. This content is not created, verified, or endorsed by us, and AI-generated summaries may contain inaccuracies. We may modify or discontinue this feature at any time.',
                    style: TextStyle(color: Colors.black54, fontSize: 16.sp),
                  ),
                  SizedBox(height: 24.h),

                  _buildSectionTitle('Data Usage'),
                  SizedBox(height: 8.h),
                  Text(
                    'We collect and store information you enter to improve your experience, including using your address to generate AI-suggested links to nearby service providers. See our Privacy Policy for details on how we protect and use your data.',
                    style: TextStyle(color: Colors.black54, fontSize: 16.sp),
                  ),
                  SizedBox(height: 24.h),

                  _buildSectionTitle('Acceptable Use'),
                  SizedBox(height: 8.h),
                  _buildBulletPoint('Do not use the app for unlawful purposes'),
                  _buildBulletPoint('Do not attempt to gain unauthorized access to other accounts or systems'),
                  _buildBulletPoint('Do not interfere with or disrupt the app\'s operation'),
                  SizedBox(height: 24.h),

                  _buildSectionTitle('Limitations'),
                  SizedBox(height: 8.h),
                  Text(
                    'We do not guarantee that AI-generated maintenance suggestions, service intervals, third-party forum content, or suggested service providers will be 100% accurate or appropriate for your situation. Always consult your owner\'s manual or a certified professional when needed. The app is provided "as is" without warranties of any kind, and we are not liable for any indirect or consequential damages arising from your use of the app.',
                    style: TextStyle(color: Colors.black54, fontSize: 16.sp),
                  ),
                  SizedBox(height: 24.h),

                  _buildSectionTitle('Intellectual Property'),
                  SizedBox(height: 8.h),
                  Text(
                    'The app and its content, features, and functionality are owned by Big Lick Enterprises and protected by applicable intellectual property laws. You retain ownership of content you submit, but grant us a limited license to store and display it as needed to operate the app. Third-party forum content displayed in the app remains the property of its original authors and platforms.',
                    style: TextStyle(color: Colors.black54, fontSize: 16.sp),
                  ),
                  SizedBox(height: 24.h),

                  _buildSectionTitle('Termination'),
                  SizedBox(height: 8.h),
                  Text(
                    'We may suspend or terminate your account if you violate these Terms. You may also delete your account at any time as described in the Account Deletion section above.',
                    style: TextStyle(color: Colors.black54, fontSize: 16.sp),
                  ),
                  SizedBox(height: 24.h),

                  _buildSectionTitle('Changes to These Terms'),
                  SizedBox(height: 8.h),
                  Text(
                    'We may update these Terms from time to time. Continued use of the app after changes take effect means you accept the revised Terms.',
                    style: TextStyle(color: Colors.black54, fontSize: 16.sp),
                  ),
                  SizedBox(height: 24.h),

                  _buildSectionTitle('Contact Us'),
                  SizedBox(height: 8.h),
                  RichText(
                    text: TextSpan(
                      style: TextStyle(color: Colors.black54, fontSize: 16.sp),
                      children: const [
                        TextSpan(
                          text: 'If you have questions about these Terms, contact us at ',
                        ),
                        TextSpan(
                          text: 'admin@biglickenterprises.com',
                          style: TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        TextSpan(text: '.'),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Scales horizontal padding by breakpoint so content doesn't hug the
  /// edges on tablets/desktop, while staying compact on phones.
  double _responsiveHorizontalPadding(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth >= 1024) {
      return (screenWidth - _kMaxContentWidth) / 2;
    } else if (screenWidth >= 600) {
      return 32.w;
    }
    return 16.w;
  }

  Widget _buildSectionTitle(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 20.sp,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.black54),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 16.sp, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}