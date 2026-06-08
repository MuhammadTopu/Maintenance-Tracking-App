import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../view_models/item_task_list_by_item_id_provider.dart';
import '../../../view_models/item_task_list_provider.dart';

class DropDownWidget extends StatefulWidget {
  const DropDownWidget({super.key, required this.status});

  final String status;

  @override
  State<DropDownWidget> createState() => _DropDownWidgetState();
}

class _DropDownWidgetState extends State<DropDownWidget> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  bool showItem = false;

  void _showPopupMenu(BuildContext context) {
    _removeOverlay();

    _overlayEntry = OverlayEntry(
      builder:
          (context) => Positioned(
            width: 150.w,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(-80, 40),
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12.r),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [_buildMenuItem("Mark as Completed")],
                ),
              ),
            ),
          ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  Widget _buildMenuItem(String value) {
    return InkWell(
      onTap: () async {
        debugPrint('Tapped: $value');
        await context.read<ItemTaskListByItemIdProvider>().toggleTaskStatus();
        await context.read<ItemTaskListByItemIdProvider>().refreshTaskList();
        _removeOverlay();
        await context.read<ItemTaskListProvider>().getItemTasks();
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.grey.shade100, width: 1.w),
        ),
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
        child: Text(value),
      ),
    );
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: () {
          setState(() {
            showItem = !showItem;
          });
          if (showItem && widget.status != "Completed") {
            _showPopupMenu(context);
          } else {
            _removeOverlay();
          }
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: Colors.lightBlue.shade50,
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(color: Colors.grey.shade400),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.status),
              SizedBox(width: 4.w,),
              SvgPicture.asset(
                'assets/icons/arrow-down.svg',
                height: 16.w,
                width: 16.w,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
