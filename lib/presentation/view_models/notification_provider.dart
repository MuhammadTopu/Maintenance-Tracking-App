import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:maintenance_genie/data/models/notification_response_model.dart';
import 'package:maintenance_genie/domain/repository/notification_repository.dart';
import 'package:maintenance_genie/shared/app_toast.dart';

class NotificationProvider extends ChangeNotifier {
  NotificationProvider(this._repository);

  final NotificationRepository _repository;

  static const Duration _pushRetryDelay = Duration(seconds: 2);

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  bool _active = false;
  bool _disposed = false;
  bool _hasLoaded = false;

  int _generation = 0;

  List<AppNotification> _items = const <AppNotification>[];
  int _unreadCount = 0;
  int _total = 0;

  bool _loading = false;
  bool _loadFailed = false;
  bool _loadingMore = false;
  bool _loadMoreFailed = false;
  bool _markingAll = false;

  bool _refreshing = false;
  bool _refreshQueued = false;
  bool _refreshAfterMarkAll = false;

  final Set<String> _busy = <String>{};

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

  bool get isActive => _active;

  List<AppNotification> get items => _items;
  int get unreadCount => _unreadCount;

  bool get isLoading => _loading && _items.isEmpty;

  bool get hasError => _loadFailed && _items.isEmpty;

  bool get isLoadingMore => _loadingMore;
  bool get loadMoreFailed => _loadMoreFailed;
  bool get hasMore => _items.length < _total;
  bool get isMarkingAll => _markingAll;

  bool isBusy(String id) => _busy.contains(id);

  // ---------------------------------------------------------------------------
  // Life cycle
  // ---------------------------------------------------------------------------

  Future<void> activate() async {
    _active = true;
    if (_hasLoaded) {
      await refresh();
    } else {
      await loadInitial();
    }
  }

  void reset() {
    _generation++;
    _active = false;
    _hasLoaded = false;
    _items = const <AppNotification>[];
    _unreadCount = 0;
    _total = 0;
    _loading = false;
    _loadFailed = false;
    _loadingMore = false;
    _loadMoreFailed = false;
    _markingAll = false;
    _refreshing = false;
    _refreshQueued = false;
    _refreshAfterMarkAll = false;
    _busy.clear();
    _notify();
  }

  // ---------------------------------------------------------------------------
  // Loading
  // ---------------------------------------------------------------------------

  Future<void> loadInitial() async {
    if (!_active) return;

    final generation = ++_generation;
    _loading = true;
    _loadFailed = false;
    _loadMoreFailed = false;
    _loadingMore = false;
    _notify();

    try {
      final response = await _repository.getNotifications(page: 1);
      if (generation != _generation) return;

      _items = _unique(response.notifications);
      _unreadCount = response.unreadCount;
      _total = math.max(response.total, _items.length);
      _hasLoaded = true;
      _loadFailed = false;
    } on NotificationFailure {
      if (generation != _generation) return;
      _loadFailed = true;
    }

    _loading = false;
    _notify();
  }

  Future<void> refresh({bool userInitiated = false}) async {
    if (!_active) return;

    if (!_hasLoaded) {
      await loadInitial();
      return;
    }
    if (_markingAll) {
      _refreshAfterMarkAll = true;
      return;
    }
    if (_refreshing) {
      _refreshQueued = true;
      return;
    }

    _refreshing = true;
    try {
      do {
        _refreshQueued = false;
        final generation = _generation;
        try {
          final response = await _repository.getNotifications(page: 1);
          if (generation != _generation) return;
          _mergeFirstPage(response);
          _notify();
        } on NotificationFailure catch (e) {
          if (userInitiated && generation == _generation) {
            _toastError(e.message);
          }
        }
      } while (_refreshQueued);
    } finally {
      _refreshing = false;
    }
  }

  Future<void> onPushReceived() async {
    if (!_active) return;

    final before = _unreadCount;
    await refresh();
    if (_disposed || !_active) return;

    if (_unreadCount <= before) {
      await Future<void>.delayed(_pushRetryDelay);
      if (_disposed || !_active) return;
      await refresh();
    }
  }

  Future<void> loadMore() async {
    if (!_active || _loading || _loadingMore || !hasMore) return;

    final generation = _generation;
    _loadingMore = true;
    _loadMoreFailed = false;
    _notify();

    final page = _items.length ~/ kNotificationPageSize + 1;

    try {
      final response = await _repository.getNotifications(page: page);
      if (generation != _generation) return;

      final known = <String>{for (final n in _items) n.id};
      final fresh = response.notifications
          .where((n) => !known.contains(n.id) && !_busy.contains(n.id))
          .toList();

      if (fresh.isEmpty) {
        _total = _items.length;
      } else {
        _items = <AppNotification>[..._items, ...fresh];
        _total = math.max(response.total, _items.length);
      }
      if (_busy.isEmpty && !_markingAll) _unreadCount = response.unreadCount;
    } on NotificationFailure {
      if (generation != _generation) return;
      _loadMoreFailed = true;
    }

    _loadingMore = false;
    _notify();
  }

