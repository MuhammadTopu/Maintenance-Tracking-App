import 'package:flutter/material.dart';
import 'package:maintenance_genie/domain/base_repository/item_and_task_list_repository.dart';
import '../../data/models/task_list_response_model.dart';

class ItemTaskListProvider extends ChangeNotifier {
  final ItemAndTaskListRepository _repository;

  ItemTaskListProvider(this._repository);

  bool _loading = false;
  bool get loading => _loading;

  void setLoading(bool loading) {
    _loading = loading;
    notifyListeners();
  }

  TaskListResponse? _taskListResponse;
  TaskListResponse? get taskListResponse => _taskListResponse;

  Future<void> getItemTasks() async {
    setLoading(true);

    final response = await _repository.getAllTasksList();

    if (response != null) {
      _taskListResponse = response;
      _filteredTaskListResponse = response;
      notifyListeners();
    }

    setLoading(false);
  }

  TaskListResponse? _filteredTaskListResponse;
  TaskListResponse? get filteredTaskListResponse => _filteredTaskListResponse;

  void filterTasks(String filterValue) {
    if (_taskListResponse == null) return;

    switch (filterValue) {
      case 'Most Recent':
        _filteredTaskListResponse = _taskListResponse;
        break;
      case 'Pending':
        _filteredTaskListResponse = TaskListResponse(
            tasks: _taskListResponse!.tasks.where((task) => task.status == 'Due').toList(), success: true, message: ''
        );
        break;
      case 'Completed':
        _filteredTaskListResponse = TaskListResponse(
            tasks: _taskListResponse!.tasks.where((task) => task.status == 'Completed').toList(), success: true, message: ''
        );
        break;
      case 'Cancelled':
        _filteredTaskListResponse = TaskListResponse(
          tasks: _taskListResponse!.tasks.where((task) => task.status == 'Cancelled').toList(), success: true, message: '',
        );
        break;
    }
    notifyListeners();
  }
}