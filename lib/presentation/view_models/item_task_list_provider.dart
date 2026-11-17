import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:maintenance_genie/data/models/task_list_response_model.dart';
import 'package:maintenance_genie/domain/repository/item_and_task_list_repository.dart';

class _TaskBucket {
  List<TaskResponse> tasks = <TaskResponse>[];
  bool loaded = false;
  bool loading = false;
  bool loadingMore = false;
  bool hasNext = false;
  bool failed = false;
  bool stale = false;
  int generation = 0;
  int total = 0;
  int pageSize = kTaskPageSize;

  void reset() {
    generation++;
    tasks = <TaskResponse>[];
    loaded = false;
    loading = false;
    loadingMore = false;
    hasNext = false;
    failed = false;
    stale = false;
    total = 0;
    pageSize = kTaskPageSize;
  }
}

class ItemTaskListProvider extends ChangeNotifier {
  ItemTaskListProvider(this._repository);

  final ItemAndTaskListRepository _repository;

  final Map<TaskFilter, _TaskBucket> _buckets = <TaskFilter, _TaskBucket>{
    for (final filter in TaskFilter.values) filter: _TaskBucket(),
  };

  TaskFilter _selectedFilter = TaskFilter.all;
  TaskCounts _counts = TaskCounts.empty;
  bool _countsKnown = false;

  TaskResponse? _upcomingTask;
  int _upcomingGeneration = 0;

  bool _disposed = false;

  _TaskBucket get _selected => _buckets[_selectedFilter]!;
  _TaskBucket get _all => _buckets[TaskFilter.all]!;

  // ---------------------------------------------------------------------------
  // Tracking screen state (the selected filter tab)
  // ---------------------------------------------------------------------------

  TaskFilter get selectedFilter => _selectedFilter;

  List<TaskResponse> get tasks => UnmodifiableListView<TaskResponse>(
    _selected.tasks,
  );

  bool get isLoading => _selected.loading;

  bool get isLoadingMore => _selected.loadingMore;

  bool get hasNextPage => _selected.hasNext;

  bool get hasError => _selected.failed && _selected.tasks.isEmpty;

  int get total =>
      _selected.total > _selected.tasks.length
          ? _selected.total
          : _selected.tasks.length;

  TaskCounts get counts => _counts;
  bool get hasCounts => _countsKnown;

  // ---------------------------------------------------------------------------
  // Dashboard state
  // ---------------------------------------------------------------------------

  List<TaskResponse> get dashboardTasks {
    final all = _all.tasks;
    return UnmodifiableListView<TaskResponse>(
      all.length > kTaskPageSize ? all.sublist(0, kTaskPageSize) : all,
    );
  }

  bool get isDashboardLoading => _all.loading;
  bool get hasDashboardError => _all.failed && _all.tasks.isEmpty;

  TaskResponse? get upcomingTask => _upcomingTask;

  // ---------------------------------------------------------------------------
  // Loading
  // ---------------------------------------------------------------------------

  Future<void> ensureDashboardLoaded() => _ensureLoaded(TaskFilter.all);

  Future<void> ensureSelectedLoaded() => _ensureLoaded(_selectedFilter);

  Future<void> getItemTasks() async {
    for (final bucket in _buckets.values) {
      if (bucket.loaded) bucket.stale = true;
    }
    await Future.wait(<Future<void>>[
      _loadFirstPage(TaskFilter.all),
      if (_selectedFilter != TaskFilter.all) _loadFirstPage(_selectedFilter),
    ]);
  }

  Future<void> refreshSelected() => _loadFirstPage(_selectedFilter);

  Future<void> selectFilter(TaskFilter filter) async {
    if (filter == _selectedFilter) return;
    _selectedFilter = filter;
    _notify();
    await _ensureLoaded(filter);
  }

  Future<void> _ensureLoaded(TaskFilter filter) async {
    final bucket = _buckets[filter]!;
    if (bucket.loading) return;
    if (bucket.loaded && !bucket.stale) return;
    await _loadFirstPage(filter);
  }

