import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:maintenance_genie/presentation/view_models/user_provider.dart';
import 'package:provider/provider.dart';

import '../../../app/routes/route_names.dart';
import '../../../core/constants/api_end_points.dart';
import '../../../shared/custom_app_bar.dart';
import '../../view_models/all_item_list_provider.dart';
import '../../view_models/login_provider.dart';

class ProfileMenu extends StatefulWidget {
  const ProfileMenu({super.key});

  @override
  State<ProfileMenu> createState() => _ProfileMenuState();
}

class _ProfileMenuState extends State<ProfileMenu> {
  @override
  Widget build(BuildContext context) {
    final getMeProvider = context.watch<UserProvider>();
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: SingleChildScrollView(
            child: Column(
              children: [
                CustomAppBar(), // Assuming this is a custom widget
                SizedBox(height: 20),
                ClipRRect(
                  borderRadius: BorderRadius.circular(90.r),
                  child: Container(
                    height: 100.h,
                    width: 100.w,
                    decoration: BoxDecoration(shape: BoxShape.circle),
                    child: Image.network(
                      ApiEndPoints.imagePath(
                        getMeProvider.userResponse?.data.avatar ?? '',
                      ),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 100.h,
                          width: 100.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xffF6F8FA),
                            border: Border.all(color: Color(0xffE9E9EA)),
                          ),
                          child: Image.asset(
                            'assets/icons/user.png',
                            height: 60.w,
                            width: 60.w,
                            color: Colors.grey.shade800,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                FutureBuilder<String?>(
                  future: getMeProvider.getUserName(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return CircularProgressIndicator();
                    } else if (snapshot.hasError) {
                      return Text(
                        'Error loading username',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      );
                    } else {
                      return Text(
                        snapshot.data ?? 'Unknown',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      );
                    }
                  },
                ),
                // FutureBuilder for Email
                FutureBuilder<String?>(
                  future: getMeProvider.getUserEmail(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return CircularProgressIndicator();
                    } else if (snapshot.hasError) {
                      return Text(
                        'Error loading email',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    } else {
                      return Text(
                        snapshot.data ?? 'Unknown',
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  height: 40,
                  color: Color(0xffEEF5F9),
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: const Text(
                    'General Settings',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                Column(
                  children: [
                    ListTile(
                      leading: Image.asset("assets/icons/edit.png", scale: 2.5),
                      title: Text('Edit Profile'),
                      trailing: Image.asset(
                        "assets/icons/arrow_right.png",
                        scale: 1.9,
                      ),
                      onTap: () {
                        Navigator.pushNamed(context, RouteName.editProfile);
                      },
                    ),
                    ListTile(
                      leading: Image.asset(
                        "assets/icons/security.png",
                        scale: 2.5,
                      ),
                      title: Text('Security'),
                      trailing: Image.asset(
                        "assets/icons/arrow_right.png",
                        scale: 1.9,
                      ),
                      onTap: () {
                        Navigator.pushNamed(context, RouteName.security);
                      },
                    ),
                  ],
                ),
                Container(
                  width: double.infinity,
                  height: 40,
                  color: Color(0xffEEF5F9),
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: const Text(
                    'Subscriptions',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                ListTile(
                  leading: Image.asset(
                    "assets/icons/subscription.png",
                    scale: 2.5,
                  ),
                  title: Text('Subscription'),
                  trailing: Image.asset(
                    "assets/icons/arrow_right.png",
                    scale: 1.9,
                  ),
                  onTap: () {
                    Navigator.pushNamed(context, RouteName.subscription);
                  },
                ),
                Container(
                  width: double.infinity,
                  height: 40,
                  color: Color(0xffEEF5F9),
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: const Text(
                    'Support and About',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                Column(
                  children: [
                    ListTile(
                      leading: Image.asset(
                        "assets/icons/about.png",
                        scale: 2.5,
                      ),
                      title: Text('About'),
                      trailing: Image.asset(
                        "assets/icons/arrow_right.png",
                        scale: 1.9,
                      ),
                      onTap: () {
                        Navigator.pushNamed(context, RouteName.about);
                      },
                    ),
                    ListTile(
                      leading: Image.asset(
                        "assets/icons/privacy_policy.png",
                        scale: 2.5,
                      ),
                      title: Text('Privacy Policy'),
                      trailing: Image.asset(
                        "assets/icons/arrow_right.png",
                        scale: 1.9,
                      ),
                      onTap: () {
                        Navigator.pushNamed(context, RouteName.privacyPolicy);
                      },
                    ),
                    ListTile(
                      leading: Image.asset(
                        "assets/icons/terms_and_condition.png",
                        scale: 2.5,
                      ),
                      title: Text('Terms and Conditions'),
                      trailing: Image.asset(
                        "assets/icons/arrow_right.png",
                        scale: 1.9,
                      ),
                      onTap: () {
                        Navigator.pushNamed(context, RouteName.terms);
                      },
                    ),
                    ListTile(
                      leading: Image.asset(
                        "assets/icons/support.png",
                        scale: 2.5,
                      ),
                      title: Text('Support'),
                      trailing: Image.asset(
                        "assets/icons/arrow_right.png",
                        scale: 1.9,
                      ),
                      onTap: () {
                        Navigator.pushNamed(context, RouteName.support);
                      },
                    ),
                    SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      height: 40,
                      color: Color(0xffEEF5F9),
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: const Text(
                        'Login/Logout',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    ListTile(
                      leading: Image.asset(
                        "assets/icons/logout.png",
                        scale: 2.5,
                      ),
                      title: Text('Logout'),
                      trailing: Image.asset(
                        "assets/icons/arrow_right.png",
                        scale: 1.9,
                      ),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return Dialog(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Transform.rotate(
                                      angle: 90 * 3.1415926535 / 180,
                                      child: const Icon(
                                        Icons.login_sharp,
                                        size: 40,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Are You Sure',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Do you want to logout?',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.black54,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),

                                    SizedBox(height: 20),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: [
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.grey.shade200,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(30),
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 12,
                                                  ),
                                            ),
                                            child: const Text(
                                              'Cancel',
                                              style: TextStyle(
                                                color: Colors.black54,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Consumer<LoginProvider>(
                                            builder: (context, provider, child) {
                                              return ElevatedButton(
                                                onPressed: () {
                                                  provider.logOut();
                                                  context
                                                      .read<
                                                        AllItemListProvider
                                                      >()
                                                      .removeItems();
                                                  Navigator.pushNamedAndRemoveUntil(
                                                    context,
                                                    RouteName.login,
                                                    (pre) => false,
                                                  );
                                                },

                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Colors.blueAccent,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          30,
                                                        ),
                                                  ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 12,
                                                      ),
                                                ),
                                                child: const Text(
                                                  'Log Out',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                    SizedBox(height: 30),
                  ],
                ),
                SizedBox(height: 70.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
