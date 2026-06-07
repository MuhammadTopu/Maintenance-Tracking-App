import 'package:flutter/material.dart';
import 'package:maintenance_genie/domain/base_repository/item_and_task_list_repository.dart';

import '../../data/models/task_list_response_model.dart';

class ItemTaskListByItemIdProvider extends ChangeNotifier {
  final ItemAndTaskListRepository _repository;

  ItemTaskListByItemIdProvider(this._repository);

  bool _loader = false;
  bool get loader => _loader;

  bool _pageLoading = false;
  bool get pageLoading => _pageLoading;

  bool _toggleLoading = false;
  bool get toggleLoading => _toggleLoading;

  String _loaderTaskId = '';
  String get loaderTaskId => _loaderTaskId;

  String _itemId = '';
  String get itemId => _itemId;

  String _taskId = '';
  String get taskId => _taskId;

  String? _error;
  String? get error => _error;

  TaskListResponse? _taskListResponse;
  TaskListResponse? get taskListResponse => _taskListResponse;

  void setItemId(String id) {
    if (_itemId == id) return;

    _itemId = id;
    notifyListeners();
  }

  void setLoader(bool value, String taskId) {
    _loader = value;
    _loaderTaskId = taskId;
    notifyListeners();
  }

  Future<void> setTaskId(String taskId, String itemId) async {
    _taskId = taskId;
    _itemId = itemId;

    await getAllTaskListByItemId();
  }

  Future<void> refreshTaskList() async {
    await getAllTaskListByItemId();
  }

  Future<void> getAllTaskListByItemId() async {
    _pageLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _repository.getTaskListByItemId(itemId: _itemId);

      if (response != null) {
        _taskListResponse = response;
      } else {
        _error = "Failed to load task list";
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _pageLoading = false;
      notifyListeners();
    }
  }

  Future<bool> toggleTaskStatus() async {
    _toggleLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _repository.toggleTaskStatus(taskId: _taskId);

      if (success) {
        await getAllTaskListByItemId();
      }

      return success;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _toggleLoading = false;
      notifyListeners();
    }
  }
}
