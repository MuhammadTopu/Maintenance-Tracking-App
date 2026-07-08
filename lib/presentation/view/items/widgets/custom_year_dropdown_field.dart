import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class YearDropdownField extends StatelessWidget {
  final String title;
  final String hint;
  final String? selectedYear;
  final ValueChanged<String> onChanged;
  final int startYear;
  final int endYear;

  const YearDropdownField({
    super.key,
    required this.title,
    required this.onChanged,
    this.selectedYear,
    this.hint = 'Select',
    this.startYear = 1800,
    this.endYear = 2100,
  });

  Future<void> _openYearPicker(BuildContext context) async {
    final currentYear = DateTime.now().year;
    final years = List<int>.generate(
      endYear - startYear + 1,
          (i) => startYear + i,
    );

    final int focusYear = int.tryParse(selectedYear ?? '') ?? currentYear;
    final int focusIndex = (focusYear - startYear).clamp(0, years.length - 1);

    const double itemExtent = 48;
    final ScrollController controller = ScrollController();

    final result = await showModalBottomSheet<int>(
      backgroundColor: Colors.white,
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (sheetContext) {
        final sheetHeight = MediaQuery.of(sheetContext).size.height * 0.6;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          final offset =
              (focusIndex * itemExtent) - (sheetHeight / 2) + (itemExtent / 2);
          controller.jumpTo(offset.clamp(0, controller.position.maxScrollExtent));
        });

        return SizedBox(
          height: sheetHeight,
          child: Column(
            children: [
              SizedBox(height: 12.h),
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                title,
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  itemExtent: itemExtent,
                  itemCount: years.length,
                  itemBuilder: (_, index) {
                    final year = years[index];
                    final isSelected = year == focusYear;
                    return InkWell(
                      onTap: () => Navigator.pop(sheetContext, year),
                      child: Container(
                        alignment: Alignment.center,
                        color: isSelected
                            ? Colors.grey.withValues(alpha: 0.15)
                            : Colors.transparent,
                        child: Text(
                          '$year',
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w400,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );

    controller.dispose();

    if (result != null) {
      onChanged(result.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title),
        SizedBox(height: 4.h),
        InkWell(
          onTap: () => _openYearPicker(context),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xff9e9e9e)),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedYear ?? hint,
                  style: TextStyle(
                    color: selectedYear == null ? Colors.grey : Colors.black,
                    fontSize: 14.sp,
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down_rounded),
              ],
            ),
          ),
        ),
      ],
    );
  }
}