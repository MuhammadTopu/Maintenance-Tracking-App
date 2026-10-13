import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/input_validator.dart';
import '../../../../shared/app_toast.dart';
import '../../../../shared/common_widgets.dart';
import '../../../../shared/custom_text_field.dart';
import '../../../view_models/forget_pass_provider.dart';

class ForgetPasswordScreen extends StatefulWidget {
  const ForgetPasswordScreen({super.key});

  @override
  State<ForgetPasswordScreen> createState() => _ForgetPasswordScreenState();
}

class _ForgetPasswordScreenState extends State<ForgetPasswordScreen> {

  final TextEditingController emailController = TextEditingController();
  final FocusNode focusNode = FocusNode();

  @override
  void dispose() {
    emailController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffFFFFFF),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 40.h),
              Row(
                children: [
                  SizedBox(
                    height: 60.h,
                    width: 60.w,
                    child: Image.asset("assets/icons/app_logo.png"),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    "Maintenance\nGenie",
                    style: TextStyle(
                      color: Color(0xff023455),
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Spacer(),
                ],
              ),
              SizedBox(height: 18.h),
              Text(
                "Enter your email address to reset your password.",
                style: TextStyle(
                  color: Color(0xff1D1F2C),
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 20.h),
              Text(
                "Email",
                style: TextStyle(
                  color: Color(0xff1D1F2C),
                  fontWeight: FontWeight.w400,
                  fontSize: 14.sp,
                ),
              ),
              SizedBox(height: 8.h),
              CustomTextField(
                controller: emailController,
                hintText: "Enter your email",
                keyboardType: TextInputType.emailAddress,
                inputFormatters: [
                  FilteringTextInputFormatter.deny(RegExp(r'\s')),
                ], // Disallow spaces
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an email address';
                  }
                  return null;
                },
                focusNode: focusNode,
              ),
              SizedBox(height: 40.h),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                child: Consumer<ForgetPassProvider>(
                  builder: (context, provider, child) {
                    return Visibility(
                      visible: !provider.isLoading,
                      replacement: const Center(
                        child: CircularProgressIndicator(color: AppColors.primaryColor,),
                      ),
                      child: PrimaryButton(
                        text: "Verify",
                        onPressed: () async {
                          final email = emailController.text.trim();
                          if (email.isEmpty) {
                            AppToast.showToast('Please enter your email', gravity: ToastGravity.TOP);
                            return;
                          }

                          if (InputValidators.emailValidator(email) == false) {
                            AppToast.showToast(
                              'Please enter a valid email',
                              gravity: ToastGravity.TOP,
                            );
                            return;
                          }
                          final result = await provider.forgetPass(email: email);

                          if (!mounted) return;

                          if (result) {
                            Navigator.pushReplacementNamed(context, RouteName.resetPasswordOtp);
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 12.h),
            ],
          ),
        ),
      ),
    );
  }
}
