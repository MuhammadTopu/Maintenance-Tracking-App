import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:maintenance_genie/shared/app_toast.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/api_end_points.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/common_widgets.dart';
import '../../../../shared/custom_item_app_bar.dart';
import '../../../view_models/user_provider.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final user = context.read<UserProvider>().userResponse?.data;

    nameController.text = user?.name ?? '';
    emailController.text = user?.email ?? '';
    addressController.text = user?.address ?? '';
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    addressController.dispose();
    super.dispose();
  }

  // ================= SNACKBAR =================
  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  // ================= INPUT DECORATION =================
  InputDecoration _decoration(String hint) {
    return InputDecoration(
      hintText: hint,
      border: _border(),
      enabledBorder: _border(),
      focusedBorder: _border(),
    );
  }

  OutlineInputBorder _border() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Colors.grey),
    );
  }

  // ================= IMAGE DIALOG =================
  Future<void> _showImagePicker(UserProvider provider) async {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: Colors.white,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Select Image",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 16.h),

              GestureDetector(
                onTap: provider.pickImage,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: const Text("Pick a Picture"),
                ),
              ),

              SizedBox(height: 16.h),

              Consumer<UserProvider>(
                builder: (_, p, __) {
                  return SizedBox(
                    width: double.infinity,
                    child: p.isLoading
                        ? const Center(child: CircularProgressIndicator(color: AppColors.primaryColor,))
                        : PrimaryButton(
                            text: 'Save Changes',
                            onPressed: () async {
                              final result = await p.updateUserImage();
                              p.image = null;

                              context.read<UserProvider>().getUserDetails();

                              _showSnack(
                                result
                                    ? "Profile picture updated"
                                    : "Profile picture update failed",
                              );

                              Navigator.pop(context);
                            },
                          ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.userResponse?.data;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CustomItemAppBar(
                  title: 'Edit Profile',
                  onTap: Navigator.of(context).pop,
                ),
              ),

              const Divider(color: Color(0xffE9E9EA), thickness: 1),

              SizedBox(height: 20.h),

              // ================= PROFILE IMAGE =================
              GestureDetector(
                onTap: () => _showImagePicker(userProvider),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(90.r),
                      child: Container(
                        height: 100.h,
                        width: 100.w,
                        decoration: BoxDecoration(shape: BoxShape.circle),
                        child: userProvider.image != null ? Image.file(userProvider.image!) :
                            Image.network(
                                ApiEndPoints.imagePath(
                                  user?.avatar ?? '',
                                ),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: 100.h,
                                    width: 100.w,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xffF6F8FA),
                                      border: Border.all(
                                        color: Color(0xffE9E9EA),
                                      ),
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

                    Positioned(
                      bottom: -6.h,
                      right: 10.w,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(5),
                        child: Image.asset("assets/icons/plus.png", scale: 3.5),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              Text(
                user?.name ?? '',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),

              Text(
                user?.email ?? '',
                style: TextStyle(color: Colors.grey.shade600),
              ),

              const SizedBox(height: 15),

              // ================= FORM =================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _label("Name"),
                    TextField(
                      controller: nameController,
                      decoration: _decoration("Enter Your Name"),
                    ),

                    _label("Email"),
                    TextField(
                      controller: emailController,
                      enabled: false,
                      style: TextStyle(color: Colors.grey.shade600),
                      decoration: _decoration("Enter Your Email"),
                    ),

                    _label("Address"),
                    TextField(
                      controller: addressController,
                      decoration: _decoration("Enter Your Address"),
                    ),

                    SizedBox(height: 30.h),

                    // ================= SAVE BUTTON =================
                    Consumer<UserProvider>(
                      builder: (_, provider, __) {
                        return SizedBox(
                          width: double.infinity,
                          child: provider.isUpdating
                              ? const Center(child: CircularProgressIndicator(color: AppColors.primaryColor,))
                              : PrimaryButton(
                                  text: "Save",
                                  onPressed: () async {
                                    final value = addressController.text;

                                    if (value.trim().isEmpty) {
                                      AppToast.showToast('Address is required');
                                      return;
                                    }

                                    if (value.trim().length < 10) {
                                      AppToast.showToast(
                                        'Address must be at least 10 characters',
                                      );
                                      return;
                                    }

                                    final result = await provider
                                        .updateProfileDetails(
                                          nameController.text,
                                          addressController.text,
                                        );

                                    AppToast.showToast(
                                      result
                                          ? "Profile updated successfully"
                                          : "Profile update failed",
                                    );

                                    if (result) {
                                      context
                                          .read<UserProvider>()
                                          .getUserDetails();
                                      Navigator.pop(context);
                                    }
                                  },
                                ),
                        );
                      },
                    ),

                    SizedBox(height: 40.h),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Text(text, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}
