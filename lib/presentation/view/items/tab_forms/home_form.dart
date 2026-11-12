import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:maintenance_genie/domain/entities/add_item_data.dart';
import 'package:maintenance_genie/shared/app_toast.dart';
import 'package:maintenance_genie/shared/custom_text_field.dart';

import '../../../../shared/asset_image_picker.dart';
import '../mixins/add_item_submission_mixin.dart';
import '../widgets/custom_drop_down_field.dart';
import '../widgets/custom_year_dropdown_field.dart';
import '../widgets/feature_checkbox_list.dart';

class HomeForm extends StatefulWidget {
  const HomeForm({super.key});

  @override
  State<HomeForm> createState() => _HomeFormState();
}

class _HomeFormState extends State<HomeForm>
    with AutomaticKeepAliveClientMixin, AddItemSubmissionMixin {
  @override
  bool get wantKeepAlive => true;

  static const _propertyTypes = [
    'House',
    'Condo / Apartment',
    'Townhouse',
    'Cabin',
    'Vacation home',
    'Rental property',
    'Mobile / Manufactured home',
    'Other',
  ];
  static const _ownership = ['Own', 'Rent'];

  static final List<String> _features = HomeSystems.labels;

  final _name = TextEditingController();
  final _zip = TextEditingController();
  final _notes = TextEditingController();
  final _image = AssetImageController();

  final _type = ValueNotifier<String?>(null);
  final _yearBuilt = ValueNotifier<String?>(null);
  final _own = ValueNotifier<String?>(null);
  final _selected = ValueNotifier<Set<String>>({});

  @override
  void dispose() {
    _name.dispose();
    _zip.dispose();
    _notes.dispose();
    _image.dispose();
    _type.dispose();
    _yearBuilt.dispose();
    _own.dispose();
    _selected.dispose();
    super.dispose();
  }

  void _clear() {
    _name.clear();
    _zip.clear();
    _notes.clear();
    _image.clear();
    _type.value = null;
    _yearBuilt.value = null;
    _own.value = null;
    _selected.value = {};
  }

  void _toggle(String feature) {
    final next = {..._selected.value};
    next.contains(feature) ? next.remove(feature) : next.add(feature);
    _selected.value = next;
  }

  String? _nullIfEmpty(String s) => s.trim().isEmpty ? null : s.trim();

  String? _validate() {
    if (_name.text.trim().isEmpty) return 'Please enter a property name';
    if (_type.value == null) return 'Please select a property type';
    if (_zip.text.trim().length > HomeItemData.maxZipLength) {
      return 'ZIP code can be at most ${HomeItemData.maxZipLength} characters';
    }
    return null;
  }

  HomeItemData _collect() => HomeItemData(
    name: _name.text.trim(),
    propertyType: _type.value!,
    yearBuilt: _yearBuilt.value,
    zipCode: _nullIfEmpty(_zip.text),
    ownOrRent: _own.value,
    systems: HomeSystems.slugsOf(_selected.value),
    imageFile: _image.value,
    userNotes: _nullIfEmpty(_notes.text),
  );

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final error = _validate();
    if (error != null) {
      AppToast.showToast(error, backgroundColor: Colors.red);
      return;
    }

    // TODO: premium users should continue into the Home question flow once
    // that screen exists (set openQuestionFlowForPremium: true then).
    await submitItem(_collect(), onSaved: _clear);
  }

  Widget _heading(String text) => Text(
    text,
    style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
  );

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [

          CustomTextField(
            title: 'Property Name *',
            hintText: 'e.g. Home, Lake House, Rental',
            controller: _name,
          ),
          SizedBox(height: 20.h),

          ValueListenableBuilder<String?>(
            valueListenable: _type,
            builder: (_, v, __) => CustomPopupDropdown(
              title: 'Property Type *',
              hint: 'Select',
              value: v,
              items: _propertyTypes,
              onChanged: (x) => _type.value = x,
            ),
          ),
          SizedBox(height: 20.h),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ValueListenableBuilder<String?>(
                  valueListenable: _yearBuilt,
                  builder: (_, v, __) => YearDropdownField(
                    title: 'Year Built',
                    hint: 'Select',
                    selectedYear: v,
                    endYear: DateTime.now().year,
                    onChanged: (x) => _yearBuilt.value = x,
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: CustomTextField(
                  title: 'ZIP Code',
                  hintText: 'ZIP code',
                  controller: _zip,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),

          ValueListenableBuilder<String?>(
            valueListenable: _own,
            builder: (_, v, __) => CustomPopupDropdown(
              title: 'Own or Rent',
              hint: 'Select',
              value: v,
              items: _ownership,
              onChanged: (x) => _own.value = x,
            ),
          ),
          SizedBox(height: 20.h),

          _heading('What does this property have?'),
          SizedBox(height: 4.h),
          Text(
            'Check whatever applies',
            style: TextStyle(fontSize: 12.sp, color: const Color(0xff808080)),
          ),
          SizedBox(height: 12.h),
          ValueListenableBuilder<Set<String>>(
            valueListenable: _selected,
            builder: (_, sel, __) => FeatureCheckboxList(
              options: _features,
              selected: sel,
              onToggle: _toggle,
            ),
          ),
          SizedBox(height: 20.h),

          AssetImagePicker(
            title: 'Property Photo',
            controller: _image,
          ),
          SizedBox(height: 20.h),

          CustomTextField(
            title: 'User Notes (optional)',
            hintText: 'e.g. Regular maintenance, no major issues...',
            controller: _notes,
            maxLines: 4,
          ),
          SizedBox(height: 20.h),

          buildSubmitButton(onPressed: _submit),
          SizedBox(height: 40.h),
        ],
      ),
    );
  }
}