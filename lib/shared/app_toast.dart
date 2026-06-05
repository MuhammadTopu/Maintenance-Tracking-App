import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class AppToast {
  AppToast._();

  static void showToast(
      String message, {
        Color? backgroundColor,
        ToastGravity gravity = ToastGravity.BOTTOM,
      }) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: gravity,
      backgroundColor: backgroundColor ?? Colors.black87,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }
}