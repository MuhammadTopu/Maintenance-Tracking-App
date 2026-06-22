import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/app_toast.dart';
import '../../../../shared/common_widgets.dart';
import '../../../../shared/custom_text_field.dart';
import '../../../view_models/forget_pass_provider.dart';
import '../widgets/password_requirements.dart';

class SetPasswordScreen extends StatefulWidget {
  const SetPasswordScreen({super.key});
  @override
  _SignUpInfoScreenState createState() => _SignUpInfoScreenState();
}

class _SignUpInfoScreenState extends State<SetPasswordScreen> {
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  @override
  void dispose() {
    super.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffFFFFFF),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 40),
              Row(
                children: [
                  SizedBox(
                    height: 60.h,
                    width: 60.w,
                    child: Image.asset("assets/icons/app_logo.png"),
                  ),
                  SizedBox(width: 8),
                  Text(
                    "Maintenance\nGenie",
                    style: TextStyle(
                      color: Color(0xff023455),
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Spacer(),
                ],
              ),
              SizedBox(height: 18),
              Text(
                "Set Your Password",
                style: TextStyle(
                  color: Color(0xff1D1F2C),
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                "Enter your email and password to log in\nto your account",
                style: TextStyle(
                  color: Color(0xff1D1F2C),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
              SizedBox(height: 20),
              Text(
                "New Password",
                style: TextStyle(
                  color: Color(0xff1D1F2C),
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 8),
              CustomTextField(
                controller: passwordController,
                hintText: "Enter your password",
                onChanged: (value) {
                  context.read<ForgetPassProvider>().validatePassword(value);
                },
              ),
              SizedBox(height: 16),
              Text(
                "Confirm Password",
                style: TextStyle(
                  color: Color(0xff1D1F2C),
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 8),
              CustomTextField(
                controller: confirmPasswordController,
                hintText: "Confirm your password",
              ),
              SizedBox(height: 20),
              Consumer<ForgetPassProvider>(
                builder: (_, provider, _) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PasswordRequirement(
                        text: "A minimum of 8 characters",
                        isValid: provider.hasMinLength,
                      ),
                      SizedBox(height: 8),

                      PasswordRequirement(
                        text: "Lower and uppercase case letters",
                        isValid: provider.hasUpperAndLower,
                      ),
                      SizedBox(height: 8),

                      PasswordRequirement(
                        text: "At least 1 number",
                        isValid: provider.hasNumber,
                      ),
                      SizedBox(height: 8),

                      PasswordRequirement(
                        text: "At least 1 symbol",
                        isValid: provider.hasSymbol,
                      ),
                    ],
                  );
                },
              ),
              SizedBox(height: 20),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                child: Consumer<ForgetPassProvider>(
                  builder: (_, provider, _) {
                    return Visibility(
                      visible: !provider.isLoading,
                      replacement: Center(child: CircularProgressIndicator(color: AppColors.primaryColor,)),
                      child: PrimaryButton(
                        text: "Reset Password",
                        onPressed: provider.isPasswordValid
                            ? () async {
                                final password = passwordController.text.trim();
                                final confirmPassword =
                                    confirmPasswordController.text.trim();

                                if (password.isEmpty ||
                                    confirmPassword.isEmpty) {
                                  AppToast.showToast(
                                    "All fields are required",
                                    backgroundColor: Colors.red,
                                  );
                                  return;
                                }

                                if (password != confirmPassword) {
                                  AppToast.showToast(
                                    "Passwords do not match",
                                    backgroundColor: Colors.red,
                                  );
                                  return;
                                }

                                if (!provider.isPasswordValid) {
                                  AppToast.showToast(
                                    "Password does not meet requirements",
                                    backgroundColor: Colors.red,
                                  );
                                  return;
                                }

                                final result = await provider.resetPass(
                                  password: password,
                                );
                                if (result) {
                                  Navigator.pushNamed(context, RouteName.login);
                                }
                              }
                            : null,
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 20),
              Text(
                "We use strictly necessary cookies to enable essential functions, such as security and authentication. For more information, see our Cookie_Policy and Privacy_Policy. This site is protected by re-CAPTCHA and the Google Privacy Policy and Terms of Service apply.",
              ),
            ],
          ),
        ),
      ),
    );
  }
}
