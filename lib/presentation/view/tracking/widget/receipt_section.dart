import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:maintenance_genie/core/constants/api_end_points.dart';
import 'package:maintenance_genie/core/constants/app_colors.dart';
import 'package:maintenance_genie/data/models/task_list_response_model.dart';
import 'package:maintenance_genie/presentation/view_models/add_receipt_provider.dart';
import 'package:maintenance_genie/shared/app_toast.dart';
import 'package:provider/provider.dart';

import '../../../../core/helper/image_picker_helper.dart';
import '../../../../core/helper/task_actions.dart';
import 'full_screen_image_view.dart';

class ReceiptSection extends StatelessWidget {
  const ReceiptSection({super.key, required this.task});

  final TaskResponse task;

  @override
  Widget build(BuildContext context) {
    if (task.hasReceipt) {
      return _ReceiptPreview(receiptPath: task.receiptUrl!);
    }
    return _ReceiptUploadBox(task: task);
  }
}

// -----------------------------------------------------------------------------
// Upload
// -----------------------------------------------------------------------------

class _ReceiptUploadBox extends StatefulWidget {
  const _ReceiptUploadBox({required this.task});

  final TaskResponse task;

  @override
  State<_ReceiptUploadBox> createState() => _ReceiptUploadBoxState();
}

class _ReceiptUploadBoxState extends State<_ReceiptUploadBox> {
  bool _refreshing = false;

  Future<void> _pickAndUpload(ImageSource source) async {
    final receipts = context.read<AddReceiptProvider>();
    if (receipts.isLoading || _refreshing) return;

    final file = await ImageHelper.pick(context, source);
    if (file == null || !mounted) return;

    final uploaded = await receipts.uploadReceipt(
      taskId: widget.task.id,
      file: file,
    );
    AppToast.showToast(receipts.message);
    if (!uploaded || !mounted) return;

    setState(() => _refreshing = true);
    try {
      await refreshSelectedTask(context);
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AddReceiptProvider>(
      builder: (context, receipts, _) {
        final busy = receipts.isLoading || _refreshing;

        return DottedBorder(
          color: Colors.grey,
          strokeWidth: 1,
          dashPattern: const [6, 5],
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(20.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (receipts.pendingFile != null)
                  SizedBox(
                    height: 120.h,
                    child: Image.file(
                      receipts.pendingFile!,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) =>
                          const Icon(Icons.error, color: Colors.red, size: 50),
                    ),
                  )
                else
                  const Icon(Icons.image, color: Colors.grey, size: 50),
                SizedBox(height: 10.h),
                const Text(
                  '(File Supported .png .jpg .webp)',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                SizedBox(height: 20.h),
                if (busy)
                  Column(
                    children: [
                      const CircularProgressIndicator(
                        color: AppColors.primaryColor,
                      ),
                      SizedBox(height: 10.h),
                      Text(
                        _refreshing ? 'Updating task…' : 'Uploading receipt…',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _PillButton(
                        label: 'Take Picture',
                        onTap: () => _pickAndUpload(ImageSource.camera),
                      ),
                      SizedBox(width: 9.w),
                      _PillButton(
                        label: 'Upload Receipt',
                        onTap: () => _pickAndUpload(ImageSource.gallery),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(99.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 7.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(99.r),
          border: Border.all(color: const Color(0xffE9E9EA)),
        ),
        child: Text(label),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Preview
// -----------------------------------------------------------------------------

class _ReceiptPreview extends StatelessWidget {
  const _ReceiptPreview({required this.receiptPath});

  final String receiptPath;

  @override
  Widget build(BuildContext context) {
    final url = ApiEndPoints.imagePath(receiptPath);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => FullScreenImageView(imageUrl: url),
        ),
      ),
      child: Container(
        height: 250.h,
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12.r)),
        foregroundDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.grey.shade400),
        ),
        child: Hero(
          tag: url,
          child: Image.network(
            url,
            width: double.infinity,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: progress.expectedTotalBytes != null
                      ? progress.cumulativeBytesLoaded /
                            progress.expectedTotalBytes!
                      : null,
                  color: AppColors.primaryColor,
                ),
              );
            },
            errorBuilder: (_, _, _) => Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.image_outlined, size: 30.h),
                SizedBox(height: 12.h),
                const Text('Receipt could not be loaded'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