  Future<void> _loadFirstPage(TaskFilter filter) async {
    final bucket = _buckets[filter]!;
    final generation = ++bucket.generation;
    bucket.loading = true;
    bucket.loadingMore = false;
    bucket.failed = false;
    _notify();

    TaskListResponse? response;
    try {
      response = await _repository.getAllTasksList(
        filter: filter,
        page: 1,
        limit: kTaskPageSize,
      );
    } catch (_) {
      response = null;
    }

    if (generation != bucket.generation) return;

    bucket.loading = false;
    if (response == null) {
      bucket.failed = true;
    } else {
      bucket.tasks = List<TaskResponse>.of(response.tasks);
      bucket.loaded = true;
      bucket.stale = false;
      bucket.hasNext = response.hasNextPage;
      bucket.total = response.total;
      bucket.pageSize = response.limit > 0 ? response.limit : kTaskPageSize;
      _counts = response.counts;
      _countsKnown = true;
    }
    _notify();

    if (response != null && filter == TaskFilter.all) {
      unawaited(_loadUpcomingTask());
    }
  }

  Future<void> loadMore() async {
    final filter = _selectedFilter;
    final bucket = _buckets[filter]!;
    if (!bucket.hasNext || bucket.loading || bucket.loadingMore) return;

    final generation = bucket.generation;
    bucket.loadingMore = true;
    _notify();

    final nextPage = bucket.tasks.length ~/ bucket.pageSize + 1;

    TaskListResponse? response;
    try {
      response = await _repository.getAllTasksList(
        filter: filter,
        page: nextPage,
        limit: bucket.pageSize,
      );
    } catch (_) {
      response = null;
    }

    if (generation != bucket.generation) return;

    bucket.loadingMore = false;
    if (response != null) {
      final known = bucket.tasks.map((t) => t.id).toSet();
      final fresh = response.tasks.where((t) => known.add(t.id)).toList();
      bucket.tasks = <TaskResponse>[...bucket.tasks, ...fresh];
      bucket.hasNext = response.hasNextPage;
      bucket.total = response.total;
      _counts = response.counts;
      _countsKnown = true;
      _notify();

      if (fresh.isEmpty && response.hasNextPage) {
        unawaited(_loadFirstPage(filter));
      }
    } else {
      _notify();
    }
  }

  Future<void> _loadUpcomingTask() async {
    final generation = ++_upcomingGeneration;

    final filters = <TaskFilter>[
      if (_counts.upcoming > 0) TaskFilter.upcoming,
      if (_counts.dueNow > 0) TaskFilter.dueNow,
    ];

    TaskResponse? found;
    for (final filter in filters) {
      TaskListResponse? response;
      try {
        response = await _repository.getAllTasksList(
          filter: filter,
          page: 1,
          limit: kTaskPageSize,
        );
      } catch (_) {
        response = null;
      }
      if (generation != _upcomingGeneration || _disposed) return;
      if (response == null) return;

      final open = response.tasks.where((t) => !t.isComplete).toList()
        ..sort(TaskResponse.compareByUrgency);
      if (open.isNotEmpty) {
        found = open.first;
        break;
      }
    }

    _upcomingTask = found;
    _notify();
  }

  // ---------------------------------------------------------------------------
  // Mutations
  // ---------------------------------------------------------------------------

  void applyTaskUpdate(
      TaskResponse updated, {
        required TaskStatus previousStatus,
      }) {
    _counts = _counts.afterStatusChange(
      from: previousStatus,
      to: updated.status,
    );

    for (final entry in _buckets.entries) {
      final filter = entry.key;
      final bucket = entry.value;
      final index = bucket.tasks.indexWhere((t) => t.id == updated.id);
      final belongs = filter.matches(updated.status);

      if (index >= 0 && belongs) {
        bucket.tasks[index] = updated;
      } else if (index >= 0) {
        bucket.tasks.removeAt(index);
        if (bucket.total > 0) bucket.total -= 1;
      } else if (belongs && bucket.loaded && filter != TaskFilter.all) {
        bucket.stale = true;
      }
    }

    if (_upcomingTask?.id == updated.id && updated.isComplete) {
      _upcomingTask = null;
    }
    final affectsUpcoming = <TaskStatus>{
      TaskStatus.upcoming,
      TaskStatus.dueNow,
    };
    if (affectsUpcoming.contains(previousStatus) ||
        affectsUpcoming.contains(updated.status)) {
      unawaited(_loadUpcomingTask());
    }

    _notify();
  }

  void reset() {
    for (final bucket in _buckets.values) {
      bucket.reset();
    }
    _selectedFilter = TaskFilter.all;
    _counts = TaskCounts.empty;
    _countsKnown = false;
    _upcomingTask = null;
    _upcomingGeneration++;
    _notify();
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