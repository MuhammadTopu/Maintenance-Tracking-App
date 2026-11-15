import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/routes/route_names.dart';
import '../../presentation/view_models/all_item_list_provider.dart';
import '../../presentation/view_models/item_task_list_provider.dart';
import '../../presentation/view_models/parent_screen_provider.dart';
import '../../presentation/view_models/question_provider.dart';

/// Tab selected in the parent screen when a question flow ends. This is the
/// value the Vehicle flow already used.
const int kPostFlowTabIndex = 1;

/// The last step of every flow (Vehicle, Home, Other): create the tasks, refresh
/// the lists, and return to the main screen with the new asset.
///
/// Safe to call from a button: a second tap while the first is running is
/// ignored by [QuestionProvider.generateTasks], and the server returns the
/// existing tasks if tasks were already generated.
Future<void> generateTasksAndFinish(BuildContext context) async {
  final questions = context.read<QuestionProvider>();
  final taskList = context.read<ItemTaskListProvider>();
  final items = context.read<AllItemListProvider>();
  final parent = context.read<ParentScreensProvider>();
  final navigator = Navigator.of(context);

  final success = await questions.generateTasks();
  if (!context.mounted || !success) return;

  await taskList.getItemTasks();
  unawaited(items.getAllItem());
  if (!context.mounted) return;

  parent.onSelectedIndex(kPostFlowTabIndex);
  navigator.pushNamedAndRemoveUntil(RouteName.parent, (route) => false);
}