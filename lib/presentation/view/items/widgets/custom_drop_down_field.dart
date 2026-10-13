import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomPopupDropdown extends StatefulWidget {
  final String title;
  final String? value;
  final List<String> items;
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback? onDisabledTap;

  const CustomPopupDropdown({
    super.key,
    required this.title,
    required this.items,
    required this.value,
    required this.hint,
    required this.onChanged,
    this.onDisabledTap,
  });

  @override
  State<CustomPopupDropdown> createState() => _CustomPopupDropdownState();
}

class _CustomPopupDropdownState extends State<CustomPopupDropdown> {
  final GlobalKey _popupKey = GlobalKey();

  Future<void> _showPopupMenu() async {
    final box = _popupKey.currentContext!.findRenderObject() as RenderBox;
    final offset = box.localToGlobal(Offset.zero);
    final size = box.size;

    final selected = await showMenu<String>(
      context: context,
      constraints: const BoxConstraints(maxHeight: 500, minHeight: 170, minWidth: 150, maxWidth: 200),
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + size.height + 4,
        offset.dx + size.width,
        offset.dy,
      ),
      items: widget.items
          .map((i) => PopupMenuItem<String>(value: i, child: Text(i)))
          .toList(),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
    );

    if (selected != null && selected != widget.value) {
      widget.onChanged(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.title),
        SizedBox(height: 4.h),
        GestureDetector(
          key: _popupKey,
          onTap: () {
            if (widget.onDisabledTap != null) {
              widget.onDisabledTap!();
              return;
            }
            _showPopupMenu();
          },
          child: Container(
            height: 46.h,
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.value ?? widget.hint,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: widget.value == null ? Colors.grey : Colors.black,
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