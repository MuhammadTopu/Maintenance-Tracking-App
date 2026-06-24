import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:maintenance_genie/shared/app_toast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/routes/route_names.dart';
import '../../../shared/common_widgets.dart';
import '../../../shared/custom_item_app_bar.dart';
import '../../view_models/add_item_provider.dart';
import 'widgets/custom_date_picker_field.dart';
import 'widgets/custom_drop_down_field.dart';

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final List<String> categoryList = ['Select', 'Vehicle', 'Home', 'Custom'];

  final List<String> brandList = [
    "Acura",
    "Alfa Romeo",
    "Aston Martin",
    "Audi",
    "BMW",
    "Bentley",
    "Bugatti",
    "Buick",
    "Cadillac",
    "Chevrolet",
    "Chrysler",
    "Dodge",
    "Ferrari",
    "Fiat",
    "Ford",
    "Genesis",
    "Honda",
    "Hyundai",
    "Infiniti",
    "Jaguar",
    "Jeep",
    "Kia",
    "Lamborghini",
    "Land Rover",
    "Lexus",
    "Lincoln",
    "Mazda",
    "McLaren",
    "Mercedes Benz",
    "Mini",
    "Mitsubishi",
    "Nissan",
    "Opel",
    "Peugeot",
    "Porsche",
    "Ram",
    "Renault",
    "Rolls Royce",
    "Saab",
    "Subaru",
    "Tesla",
    "Toyota",
    "Volkswagen",
    "Volvo",
  ];

  Future<bool> _requestCameraPermission(BuildContext context) async {
    final status = await Permission.camera.status;

    if (status.isGranted) return true;

    final result = await Permission.camera.request();

    if (result.isGranted) return true;

    if (result.isPermanentlyDenied) {
      await openAppSettings();
    }

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(const SnackBar(content: Text("Camera permission denied")));

    return false;
  }

  void _showSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  final TextEditingController nameController = TextEditingController();
  final TextEditingController brandController = TextEditingController();
  final TextEditingController modelController = TextEditingController();
  final TextEditingController yearController = TextEditingController();
  final TextEditingController mileageController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    brandController.dispose();
    modelController.dispose();
    yearController.dispose();
    mileageController.dispose();
    super.dispose();
  }

  void clear() {
    nameController.clear();
    brandController.clear();
    modelController.clear();
    yearController.clear();
    mileageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AddItemProvider>();

    return Scaffold(
      backgroundColor: const Color(0xffFFFFFF),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: [
                CustomItemAppBar(
                  title: 'Add Item',
                  onTap: () => Navigator.pop(context),
                ),

                SizedBox(height: 20.h),

                /// CATEGORY + NAME
                Row(
                  children: [
                    Expanded(
                      child: CustomPopupDropdown(
                        title: 'Category',
                        hint: 'Select',
                        value: context
                            .watch<AddItemProvider>()
                            .selectedCategory,
                        items: categoryList,
                        onChanged: provider.setCategory,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: _buildTextField(
                        title: 'Item Name',
                        hint: 'Name',
                        controller: nameController,
                        onChanged: provider.setName,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 20.h),

                /// BRAND + MODEL
                Consumer<AddItemProvider>(
                  builder: (_, pr, __) {
                    return Row(
                      children: [
                        Expanded(
                          child: pr.selectedCategory == 'Vehicle'
                              ? CustomPopupDropdown(
                                  title: 'Brand',
                                  hint: 'Select',
                                  value: pr.selectedBrand,
                                  items: brandList,
                                  onChanged: (value) async {
                                    provider.setBrand(value);
                                    await provider.getModels(value);
                                  },
                                )
                              : _buildTextField(
                                  title: 'Brand',
                                  hint: 'Brand',
                                  controller: brandController,
                                  onChanged: provider.setBrand,
                                ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: pr.selectedCategory == 'Vehicle'
                              ? IgnorePointer(
                                  ignoring: pr.isModelLoading,
                                  child: Opacity(
                                    opacity: pr.isModelLoading ? 0.5 : 1.0,
                                    child: CustomPopupDropdown(
                                      title: 'Model',
                                      hint: pr.isModelLoading
                                          ? 'Loading...'
                                          : 'Select',
                                      value: pr.selectedModel,
                                      items: pr.modelList,
                                      onChanged: pr.setModel,
                                    ),
                                  ),
                                )
                              : _buildTextField(
                                  title: 'Model',
                                  hint: 'Model',
                                  controller: modelController,
                                  onChanged: provider.setModel,
                                ),
                        ),
                      ],
                    );
                  },
                ),

                SizedBox(height: 20.h),

                /// YEAR
                _buildTextField(
                  title: 'Year of the model',
                  hint: 'Year',
                  controller: yearController,
                  onChanged: provider.setYearOfModel,
                ),

                SizedBox(height: 20.h),

                /// DATE + MILEAGE
                Row(
                  children: [
                    Expanded(
                      child: CustomDatePickerField(
                        context: context,
                        title: 'Purchase Date',
                        hint: 'Select',
                        selectedDate: context
                            .watch<AddItemProvider>()
                            .selectedDate,
                        onDatePicked: provider.setDate,
                      ),
                    ),
                    SizedBox(width: 10.h),
                    Expanded(
                      child: _buildTextField(
                        title: 'Total Mileage',
                        hint: 'Number',
                        controller: mileageController,
                        onChanged: provider.setTotalMileage,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 20.h),

                /// IMAGE SECTION
                Consumer<AddItemProvider>(
                  builder: (_, pr, _) {
                    return SizedBox(
                      height: 260.h,
                      child: DottedBorder(
                        color: Colors.grey,
                        strokeWidth: 1,
                        dashPattern: const [5, 8],
                        child: Padding(
                          padding: EdgeInsets.all(20.w),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              pr.imageFile != null
                                  ? Expanded(
                                      child: Image.file(
                                        pr.imageFile!,
                                        fit: BoxFit.contain,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.image,
                                      size: 50,
                                      color: Colors.grey,
                                    ),

                              SizedBox(height: 10.h),

                              const Text(
                                '(File Supported .png .jpg .webp)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),

                              SizedBox(height: 20.h),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _imageButton(
                                    context,
                                    label: "Take Picture",
                                    onTap: () async {
                                      final ok = await _requestCameraPermission(
                                        context,
                                      );
                                      if (!ok) return;

                                      await pr.pickImage(ImageSource.camera);
                                      AppToast.showToast(
                                        pr.imageFile != null
                                            ? "Image selected"
                                            : "No image selected",
                                      );
                                    },
                                  ),
                                  SizedBox(width: 10.w),
                                  _imageButton(
                                    context,
                                    label: "Upload Picture",
                                    onTap: () async {
                                      await pr.pickImage(ImageSource.gallery);
                                      AppToast.showToast(
                                        pr.imageFile != null
                                            ? "Image selected"
                                            : "No image selected",
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),

                SizedBox(height: 20.h),

                /// SUBMIT BUTTON
                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    text: 'Add Item',
                    onPressed: () {
                      Navigator.pushNamed(context, RouteName.itemAddQuestion);
                    },
                  ),
                ),

                SizedBox(height: 40.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String title,
    required String hint,
    required TextEditingController controller,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title),
        TextField(
          controller: controller,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderSide: const BorderSide(color: Color(0xff9e9e9e)),
              borderRadius: BorderRadius.circular(10.r),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Color(0xff9e9e9e)),
              borderRadius: BorderRadius.circular(10.r),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Color(0xff9e9e9e)),
              borderRadius: BorderRadius.circular(10.r),
            ),
            errorStyle: const TextStyle(fontSize: 12, color: Colors.red),
          ),
        ),
      ],
    );
  }

  Widget _imageButton(
    BuildContext context, {
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
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
