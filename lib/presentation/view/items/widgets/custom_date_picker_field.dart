import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomDatePickerField extends StatelessWidget {
  const CustomDatePickerField({super.key, required this.context, required this.title, required this.hint, this.selectedDate, required this.onDatePicked});

  final BuildContext context;
  final String title;
  final String hint;
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDatePicked;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title),
        InkWell(
          onTap: () async {
            DateTime? picked = await showDatePicker(
              context: context,
              initialDate: selectedDate ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (picked != null) onDatePicked(picked);
          },
          child: InputDecorator(
            decoration: InputDecoration(
              hintText: hint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide: BorderSide(color: Color(0xff8e8e91)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide: BorderSide(color: Color(0xff8e8e91)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide: BorderSide(color: Color(0xff8e8e91)),
              ),
              suffixIcon: const Icon(Icons.calendar_month_outlined),
            ),
            child: Text(
              selectedDate != null
                  ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                  : 'Select',
            ),
          ),
        ),
      ],
    );
  }
}