import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class PincodeTextField extends StatelessWidget {
  final TextEditingController? controller;

  const PincodeTextField({super.key, this.controller});

  @override
  Widget build(BuildContext context) {
    const borderColor = Color(0xffE9E9EA);

    return Center(
      child: SizedBox(
        width: 260.w,
        child: PinCodeTextField(
          appContext: context,
          keyboardType: TextInputType.number,
          length: 4,
          controller: controller,
          obscureText: false,
          animationDuration: const Duration(milliseconds: 200),
          backgroundColor: Colors.transparent,
          enableActiveFill: true,
          onChanged: (value) {
            debugPrint("Pincode: $value");
          }, // You can handle changes if needed

          pinTheme: PinTheme(
            shape: PinCodeFieldShape.box,
            borderRadius: BorderRadius.circular(8.r),
            fieldHeight: 48.h,
            fieldWidth: 54.w,
            activeBorderWidth: 1,
            selectedBorderWidth: 1.4,
            inactiveBorderWidth: 1,
            activeColor: Colors.grey,
            inactiveColor: borderColor,
            selectedColor: Colors.grey,
            activeFillColor: Colors.white,
            selectedFillColor: Colors.white,
            inactiveFillColor: Colors.white,
          ),

          textStyle: TextStyle(
            color: Colors.black,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
