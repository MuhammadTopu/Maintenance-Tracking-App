import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomPopupDropdown extends StatelessWidget {
  final String title;
  final String? value;
  final List<String> items;
  final String hint;
  final ValueChanged<String> onChanged;

  const CustomPopupDropdown({
    super.key,
    required this.title,
    required this.items,
    required this.value,
    required this.hint,
    required this.onChanged,
  });

  void _showPopupMenu(BuildContext context, GlobalKey key) async {
    final RenderBox renderBox =
    key.currentContext!.findRenderObject() as RenderBox;
    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final Size size = renderBox.size;

    final selected = await showMenu<String>(
      context: context,
      constraints: BoxConstraints(
        maxHeight: 500,
        minHeight: 170,
      ),
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + size.height + 4,
        offset.dx + size.width,
        offset.dy,
      ),
      items:
      items.map((item) {
        return PopupMenuItem<String>(value: item, child: Text(item));
      }).toList(),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
    );

    if (selected != null && selected != value) {
      onChanged(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final GlobalKey popupKey = GlobalKey();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title),
        GestureDetector(
          key: popupKey,
          onTap: () => _showPopupMenu(context, popupKey),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.w),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value ?? hint,
                    style: TextStyle(
                      color: value == null ? Colors.grey : Colors.black,
                      fontSize: 14.sp,
                    ),
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
