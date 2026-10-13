import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:maintenance_genie/shared/app_toast.dart';
import 'package:maintenance_genie/shared/common_widgets.dart';
import 'package:maintenance_genie/shared/custom_text_field.dart';

import '../../../../shared/asset_image_picker.dart';
import '../widgets/custom_drop_down_field.dart';
import '../widgets/custom_year_dropdown_field.dart';
import '../widgets/feature_checkbox_list.dart';

class HomeForm extends StatefulWidget {
  const HomeForm({super.key, required this.category});

  final String category;

  @override
  State<HomeForm> createState() => _HomeFormState();
}

class _HomeFormState extends State<HomeForm>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  static const _propertyTypes = [
    'House',
    'Condo / Apartment',
    'Townhouse',
    'Cabin',
    'Vacation home',
    'Rental property',
    'Mobile / Manufactured home'
    'Other',
  ];
  static const _ownership = ['Own', 'Rent'];
  static const _features = [
    'Central HVAC / heat pump / furnace',
    'Window or mini-split AC',
    'Water heater',
    'Well',
    'Septic',
    'Municipal water/sewer',
    'Gutters',
    'Fireplace / wood stove',
    'Sump pump',
    'Basement / crawlspace',
    'Garage',
    'Deck / porch',
    'Pool / hot tub',
    'Irrigation system',
    'Generator',
    'Water softener / filtration',
  ];

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

  void _toggle(String feature) {
    final next = {..._selected.value};
    next.contains(feature) ? next.remove(feature) : next.add(feature);
    _selected.value = next;
  }

  String? _validate() {
    if (_name.text.trim().isEmpty) return 'Please enter a property name';
    if (_type.value == null) return 'Please select a property type';
    return null;
  }

  Map<String, dynamic> _collect() => {
    'category': widget.category,
    'name': _name.text.trim(),
    'propertyType': _type.value,
    'yearBuilt': _yearBuilt.value,
    'zipCode': _zip.text.trim().isEmpty ? null : _zip.text.trim(),
    'ownOrRent': _own.value,
    'features': _selected.value.toList(),
    'image': _image.value,
    'userNotes': _notes.text.trim().isEmpty ? null : _notes.text.trim(),
  };

  void _submit() {
    FocusScope.of(context).unfocus();
    final error = _validate();
    if (error != null) {
      AppToast.showToast(error, backgroundColor: Colors.red);
      return;
    }
    debugPrint('Home form data: ${_collect()}');
    // TODO: connect API
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

          PrimaryButton(text: 'Add Asset', onPressed: _submit),
          SizedBox(height: 40.h),
        ],
      ),
    );
  }
}