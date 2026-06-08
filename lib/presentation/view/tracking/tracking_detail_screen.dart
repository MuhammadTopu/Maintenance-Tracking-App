import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/api_end_points.dart';
import '../../../data/models/task_list_response_model.dart';
import '../../../shared/custom_item_app_bar.dart';
import '../../view_models/add_receipt_provider.dart';
import '../../view_models/item_task_list_by_item_id_provider.dart';
import 'widget/drop_down_widget.dart';

class TrackingDetailScreen extends StatefulWidget {
  const TrackingDetailScreen({super.key});

  @override
  State<TrackingDetailScreen> createState() => _TrackingDetailScreenState();
}

class _TrackingDetailScreenState extends State<TrackingDetailScreen> {
  Future<void> _launchURL(String mapUrl) async {
    if (await canLaunch(mapUrl)) {
      await launch(mapUrl);
    } else {
      throw 'Could not launch $mapUrl';
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<ItemTaskListByItemIdProvider>();
    final task = taskProvider.taskListResponse?.tasks.where(
      (t) => t.taskId == taskProvider.taskId,
    );
    final addReceiptProvider = context.watch<AddReceiptProvider>();
    return Scaffold(
      backgroundColor: const Color(0xffFFFFFF),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20.h),
                CustomItemAppBar(
                  title: 'Item Details',
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                SizedBox(height: 21.h),
                const Divider(thickness: 1, color: Color(0xffE9E9EA)),
                SizedBox(height: 20.h),
                Text(
                  task?.toList().first.upcomingTask ?? '',
                  style: TextStyle(
                    color: const Color(0xff1D1F2C),
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    const Icon(Icons.add_home_outlined, color: Colors.grey),
                    SizedBox(width: 8.w),
                    const Text(
                      "Item :",
                      style: TextStyle(
                        color: Color(0xff4A4C56),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      task?.toList().first.itemName ?? '',
                      style: TextStyle(
                        color: Color(0xff4A4C56),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 21.h),
                Row(
                  children: [
                    const Icon(Icons.check_box_outlined, color: Colors.grey),
                    SizedBox(width: 8.w),
                    const Text(
                      "Status :",
                      style: TextStyle(
                        color: Color(0xff4A4C56),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const Spacer(),
                    DropDownWidget(status: task?.toList().first.status ?? '',)
                  ],
                ),
                SizedBox(height: 21.h),
                Row(
                  children: [
                    const Icon(Icons.calendar_month, color: Colors.grey),
                    SizedBox(width: 8.w),
                    const Text("Last date :"),
                    const Spacer(),
                    Text(
                      DateFormat('dd/MM/yyyy, hh:mm a').format(
                        DateTime.parse(task?.toList().first.lastDate ?? ''),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: "Description: ",
                        style: TextStyle(
                          color: const Color(0xff1D1F2C),
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextSpan(
                        text: task?.toList().first.description ?? '',
                        style: TextStyle(
                          color: const Color(0xff1D1F2C),
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12.h),
                SizedBox(
                  height: 200.h,
                  child: DottedBorder(
                    color: Colors.grey,
                    strokeWidth: 1,
                    dashPattern: const [6, 5],
                    child: Container(
                      padding: EdgeInsets.all(20.w),
                      width: MediaQuery.of(context).size.width * 0.9,
                      height: 250.h,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (addReceiptProvider.getImageFile != null)
                            Expanded(
                              child: Image.file(
                                addReceiptProvider.getImageFile!,
                                width: 100.w,
                                height: 100.h,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  debugPrint('Image.file error: $error');
                                  return const Icon(
                                    Icons.error,
                                    color: Colors.red,
                                    size: 50,
                                  );
                                },
                              ),
                            )
                          else
                            const Icon(
                              Icons.image,
                              color: Colors.grey,
                              size: 50,
                            ),
                          SizedBox(height: 10.h),
                          const Text(
                            '(File Supported .png .jpg .webp)',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          SizedBox(height: 20.h),
                          Consumer<AddReceiptProvider>(
                            builder: (_, pr, __) {
                              return Visibility(
                                visible: !pr.isLoading,
                                replacement: Center(child: CircularProgressIndicator(),),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    InkWell(
                                      onTap: () async {
                                        final hasPermission =
                                            await Permission.camera
                                                .request()
                                                .isGranted;
                                        if (hasPermission) {
                                          final bool isImageSelected = await pr.pickImage(
                                            ImageSource.camera,
                                            task?.toList().first.taskId ?? '',
                                          );
                                          if (isImageSelected) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  pr.message,
                                                ),
                                              ),
                                            );
                                          } else {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text('No image selected'),
                                              ),
                                            );
                                          }
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Camera permission denied',
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                      borderRadius: BorderRadius.circular(99.r),
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 15.w,
                                          vertical: 7.h,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(99.r),
                                          border: Border.all(
                                            color: const Color(0xffE9E9EA),
                                          ),
                                        ),
                                        child: const Text('Take Picture'),
                                      ),
                                    ),
                                    SizedBox(width: 9.w),
                                    InkWell(
                                      onTap: () async {
                                        // final hasPermission = await _requestGalleryPermission();
                                        // if (!hasPermission) {
                                        //   ScaffoldMessenger.of(context).showSnackBar(
                                        //     const SnackBar(
                                        //       content: Text(
                                        //         'Gallery access denied. Please allow permission in settings.',
                                        //       ),
                                        //     ),
                                        //   );
                                        //   debugPrint('Gallery permission denied.');
                                        //   return;
                                        // }
                                        final bool isImageSelected = await pr.pickImage(
                                          ImageSource.gallery,
                                          task?.toList().first.taskId ?? '',
                                        );
                                        if (isImageSelected) {
                                          debugPrint(
                                            'Image displayed in UI: ${pr.getImageFile!.path}',
                                          );
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                pr.message,
                                              ),
                                            ),
                                          );
                                        } else {
                                          debugPrint('No image selected in UI.');
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('No image selected'),
                                            ),
                                          );
                                        }
                                      },
                                      borderRadius: BorderRadius.circular(99.r),
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 15.w,
                                          vertical: 7.h,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(99.r),
                                          border: Border.all(
                                            color: const Color(0xffE9E9EA),
                                          ),
                                        ),
                                        child: const Text('Upload Receipt'),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child: Container(
                    height: 250.h,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child:
                    task?.toList().first.receiptUrl != null
                        ? Image.network(
                      ApiEndPoints.imagePath(task?.toList().first.receiptUrl ?? ''),
                      width: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                                : null,
                            color: const Color(0xFF6359FF),
                          ),
                        );
                      },
                      errorBuilder:
                          (context, error, stackTrace) => Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(Icons.image_outlined, size: 30.h,),
                              SizedBox(height: 12.h,),
                              Text('No Receipt Available!')
                            ],
                          ),
                    )
                        : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(Icons.image_outlined, size: 30.h,),
                            SizedBox(height: 12.h,),
                            Text('No Receipt Available!')
                          ],
                        ),
                  ),
                ),
                SizedBox(height: 12.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: const Color(0xffF0FAF9),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Maintenance History",
                        style: TextStyle(
                          color: const Color(0xff1D1F2C),
                          fontWeight: FontWeight.w600,
                          fontSize: 20.sp,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      if (task?.toList().first.maintenanceHistory.isNotEmpty ??
                          false)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: List.generate(
                            task?.toList().first.maintenanceHistory.length ?? 0,
                            (index) {
                              final historyItem =
                                  task
                                      ?.toList()
                                      .first
                                      .maintenanceHistory[index];
                              return Padding(
                                padding: EdgeInsets.symmetric(vertical: 8.h),
                                child: Text(
                                  historyItem ?? '', // Maintenance task title
                                  style: TextStyle(
                                    color: const Color(0xff4A4C56),
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              );
                            },
                          ),
                        )
                      else
                        const Text(
                          'No Maintenance History available',
                          style: TextStyle(
                            color: Color(0xff4A4C56),
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                    ],
                  ),
                ),

                SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: const Color(0xffF0FAF9),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Shop Suggestion(Nearby)",
                        style: TextStyle(
                          color: const Color(0xff1D1F2C),
                          fontWeight: FontWeight.w600,
                          fontSize: 20.sp,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Column(
                        spacing: 24.h,
                        children: List.generate(
                          task?.toList().first.shopSuggestions.length ?? 0,
                          (index) {
                            return _buildShopSuggestionCard(
                              context,
                              task!.toList().first.shopSuggestions[index],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20.h,)
              ],
            ),
          ),
        ),
      ),
    );
  }

  Column _buildShopSuggestionCard(
    BuildContext context,
    SuggestionResponse shopSuggestions,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text("Name :"),
            const Spacer(),
            Text(shopSuggestions.name),
          ],
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            const Text("Rating:"),
            const Spacer(),
            Row(
              children: [
                Image.asset("assets/icons/star.png", height: 13.h),
                SizedBox(width: 4.w),
                Text(
                  "${shopSuggestions.rating} from ${shopSuggestions.totalReviews} user",
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            const Text("Contact:"),
            const Spacer(),
            Text(shopSuggestions.contact),
          ],
        ),
        SizedBox(height: 12.h),
        GestureDetector(
          onTap: () {
            _launchURL(shopSuggestions.googleMapUrl);
          },
          child: Container(
            width: MediaQuery.of(context).size.width * 0.5,
            padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: 10.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Color(0xffE9E9EA)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("See on Google map"),
                SizedBox(width: 7.w),
                Icon(Icons.location_pin, size: 17, color: Color(0xff589DC4)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
