import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:maintenance_genie/data/models/task_list_response_model.dart';
import 'package:maintenance_genie/presentation/view_models/item_task_list_by_item_id_provider.dart';
import 'package:maintenance_genie/shared/common_widgets.dart';
import 'package:maintenance_genie/shared/custom_item_app_bar.dart';
import 'package:maintenance_genie/shared/empty_state_widget.dart';
import 'package:maintenance_genie/shared/task_display.dart';
import 'package:provider/provider.dart';

import '../../../core/services/role/role_service.dart';
import '../../../core/services/role/user_role.dart';
import 'widget/drop_down_widget.dart';
import 'widget/receipt_section.dart';
import 'widget/task_detail_section.dart';

class TrackingDetailScreen extends StatelessWidget {
  const TrackingDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final task = context.select<ItemTaskListByItemIdProvider, TaskResponse?>(
      (provider) => provider.selectedTask,
    );
    final access = context.select<RoleService, ({bool receipts, bool shops})>(
      (role) => (
        receipts: role.can(AppFeature.receiptAttachments),
        shops: role.can(AppFeature.shopSuggestions),
      ),
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xffFFFFFF),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: task == null
                ? Column(
                    children: [
                      SizedBox(height: 20.h),
                      CustomItemAppBar(
                        title: 'Task Details',
                        onTap: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: EmptyState(
                          icon: Icons.assignment_outlined,
                          title: 'Task not found',
                          subtitle: 'Go back and open the task again.',
                        ),
                      ),
                    ],
                  )
                : _buildContent(context, task, access),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    TaskResponse task,
    ({bool receipts, bool shops}) access,
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 20.h),
          CustomItemAppBar(
            title: 'Task Details',
            onTap: () => Navigator.pop(context),
          ),
          SizedBox(height: 21.h),
          const Divider(thickness: 1, color: Color(0xffE9E9EA)),
          SizedBox(height: 20.h),
          Text(
            task.upcomingTask,
            style: TextStyle(
              color: const Color(0xff1D1F2C),
              fontSize: 20.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 12.h),
          _HeaderRow(
            icon: Icons.add_home_outlined,
            label: 'Item :',
            value: Text(
              task.itemName,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xff4A4C56),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          SizedBox(height: 16.h),
          _HeaderRow(
            icon: Icons.check_box_outlined,
            label: 'Status :',
            value: Align(
              alignment: Alignment.centerRight,
              child: DropDownWidget(task: task),
            ),
          ),
          SizedBox(height: 16.h),
          _HeaderRow(
            icon: Icons.calendar_month,
            label: 'Due date :',
            value: Text(task.dueDateLabel, textAlign: TextAlign.right),
          ),
          if (task.completedOnLabel != null) ...[
            SizedBox(height: 16.h),
            _HeaderRow(
              icon: Icons.task_alt,
              label: 'Completed on :',
              value: Text(task.completedOnLabel!, textAlign: TextAlign.right),
            ),
          ],
          SizedBox(height: 12.h),
          Divider(color: Colors.grey.shade400, height: 1, thickness: 1),
          SizedBox(height: 12.h),
          TaskInfoSection(task: task),
          SizedBox(height: 12.h),
          if (access.receipts) ...[
            ReceiptSection(task: task),
            SizedBox(height: 12.h),
          ],
          MaintenanceHistorySection(history: task.maintenanceHistory),
          if (access.shops) ...[
            SizedBox(height: 12.h),
            ShopSuggestionsSection(shops: task.shopSuggestions),
          ],
          if (!access.receipts || !access.shops) ...[
            SizedBox(height: 12.h),
            PremiumLockedView(title: _lockedTitle(access)),
          ],
          SizedBox(height: 24.h),
        ],
      ),
    );
  }

  static String _lockedTitle(({bool receipts, bool shops}) access) {
    if (!access.receipts && !access.shops) {
      return 'Go Premium to upload receipts\nand see Shop Suggestions';
    }
    return access.receipts
        ? 'Go Premium to see\nShop Suggestions'
        : 'Go Premium to upload\nreceipts';
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final Widget value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey),
        SizedBox(width: 8.w),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xff4A4C56),
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(child: value),
      ],
    );
  }
}
