import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../shared/custom_item_app_bar.dart';

/// Content will never grow wider than this, so text stays readable
/// on tablets, foldables, and desktop/web instead of stretching edge-to-edge.
const double _kMaxContentWidth = 700.0;

class PrivacyPolicy extends StatefulWidget {
  const PrivacyPolicy({super.key});

  @override
  State<PrivacyPolicy> createState() => _PrivacyPolicyState();
}

class _PrivacyPolicyState extends State<PrivacyPolicy> {
  @override
  Widget build(BuildContext context) {
    final double horizontalPadding = _responsiveHorizontalPadding(context);

    return Scaffold(
      body: SafeArea(
        child: Container(
          color: Colors.white,
          width: double.infinity,
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
                        title: 'Privacy Policy',
                        onTap: Navigator.of(context).pop,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Divider(color: const Color(0xffE9E9EA), thickness: 1.h),
                    SizedBox(height: 16.h),

                    Text(
                      'At Maintenance Genie, we value your privacy. This policy explains how we collect, use, and protect your data when you use our app.',
                      style: TextStyle(color: Colors.black54, fontSize: 16.sp),
                    ),
                    SizedBox(height: 24.h),

                    _buildSectionTitle('Information We Collect'),
                    SizedBox(height: 8.h),
                    _buildBulletPoint(
                      'Personal Info: Name, email, phone number, and address (collected when you sign up or set up your profile)',
                    ),
                    _buildBulletPoint(
                      'Asset Data: Vehicle, home, or equipment details you enter',
                    ),
                    _buildBulletPoint(
                      'Usage Data: App interactions and preferences (to improve user experience)',
                    ),
                    _buildBulletPoint(
                      'Photos: Images you capture with your camera or select from your photo library, such as your profile picture, asset photos, or maintenance receipts',
                    ),
                    _buildBulletPoint(
                      'Device or Other IDs: A device token used by push notification services to deliver reminders and alerts to you',
                    ),
                    SizedBox(height: 24.h),

                    _buildSectionTitle('How We Use Your Information'),
                    SizedBox(height: 8.h),
                    _buildBulletPoint('To send you reminders and notifications'),
                    _buildBulletPoint(
                      'To improve features and personalize your experience',
                    ),
                    _buildBulletPoint(
                      'To generate AI-powered maintenance suggestions based on your asset and usage data',
                    ),
                    _buildBulletPoint(
                      'To use your address to help our AI suggest nearby service providers, which may direct you to an external map or search link',
                    ),
                    _buildBulletPoint('For customer support and updates'),
                    _buildBulletPoint(
                      'To authenticate your account and keep it secure',
                    ),
                    SizedBox(height: 24.h),

                    _buildSectionTitle('Premium Subscriptions'),
                    SizedBox(height: 8.h),
                    Text(
                      'Certain features, such as service provider suggestions and community forum content, are available through a paid subscription. Subscription and purchase management is handled by our third-party provider, RevenueCat, together with the app store you subscribed through (Google Play or the Apple App Store). We do not store your full payment card details.',
                      style: TextStyle(color: Colors.black54, fontSize: 16.sp),
                    ),
                    SizedBox(height: 24.h),

                    _buildSectionTitle('Community Forum Content'),
                    SizedBox(height: 8.h),
                    Text(
                      'You cannot post content to a forum through this app. Instead, the app displays maintenance-related discussions sourced from third-party public forums, collected and summarized using AI technology. This content is not created by us or our users, and we do not verify its accuracy. All rights to the original content remain with their respective authors and platforms.',
                      style: TextStyle(color: Colors.black54, fontSize: 16.sp),
                    ),
                    SizedBox(height: 24.h),

                    _buildSectionTitle('Third-Party Services'),
                    SizedBox(height: 8.h),
                    _buildBulletPoint(
                      'Firebase Authentication (Google LLC) — used to create and manage your account',
                    ),
                    _buildBulletPoint(
                      'Firebase Cloud Messaging (Google LLC) — used to deliver push notifications',
                    ),
                    _buildBulletPoint(
                      'RevenueCat — used to manage subscriptions and purchases',
                    ),
                    _buildBulletPoint(
                      'Our AI service provider — used to generate maintenance suggestions and, where relevant, a link to nearby service providers based on your address',
                    ),
                    SizedBox(height: 24.h),

                    _buildSectionTitle('Data Protection'),
                    SizedBox(height: 8.h),
                    Text(
                      'We store your data securely and do not sell it to third parties. All sensitive data is encrypted and access-controlled.',
                      style: TextStyle(color: Colors.black54, fontSize: 16.sp),
                    ),
                    SizedBox(height: 24.h),

                    _buildSectionTitle('Data Retention'),
                    SizedBox(height: 8.h),
                    Text(
                      'We retain your data for as long as your account is active, unless you request deletion as described below.',
                      style: TextStyle(color: Colors.black54, fontSize: 16.sp),
                    ),
                    SizedBox(height: 24.h),

                    _buildSectionTitle('Account Deletion'),
                    SizedBox(height: 8.h),
                    _buildBulletPoint(
                      'You can delete your account and associated data at any time from within the app',
                    ),
                    _buildBulletPoint(
                      'Deletion takes up to 30 days to complete; logging in during this period cancels the deletion request and restores your account',
                    ),
                    _buildBulletPoint(
                      'After 30 days, your account and associated data are permanently deleted',
                    ),
                    _buildBulletPoint(
                      'Your profile, personal info, asset data, photos, and usage data are permanently deleted; limited data may be retained where required by law',
                    ),
                    SizedBox(height: 24.h),

                    _buildSectionTitle('Your Rights'),
                    SizedBox(height: 8.h),
                    Text(
                      'You may request access to, correction of, or deletion of your personal data at any time by contacting us below.',
                      style: TextStyle(color: Colors.black54, fontSize: 16.sp),
                    ),
                    SizedBox(height: 24.h),

                    _buildSectionTitle('Children\'s Privacy'),
                    SizedBox(height: 8.h),
                    Text(
                      'Maintenance Genie is not directed at children under 13, and we do not knowingly collect personal information from children.',
                      style: TextStyle(color: Colors.black54, fontSize: 16.sp),
                    ),
                    SizedBox(height: 24.h),

                    _buildSectionTitle('Changes to This Policy'),
                    SizedBox(height: 8.h),
                    Text(
                      'We may update this Privacy Policy from time to time. Continued use of the app after changes take effect means you accept the revised policy.',
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
                            text: 'If you have questions about this policy, contact us at ',
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
                    SizedBox(height: 24.h),
                  ],
                ),
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
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }
}