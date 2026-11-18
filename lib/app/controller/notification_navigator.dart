import 'dart:async';

import 'package:flutter/material.dart';
import 'package:maintenance_genie/app/routes/route_names.dart';
import 'package:maintenance_genie/core/services/navigation_service.dart';
import 'package:maintenance_genie/core/services/notification/notification_service.dart';
import 'package:maintenance_genie/data/models/notification_response_model.dart';
import 'package:maintenance_genie/data/models/task_list_response_model.dart';
import 'package:maintenance_genie/presentation/view_models/item_task_list_by_item_id_provider.dart';
import 'package:maintenance_genie/presentation/view_models/notification_provider.dart';
import 'package:maintenance_genie/presentation/view_models/parent_screen_provider.dart';
import 'package:maintenance_genie/shared/app_toast.dart';
import 'package:provider/provider.dart';

class NotificationNavigator {
  NotificationNavigator._();

  static final NotificationNavigator instance = NotificationNavigator._();

  NotificationTarget? _pending;
  bool _homeReady = false;
  bool _opening = false;

  // ---------------------------------------------------------------------------
  // Entry points
  // ---------------------------------------------------------------------------

  void handleTap(Map<String, dynamic> payload) {
    unawaited(NotificationService.instance.cancelAllNotifications());

    final target = NotificationTarget.fromPush(payload);

    if (!target.opensTask) return;

    if (!_homeReady) {
      _pending = target;
      return;
    }
    unawaited(_goTo(target));
  }

  void attachHome() {
    _homeReady = true;

    final pending = _pending;
    if (pending == null) return;
    _pending = null;
    unawaited(_goTo(pending));
  }

  void detachHome() => _homeReady = false;

  void discardPending() => _pending = null;

  // ---------------------------------------------------------------------------
  // Navigation
  // ---------------------------------------------------------------------------

  Future<void> _goTo(NotificationTarget target) async {
    final navigator = navigatorKey.currentState;
    final context = navigatorKey.currentContext;
    if (navigator == null || context == null) return;

    navigator.popUntil(
          (route) => route.settings.name == RouteName.parent || route.isFirst,
    );
    context.read<ParentScreensProvider>().onSelectedIndex(0);

    unawaited(context.read<NotificationProvider>().refresh());

    await openTask(itemId: target.itemId!, taskId: target.taskId!);
  }

  Future<bool> openTask({
    required String itemId,
    required String taskId,
  }) async {
    if (_opening) return false;

    final navigator = navigatorKey.currentState;
    final context = navigatorKey.currentContext;
    if (navigator == null || context == null) return false;

    _opening = true;
    try {
      final byItem = context.read<ItemTaskListByItemIdProvider>();
      byItem.setItemId(itemId);
      await byItem.loadItemTasks();

      final task = _findTask(byItem, taskId);
      if (task == null) {
        if (!byItem.hasError) {
          AppToast.showToast(
            'This task is no longer available.',
            backgroundColor: Colors.red,
          );
        }
        return false;
      }

      byItem.selectTask(task);
      unawaited(navigator.pushNamed(RouteName.trackingDetail));
      return true;
    } finally {
      _opening = false;
    }
  }

  TaskResponse? _findTask(ItemTaskListByItemIdProvider provider, String id) {
    for (final task in provider.activeTasks) {
      if (task.id == id) return task;
    }
    for (final task in provider.completedTasks) {
      if (task.id == id) return task;
    }
    return null;
  }
}