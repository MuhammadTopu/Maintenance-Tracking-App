import 'package:flutter/foundation.dart';
import 'package:maintenance_genie/data/models/task_list_response_model.dart';
import 'package:maintenance_genie/domain/repository/item_and_task_list_repository.dart';

class ItemTaskListByItemIdProvider extends ChangeNotifier {
  ItemTaskListByItemIdProvider(this._repository);

  final ItemAndTaskListRepository _repository;

  static const int _maxPages = 25;

  String _itemId = '';
  List<TaskResponse> _tasks = const <TaskResponse>[];
  List<TaskResponse> _active = const <TaskResponse>[];
  List<TaskResponse> _completed = const <TaskResponse>[];

  bool _loading = false;
  bool _failed = false;
  int _generation = 0;

  TaskResponse? _selected;
  bool _toggling = false;
  bool _disposed = false;

  // ---------------------------------------------------------------------------
  // Item tasks
  // ---------------------------------------------------------------------------

  String get itemId => _itemId;

  bool get isLoading => _loading;
  bool get hasError => _failed;
  bool get hasTasks => _tasks.isNotEmpty;

  List<TaskResponse> get activeTasks => _active;

  List<TaskResponse> get completedTasks => _completed;

  void setItemId(String id) {
    if (_applyItemId(id)) _notify();
  }

  bool _applyItemId(String id) {
    if (_itemId == id) return false;
    _itemId = id;
    _generation++;
    _loading = false;
    _failed = false;
    _setTasks(const <TaskResponse>[]);
    return true;
  }

  void _setTasks(List<TaskResponse> tasks) {
    _tasks = tasks;
    _active = tasks.where((t) => !t.isComplete).toList()
      ..sort(TaskResponse.compareByUrgency);
    _completed = tasks.where((t) => t.isComplete).toList()
      ..sort(TaskResponse.compareByCompletion);
  }

  Future<void> loadItemTasks({bool silent = false}) async {
    final id = _itemId;
    if (id.isEmpty) return;

    final generation = ++_generation;
    if (!silent) {
      _loading = true;
      _failed = false;
      _notify();
    }

    final byId = <String, TaskResponse>{};
    var page = 1;
    var ok = true;

    while (true) {
      final response = await _repository.getTaskListByItemId(
        itemId: id,
        page: page,
        limit: kTaskPageSize,
      );
      if (generation != _generation) return;

      if (response == null) {
        ok = false;
        break;
      }
      for (final task in response.tasks) {
        byId[task.id] = task;
      }
      if (!response.hasNextPage || response.tasks.isEmpty || page >= _maxPages) {
        break;
      }
      page++;
    }

    _loading = false;
    if (ok) {
      _failed = false;
      _setTasks(byId.values.toList());
      _syncSelectedFromList();
    } else {
      _failed = true;
    }
    _notify();
  }

  // ---------------------------------------------------------------------------
  // Selected task (task details screen)
  // ---------------------------------------------------------------------------

  TaskResponse? get selectedTask => _selected;
  bool get isToggling => _toggling;

  void selectTask(TaskResponse task) {
    _applyItemId(task.itemId);
    _selected = task;
    _notify();
  }

  Future<TaskResponse?> toggleSelectedTask() async {
    final current = _selected;
    if (current == null || _toggling) return null;

    _toggling = true;
    _notify();

    final updated = await _repository.toggleTaskStatus(taskId: current.id);

    _toggling = false;
    if (updated != null) _replace(updated);
    _notify();
    return updated;
  }

  Future<TaskResponse?> refreshSelectedTask() async {
    final current = _selected;
    if (current == null) return null;
    _applyItemId(current.itemId);
    await loadItemTasks(silent: true);
    return _selected;
  }

  void _replace(TaskResponse updated) {
    if (_selected?.id == updated.id) _selected = updated;

    final index = _tasks.indexWhere((t) => t.id == updated.id);
    if (index >= 0) {
      final next = List<TaskResponse>.of(_tasks);
      next[index] = updated;
      _setTasks(next);
    }
  }

  void _syncSelectedFromList() {
    final current = _selected;
    if (current == null) return;
    for (final task in _tasks) {
      if (task.id == current.id) {
        _selected = task;
        return;
      }
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}