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
      notifyListeners();
    }

    setLoading(false);
  }
}