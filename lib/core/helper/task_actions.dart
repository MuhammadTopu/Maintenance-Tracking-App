import 'package:flutter/material.dart';
import 'package:maintenance_genie/app/routes/route_names.dart';
import 'package:maintenance_genie/data/models/task_list_response_model.dart';
import 'package:maintenance_genie/presentation/view_models/item_task_list_by_item_id_provider.dart';
import 'package:maintenance_genie/presentation/view_models/item_task_list_provider.dart';
import 'package:provider/provider.dart';

void openTaskDetails(BuildContext context, TaskResponse task) {
  context.read<ItemTaskListByItemIdProvider>().selectTask(task);
  Navigator.pushNamed(context, RouteName.trackingDetail);
}

Future<bool> toggleSelectedTask(BuildContext context) async {
  final byItem = context.read<ItemTaskListByItemIdProvider>();
  final lists = context.read<ItemTaskListProvider>();

  final previous = byItem.selectedTask?.status;
  final updated = await byItem.toggleSelectedTask();
  if (updated == null) return false;

  if (previous != null) {
    lists.applyTaskUpdate(updated, previousStatus: previous);
  }
  return true;
}

Future<void> refreshSelectedTask(BuildContext context) async {
  final byItem = context.read<ItemTaskListByItemIdProvider>();
  final lists = context.read<ItemTaskListProvider>();

  final fresh = await byItem.refreshSelectedTask();
  if (fresh != null) {
    lists.applyTaskUpdate(fresh, previousStatus: fresh.status);
  }
}