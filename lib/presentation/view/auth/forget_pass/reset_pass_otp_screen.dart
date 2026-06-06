
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../shared/app_toast.dart';
import '../../../../shared/common_widgets.dart';
import '../../../view_models/forget_pass_provider.dart';
import '../widgets/pin_code_text_field.dart';

class ResetPassOtpScreen extends StatefulWidget {
  const ResetPassOtpScreen({super.key});

  @override
  State<ResetPassOtpScreen> createState() => _ResetPassOtpScreenState();
}

class _ResetPassOtpScreenState extends State<ResetPassOtpScreen> {
  final TextEditingController _otpController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final email = context.watch<ForgetPassProvider>().email;
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
                "Enter OTP Code",
                style: TextStyle(
                  color: Color(0xff1D1F2C),
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              // Show the email that was passed
              Text(
                "Verify your email $email. This helps us keep your account secure by verifying that it's really you.",
                style: TextStyle(
                  color: Color(0xff4A4C56),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
              SizedBox(height: 20),
              PincodeTextField(controller: _otpController),
              SizedBox(height: 20),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                child: Consumer<ForgetPassProvider>(
                  builder: (context, provider, child) {
                    return Visibility(
                      visible: !provider.isLoading,
                      replacement: const Center(
                        child: CircularProgressIndicator(),
                      ),
                      child: PrimaryButton(
                        text: "Verify",
                        onPressed: () async {
                          final otp = _otpController.text;
                          if (otp.isEmpty) {
                            AppToast.showToast(
                              "OTP is required",
                              backgroundColor: Colors.red,
                            );
                            return;
                          }
                          final result = await provider.verifyResetPassOtp(
                            otp: otp,
                          );
                          if (result == false) {
                            Navigator.pushNamed(context, RouteName.resetPassword);
                          }
                        },
                      ),
                    );
                  },
                ),
              ),

              SizedBox(height: 32),
              Align(
                alignment: Alignment.center,
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    "Go back",
                    style: TextStyle(
                      color: Color(0xff1D1F2C),
                      fontWeight: FontWeight.w400,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


