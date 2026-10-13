import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:maintenance_genie/shared/app_toast.dart';
import 'package:maintenance_genie/shared/common_widgets.dart';
import 'package:maintenance_genie/shared/custom_text_field.dart';

import '../../../../shared/asset_image_picker.dart';
import '../widgets/custom_date_picker_field.dart';
import '../widgets/custom_drop_down_field.dart';

class OtherForm extends StatefulWidget {
  const OtherForm({super.key, required this.category});

  final String category;

  @override
  State<OtherForm> createState() => _OtherFormState();
}

class _OtherFormState extends State<OtherForm>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  static const _groups = [
    'Household',
    'Garden',
    'Personal',
    'Work',
    'Finance',
    'Equipment',
    'Outdoor',
    'Project',
    'Seasonal',
    'Other',
  ];
  static const _repeats = ['Never', 'Daily', 'Weekly', 'Monthly', 'Yearly'];
  static const _reminders = [
    'None',
    'On the day',
    '1 day before',
    '3 days before',
    '1 week before',
    '2 weeks before',
  ];

  final _name = TextEditingController();
  final _description = TextEditingController();
  final _notes = TextEditingController();
  final _image = AssetImageController();

  final _group = ValueNotifier<String?>(null);
  final _dueDate = ValueNotifier<DateTime?>(null);
  final _repeat = ValueNotifier<String?>(null);
  final _reminder = ValueNotifier<String?>(null);

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _notes.dispose();
    _image.dispose();
    _group.dispose();
    _dueDate.dispose();
    _repeat.dispose();
    _reminder.dispose();
    super.dispose();
  }

  String? _nullIfEmpty(String s) => s.trim().isEmpty ? null : s.trim();

  String? _validate() {
    if (_name.text.trim().isEmpty) return 'Please enter a name';
    return null;
  }

  Map<String, dynamic> _collect() => {
    'category': widget.category,
    'name': _name.text.trim(),
    'group': _group.value,
    'description': _nullIfEmpty(_description.text),
    'dueDate': _dueDate.value,
    'repeat': _repeat.value,
    'reminder': _reminder.value,
    'notes': _nullIfEmpty(_notes.text),
    'attachment': _image.value,
  };

  void _submit() {
    FocusScope.of(context).unfocus();
    final error = _validate();
    if (error != null) {
      AppToast.showToast(error, backgroundColor: Colors.red);
      return;
    }
    debugPrint('Other form data: ${_collect()}');
    // TODO: connect API
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CustomTextField(
            title: 'Name *',
            hintText: 'e.g. Repaint mailbox',
            controller: _name,
          ),
          SizedBox(height: 20.h),

          ValueListenableBuilder<String?>(
            valueListenable: _group,
            builder: (_, v, __) => CustomPopupDropdown(
              title: 'Category',
              hint: 'Select',
              value: v,
              items: _groups,
              onChanged: (x) => _group.value = x,
            ),
          ),
          SizedBox(height: 20.h),

          CustomTextField(
            title: 'Description',
            hintText: 'Optional notes',
            controller: _description,
            maxLines: 4,
          ),
          SizedBox(height: 20.h),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ValueListenableBuilder<DateTime?>(
                  valueListenable: _dueDate,
                  builder: (_, d, __) => CustomDatePickerField(
                    context: context,
                    title: 'Due Date *',
                    hint: 'Select',
                    selectedDate: d,
                    onDatePicked: (x) => _dueDate.value = x,
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: ValueListenableBuilder<String?>(
                  valueListenable: _repeat,
                  builder: (_, v, __) => CustomPopupDropdown(
                    title: 'Repeat *',
                    hint: 'Select',
                    value: v,
                    items: _repeats,
                    onChanged: (x) => _repeat.value = x,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),

          ValueListenableBuilder<String?>(
            valueListenable: _reminder,
            builder: (_, v, __) => CustomPopupDropdown(
              title: 'Reminder *',
              hint: 'Select',
              value: v,
              items: _reminders,
              onChanged: (x) => _reminder.value = x,
            ),
          ),
          SizedBox(height: 20.h),

          CustomTextField(
            title: 'User Notes (optional)',
            hintText: 'Paint color, receipt...',
            controller: _notes,
            maxLines: 4,
          ),
          SizedBox(height: 20.h),

          AssetImagePicker(
            title: 'Attachments',
            controller: _image,
          ),
          SizedBox(height: 20.h),

          PrimaryButton(text: 'Add Asset', onPressed: _submit),
          SizedBox(height: 40.h),
        ],
      ),
    );
  }
}