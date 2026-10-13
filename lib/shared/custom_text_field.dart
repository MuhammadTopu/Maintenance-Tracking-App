import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomTextField extends StatelessWidget {
  final String? title;
  final String? hintText;
  final String? labelText;
  final TextInputType keyboardType;
  final bool obscureText;
  final Icon? prefixIcon;
  final Widget? suffixIcon;
  final TextEditingController? controller;
  final void Function(String)? onChanged;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final FocusNode? focusNode;
  final VoidCallback? onSuffixIconPressed;
  final int? maxLines;
  final double? borderRadius;

  const CustomTextField({
    super.key,
    this.title,
    this.hintText,
    this.labelText,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.controller,
    this.onChanged,
    this.inputFormatters,
    this.validator,
    this.focusNode,
    this.onSuffixIconPressed,
    this.maxLines = 1,
    this.borderRadius,
  });

  static const _hintStyle = TextStyle(color: Color(0xffA5A5AB));
  static const _errorStyle = TextStyle(fontSize: 12, color: Colors.red);
  static const _borderSide = BorderSide(color: Color(0xff9e9e9e));

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderSide: _borderSide,
      borderRadius: BorderRadius.circular(borderRadius ?? 10.r),
    );

    final decoration = InputDecoration(
      hintText: hintText,
      hintStyle: _hintStyle,
      labelText: labelText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      border: border,
      enabledBorder: border,
      focusedBorder: border,
      errorStyle: _errorStyle,
    );

    final int? lines = obscureText ? 1 : maxLines;

    final Widget field = validator == null
        ? TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            onChanged: onChanged,
            inputFormatters: inputFormatters,
            focusNode: focusNode,
            maxLines: lines,
            decoration: decoration,
          )
        : TextFormField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            onChanged: onChanged,
            inputFormatters: inputFormatters,
            validator: validator,
            focusNode: focusNode,
            maxLines: lines,
            decoration: decoration,
          );

    if (title == null) return field;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title!),
        SizedBox(height: 4.h),
        field,
      ],
    );
  }
}
