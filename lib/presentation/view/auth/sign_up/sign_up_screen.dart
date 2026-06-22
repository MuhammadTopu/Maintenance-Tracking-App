import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:maintenance_genie/presentation/view_models/sign_up_provider.dart';
import 'package:provider/provider.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/input_validator.dart';
import '../../../../shared/app_toast.dart';
import '../../../../shared/common_widgets.dart';
import '../../../../shared/custom_text_field.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController emailController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    super.dispose();
    emailController.dispose();
    _focusNode.dispose();
  }

  Future<void> handleSignUp(SignUpProvider provider) async {
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
    final result = await provider.register1(email: email);

    if (!mounted) return;

    if (result) {
      Navigator.pushReplacementNamed(context, RouteName.verifyEmailOtp);
    }
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
                "Create Your Account",
                style: TextStyle(
                  color: Color(0xff1D1F2C),
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 20),
              Text(
                "Email",
                style: TextStyle(
                  color: Color(0xff1D1F2C),
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 8),
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
                focusNode: _focusNode,
              ),
              SizedBox(height: 20),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                child: Consumer<SignUpProvider>(
                  builder: (_, provider, _) {
                    return Visibility(
                      visible: !provider.isLoading,
                      replacement: Center(child: CircularProgressIndicator(color: AppColors.primaryColor,)),
                      child: PrimaryButton(
                        text: "Verify",
                        onPressed: () => handleSignUp(provider),
                      ),
                    );
                  }
                ),
              ),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Consumer<SignUpProvider>(
                    builder: (_, pro, _) {
                      return Checkbox(
                        value: pro.isChecked,
                        onChanged: (value) => pro.toggleCheck(value!),
                      );
                    },
                  ),
                  Expanded(
                    child: Text(
                      "By proceeding, you accept Maintenance\nGenie Terms of Service and acknowledge reading its Privacy Policy.",
                      style: TextStyle(
                        color: Color(0xff1D1F2C),
                        fontWeight: FontWeight.w400,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
