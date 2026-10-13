import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:maintenance_genie/core/constants/app_colors.dart';
import 'package:maintenance_genie/shared/app_toast.dart';

import '../core/helper/image_picker_helper.dart';

class AssetImageController extends ValueNotifier<File?> {
  AssetImageController() : super(null);
  void clear() => value = null;
}

class AssetImagePicker extends StatefulWidget {
  const AssetImagePicker({
    super.key,
    required this.title,
    required this.controller,
  });

  final String title;
  final AssetImageController controller;

  @override
  State<AssetImagePicker> createState() => _AssetImagePickerState();
}

class _AssetImagePickerState extends State<AssetImagePicker> {
  bool _busy = false;

  Future<void> _pick(ImageSource source) async {
    if (_busy) return;
    setState(() => _busy = true);
    final file = await ImageHelper.pick(context, source);
    if (!mounted) return;
    setState(() => _busy = false);
    if (file != null) {
      widget.controller.value = file;
      AppToast.showToast('Image selected');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.title),
        SizedBox(height: 4.h),
        SizedBox(
          height: 260.h,
          width: double.infinity,
          child: DottedBorder(
            color: const Color(0xff9e9e9e),
            strokeWidth: 1,
            dashPattern: const [5, 6],
            borderType: BorderType.RRect,
            radius: Radius.circular(10.r),
            padding: EdgeInsets.all(6.w),
            child: _busy
                ? Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryColor,
              ),
            )
                : ValueListenableBuilder<File?>(
              valueListenable: widget.controller,
              builder: (_, file, __) =>
              file == null ? _picker() : _preview(file),
            ),
          ),
        ),
      ],
    );
  }

  Widget _picker() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.image_outlined, size: 36.sp, color: Colors.grey),
          SizedBox(height: 8.h),
          Text(
            '(File Supported .png .jpg .webp within 5MB)',
            style: TextStyle(fontSize: 12.sp, color: const Color(0xff808080)),
          ),
          SizedBox(height: 14.h),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10.w,
            runSpacing: 10.h,
            children: [
              _pill('Take Picture', () => _pick(ImageSource.camera)),
              _pill('Upload Picture', () => _pick(ImageSource.gallery)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(99.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 7.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(99.r),
          border: Border.all(color: const Color(0xffE8E8EB)),
        ),
        child: Text(label, style: TextStyle(fontSize: 13.sp)),
      ),
    );
  }

  Widget _preview(File file) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8.r),
          child: Image.file(
            file,
            key: ValueKey(file.path),
            fit: BoxFit.cover,
            cacheWidth: 800,
            errorBuilder: (_, __, ___) => const Center(
              child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
            ),
          ),
        ),
        Positioned(
          top: 6.h,
          right: 6.w,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.controller.clear,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Icon(Icons.cancel, size: 28.sp, color: Colors.black87),
            ),
          ),
        ),
      ],
    );
  }
}