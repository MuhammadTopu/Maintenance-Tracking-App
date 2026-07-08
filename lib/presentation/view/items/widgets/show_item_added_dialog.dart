import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../shared/common_widgets.dart';

class ItemAddedDialog extends StatelessWidget {
  final VoidCallback onDone;
  final bool isPremium;
  const ItemAddedDialog({
    super.key,
    required this.onDone,
    required this.isPremium,
  });
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24.w, horizontal: 16.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 48.sp),
              SizedBox(height: 16.h),
              Text(
                "Asset Added Successfully",
                style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16.h),
              Text(
                isPremium
                    ? "Your asset has been saved and maintenance tasks are generated successfully."
                    : "Auto-generated maintenance tasks are a Premium feature. Upgrade anytime to unlock them for this item.",
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w400, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8.h),
              const Divider(),
              SizedBox(height: 8.h),
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(text: 'Done', onPressed: onDone),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