  // ---------------------------------------------------------------------------
  // Actions (optimistic)
  // ---------------------------------------------------------------------------

  Future<void> markAsRead(String id) async {
    final index = _indexOf(id);
    if (index < 0 || _items[index].isRead || _busy.contains(id)) return;

    final generation = _generation;
    final original = _items[index];

    _busy.add(id);
    _items = _replaced(index, original.withRead(true));
    _unreadCount = math.max(0, _unreadCount - 1);
    _notify();

    try {
      final updated = await _repository.markAsRead(id);
      if (generation != _generation) return;

      final i = _indexOf(id);
      if (i >= 0 && updated != null && updated.isRead) {
        _items = _replaced(i, updated);
      }
    } on NotificationFailure catch (e) {
      if (generation != _generation) return;

      final i = _indexOf(id);
      if (e.isNotFound) {
        if (i >= 0) {
          _items = _without(i);
          _total = math.max(0, _total - 1);
        }
      } else {
        if (i >= 0) _items = _replaced(i, original);
        _unreadCount += 1;
        _toastError(e.message);
      }
    } finally {
      _busy.remove(id);
      _notify();
    }
  }

  Future<void> markAllAsRead() async {
    if (_markingAll) return;
    final unreadIds = <String>{
      for (final n in _items)
        if (!n.isRead) n.id,
    };
    if (unreadIds.isEmpty && _unreadCount == 0) return;

    final generation = _generation;
    final previousUnread = _unreadCount;

    _markingAll = true;
    _items = <AppNotification>[
      for (final n in _items) n.isRead ? n : n.withRead(true),
    ];
    _unreadCount = 0;
    _notify();

    try {
      final serverUnread = await _repository.markAllAsRead();
      if (generation != _generation) return;
      _unreadCount = serverUnread ?? 0;
    } on NotificationFailure catch (e) {
      if (generation != _generation) return;

      _items = <AppNotification>[
        for (final n in _items)
          unreadIds.contains(n.id) ? n.withRead(false) : n,
      ];
      _unreadCount = previousUnread;
      _toastError(e.message);
    } finally {
      if (generation == _generation) {
        _markingAll = false;
        _notify();
        if (_refreshAfterMarkAll) {
          _refreshAfterMarkAll = false;
          unawaited(refresh());
        }
      }
    }
  }

  Future<void> delete(String id) async {
    final index = _indexOf(id);
    if (index < 0 || _busy.contains(id)) return;

    final generation = _generation;
    final removed = _items[index];

    _busy.add(id);
    _items = _without(index);
    if (!removed.isRead) _unreadCount = math.max(0, _unreadCount - 1);
    _total = math.max(0, _total - 1);
    _notify();

    try {
      await _repository.deleteNotification(id);
    } on NotificationFailure catch (e) {
      if (generation == _generation) {
        // Put it back where it was.
        final at = math.min(index, _items.length);
        _items = <AppNotification>[..._items]..insert(at, removed);
        if (!removed.isRead) _unreadCount += 1;
        _total += 1;
        _toastError(e.message);
      }
    } finally {
      _busy.remove(id);
      _notify();
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  void _mergeFirstPage(NotificationListResponse response) {
    final fetched = response.notifications
        .where((n) => !_busy.contains(n.id))
        .toList();

    final known = <String>{for (final n in _items) n.id};
    final noOverlap =
        _items.isNotEmpty &&
            fetched.isNotEmpty &&
            !fetched.any((n) => known.contains(n.id));

    if (noOverlap) {
      _items = _unique(fetched);
    } else {
      final byId = <String, AppNotification>{
        for (final n in _items) n.id: n,
      };
      for (final n in fetched) {
        byId[n.id] = n;
      }
      _items = byId.values.toList()..sort(_newestFirst);
    }

    if (_busy.isEmpty && !_markingAll) _unreadCount = response.unreadCount;
    _total = math.max(response.total, _items.length);
  }

  static int _newestFirst(AppNotification a, AppNotification b) {
    final at = a.createdAt;
    final bt = b.createdAt;
    if (at != null && bt != null) {
      final byDate = bt.compareTo(at);
      if (byDate != 0) return byDate;
    } else if (at == null && bt != null) {
      return 1;
    } else if (at != null && bt == null) {
      return -1;
    }
    return b.id.compareTo(a.id);
  }

  List<AppNotification> _unique(List<AppNotification> list) {
    final byId = <String, AppNotification>{};
    for (final n in list) {
      byId.putIfAbsent(n.id, () => n);
    }
    return byId.values.toList();
  }

  int _indexOf(String id) => _items.indexWhere((n) => n.id == id);

  List<AppNotification> _replaced(int index, AppNotification value) {
    final next = List<AppNotification>.of(_items);
    next[index] = value;
    return next;
  }

  List<AppNotification> _without(int index) {
    final next = List<AppNotification>.of(_items);
    next.removeAt(index);
    return next;
  }

  void _toastError(String message) {
    AppToast.showToast(message, backgroundColor: Colors.red);
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