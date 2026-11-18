import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class PincodeTextField extends StatelessWidget {
  final TextEditingController? controller;

  const PincodeTextField({super.key, this.controller});

  @override
  Widget build(BuildContext context) {
    const borderColor = Color(0xffE9E9EA);
    const length = 6;
    final gap = 8.w;

    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth.isFinite ? constraints.maxWidth : 300.0;
        final fieldWidth = ((available - gap * (length - 1)) / length)
            .clamp(30.0, 56.0)
            .toDouble();
        final fieldHeight = fieldWidth * 1.1;
        final rowWidth = fieldWidth * length + gap * (length - 1);

        return Center(
          child: SizedBox(
            width: rowWidth,
            child: PinCodeTextField(
              appContext: context,
              keyboardType: TextInputType.number,
              length: length,
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
                fieldHeight: fieldHeight,
                fieldWidth: fieldWidth,
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
                fontSize: fieldWidth * 0.38,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      },
    );
  }
}
