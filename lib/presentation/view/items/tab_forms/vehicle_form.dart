import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:maintenance_genie/app/routes/route_names.dart';
import 'package:maintenance_genie/core/constants/app_colors.dart';
import 'package:maintenance_genie/presentation/view_models/add_item_provider.dart';
import 'package:maintenance_genie/presentation/view_models/all_item_list_provider.dart';
import 'package:maintenance_genie/presentation/view_models/user_provider.dart';
import 'package:maintenance_genie/shared/app_toast.dart';
import 'package:maintenance_genie/shared/common_widgets.dart';
import 'package:provider/provider.dart';

import '../../../../shared/asset_image_picker.dart';
import '../../../../shared/custom_text_field.dart';
import '../widgets/custom_date_picker_field.dart';
import '../widgets/custom_drop_down_field.dart';
import '../widgets/custom_year_dropdown_field.dart';
import '../widgets/show_item_added_dialog.dart';

class VehicleForm extends StatefulWidget {
  const VehicleForm({super.key, required this.category});

  final String category;

  @override
  State<VehicleForm> createState() => _VehicleFormState();
}

class _VehicleFormState extends State<VehicleForm>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  static const List<String> brandList = [
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

  final nameController = TextEditingController();
  final mileageController = TextEditingController();
  final engineController = TextEditingController();
  final transmissionController = TextEditingController();
  final drivetrainController = TextEditingController();
  final currentMileageController = TextEditingController();
  final averageMileagePerYearController = TextEditingController();
  final userNotesController = TextEditingController();
  final _image = AssetImageController();

  final _brand = ValueNotifier<String?>(null);
  final _model = ValueNotifier<String?>(null);
  final _year = ValueNotifier<String?>(null);
  final _date = ValueNotifier<DateTime?>(null);

  @override
  void dispose() {
    nameController.dispose();
    mileageController.dispose();
    engineController.dispose();
    transmissionController.dispose();
    drivetrainController.dispose();
    currentMileageController.dispose();
    averageMileagePerYearController.dispose();
    userNotesController.dispose();
    _image.dispose();
    _brand.dispose();
    _model.dispose();
    _year.dispose();
    _date.dispose();
    super.dispose();
  }

  void clear() {
    nameController.clear();
    mileageController.clear();
    engineController.clear();
    transmissionController.clear();
    drivetrainController.clear();
    currentMileageController.clear();
    averageMileagePerYearController.clear();
    userNotesController.clear();
    _image.clear();
    _brand.value = null;
    _model.value = null;
    _year.value = null;
    _date.value = null;
  }

  String? _nullIfEmpty(String s) => s.trim().isEmpty ? null : s.trim();

  String? _validate() {
    if (nameController.text.trim().isEmpty) return 'Please enter an item name';
    if (_brand.value == null) return 'Please select a make';
    if (_model.value == null) return 'Please select a model';
    if (_year.value == null) return 'Please enter year of model';
    if (_date.value == null) return 'Please select a purchase date';
    return null;
  }

  AddItemData _collect() => AddItemData(
    name: nameController.text.trim(),
    brand: _brand.value!,
    model: _model.value!,
    category: widget.category,
    purchaseDate: _date.value!,
    yearOfModel: _year.value!,
    imageFile: _image.value,
    totalMileage: int.tryParse(mileageController.text.trim()),
    engine: _nullIfEmpty(engineController.text),
    transmission: _nullIfEmpty(transmissionController.text),
    drivetrain: _nullIfEmpty(drivetrainController.text),
    currentMileage: int.tryParse(currentMileageController.text.trim()),
    averageMileagePerYear: int.tryParse(
      averageMileagePerYearController.text.trim(),
    ),
    userNotes: _nullIfEmpty(userNotesController.text),
  );

  Future<void> _submit() async {
    final error = _validate();
    if (error != null) {
      AppToast.showToast(error, backgroundColor: Colors.red);
      return;
    }

    final data = _collect();
    final isPremium =
        context.read<UserProvider>().userResponse?.data.isPremium == true;

    if (isPremium) {
      Navigator.pushNamed(context, RouteName.itemAddQuestion, arguments: data);
      return;
    }

    final provider = context.read<AddItemProvider>();
    final ok = await provider.addItem(data);
    if (!mounted) return;

    if (ok) {
      context.read<AllItemListProvider>().getAllItem();
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => ItemAddedDialog(
          onDone: () => Navigator.popAndPushNamed(context, RouteName.parent),
          isPremium: false,
        ),
      );
      provider.clearFields();
      clear();
    } else {
      AppToast.showToast('Something went wrong');
    }
  }

  void _onBrandChanged(String value) {
    _brand.value = value;
    _model.value = null;
    context.read<AddItemProvider>().getModels(value);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Column(
        children: [
          /// NAME
          CustomTextField(
            title: 'Name *',
            hintText: 'e.g. Car, Sedan, Truck',
            controller: nameController,
          ),

          SizedBox(height: 20.h),

          /// MAKE + MODEL
          Row(
            children: [
              Expanded(
                child: ValueListenableBuilder<String?>(
                  valueListenable: _brand,
                  builder: (_, brand, __) => CustomPopupDropdown(
                    title: 'Make *',
                    hint: 'Select',
                    value: brand,
                    items: brandList,
                    onChanged: _onBrandChanged,
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Consumer<AddItemProvider>(
                  builder: (_, pr, __) => ValueListenableBuilder<String?>(
                    valueListenable: _brand,
                    builder: (_, brand, __) => ValueListenableBuilder<String?>(
                      valueListenable: _model,
                      builder: (_, model, __) => IgnorePointer(
                        ignoring: pr.isModelLoading,
                        child: Opacity(
                          opacity: pr.isModelLoading ? 0.5 : 1.0,
                          child: CustomPopupDropdown(
                            title: 'Model *',
                            hint: pr.isModelLoading ? 'Loading...' : 'Select',
                            value: model,
                            items: pr.modelList,
                            onChanged: (v) => _model.value = v,
                            onDisabledTap: brand == null
                                ? () => AppToast.showToast(
                                    'Please select a Make first',
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 20.h),

          /// YEAR
          ValueListenableBuilder<String?>(
            valueListenable: _year,
            builder: (_, year, __) => YearDropdownField(
              title: 'Year of the model *',
              hint: 'Select',
              selectedYear: year,
              onChanged: (v) => _year.value = v,
            ),
          ),

          SizedBox(height: 20.h),

          /// DATE + MILEAGE
          Row(
            children: [
              Expanded(
                child: ValueListenableBuilder<DateTime?>(
                  valueListenable: _date,
                  builder: (_, date, __) => CustomDatePickerField(
                    context: context,
                    title: 'Purchase Date *',
                    hint: 'Select',
                    selectedDate: date,
                    onDatePicked: (d) => _date.value = d,
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: CustomTextField(
                  title: 'Total Mileage',
                  hintText: 'Number',
                  controller: mileageController,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),

          SizedBox(height: 20.h),

          /// IMAGE SECTION
          AssetImagePicker(
            title: 'Vehicle Photo',
            controller: _image,
          ),

          SizedBox(height: 20.h),

          CustomTextField(
            title: 'Engine',
            hintText: 'e.g. 2.5L 4-Cylinder',
            controller: engineController,
          ),
          SizedBox(height: 20.h),
          CustomTextField(
            title: 'Transmission',
            hintText: 'e.g. 8-Speed Automatic',
            controller: transmissionController,
          ),
          SizedBox(height: 20.h),
          CustomTextField(
            title: 'Drivetrain',
            hintText: 'e.g. FWD',
            controller: drivetrainController,
          ),

          SizedBox(height: 20.h),

          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  title: 'Current Mileage',
                  hintText: 'Number',
                  controller: currentMileageController,
                  keyboardType: TextInputType.number,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: CustomTextField(
                  title: 'Average Mileage Per Year',
                  hintText: 'Number',
                  controller: averageMileagePerYearController,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),

          SizedBox(height: 20.h),

          CustomTextField(
            title: 'User Notes (optional)',
            hintText: 'e.g. Regular maintenance, no major issues...',
            controller: userNotesController,
            maxLines: 4,
          ),

          SizedBox(height: 20.h),

          /// SUBMIT BUTTON
          Selector<AddItemProvider, bool>(
            selector: (_, p) => p.isLoading,
            builder: (_, isLoading, __) => Visibility(
              visible: !isLoading,
              replacement: Center(
                child: CircularProgressIndicator(color: AppColors.primaryColor),
              ),
              child: SizedBox(
                width: double.infinity,
                child: PrimaryButton(text: 'Add Asset', onPressed: _submit),
              ),
            ),
          ),

          SizedBox(height: 40.h),
        ],
      ),
    );
  }
}
