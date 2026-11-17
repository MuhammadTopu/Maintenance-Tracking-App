const int kTaskPageSize = 20;

String _text(Object? value) {
  if (value == null) return '';
  return value is String ? value.trim() : value.toString().trim();
}

DateTime? _date(Object? value) {
  if (value is! String) return null;
  return DateTime.tryParse(value);
}

bool _bool(Object? value) => value is bool ? value : false;

int _int(Object? value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(_text(value)) ?? fallback;
}

enum TaskStatus {
  overdue('Overdue', 'Overdue'),
  dueNow('Due Now', 'DueNow'),
  upcoming('Upcoming', 'Upcoming'),
  future('Future', 'Future'),
  complete('Completed', 'Complete'),
  unknown('Unknown', '');

  const TaskStatus(this.label, this.apiValue);

  final String label;

  final String apiValue;

  bool get isComplete => this == TaskStatus.complete;

  static TaskStatus fromApi(String? raw) {
    final key = (raw ?? '').toLowerCase().replaceAll(RegExp(r'[\s_\-]'), '');
    switch (key) {
      case 'overdue':
        return TaskStatus.overdue;
      case 'duenow':
        return TaskStatus.dueNow;
      case 'upcoming':
        return TaskStatus.upcoming;
      case 'future':
        return TaskStatus.future;
      case 'complete':
      case 'completed':
        return TaskStatus.complete;
      default:
        return TaskStatus.unknown;
    }
  }
}

enum TaskFilter {
  all('All', 'all'),
  overdue('Overdue', 'overdue'),
  dueNow('Due Now', 'duenow'),
  upcoming('Upcoming', 'upcoming'),
  future('Future', 'future'),
  completed('Completed', 'completed');

  const TaskFilter(this.label, this.apiValue);

  final String label;
  final String apiValue;

  bool matches(TaskStatus status) => switch (this) {
    TaskFilter.all => true,
    TaskFilter.overdue => status == TaskStatus.overdue,
    TaskFilter.dueNow => status == TaskStatus.dueNow,
    TaskFilter.upcoming => status == TaskStatus.upcoming,
    TaskFilter.future => status == TaskStatus.future,
    TaskFilter.completed => status == TaskStatus.complete,
  };
}

class TaskCounts {
  const TaskCounts({
    this.all = 0,
    this.overdue = 0,
    this.dueNow = 0,
    this.upcoming = 0,
    this.future = 0,
    this.completed = 0,
  });

  static const TaskCounts empty = TaskCounts();

  final int all;
  final int overdue;
  final int dueNow;
  final int upcoming;
  final int future;
  final int completed;

  factory TaskCounts.fromJson(Map<String, dynamic>? json) {
    if (json == null) return empty;
    return TaskCounts(
      all: _int(json['all']),
      overdue: _int(json['overdue']),
      dueNow: _int(json['duenow'] ?? json['dueNow']),
      upcoming: _int(json['upcoming']),
      future: _int(json['future']),
      completed: _int(json['completed']),
    );
  }

  int of(TaskFilter filter) => switch (filter) {
    TaskFilter.all => all,
    TaskFilter.overdue => overdue,
    TaskFilter.dueNow => dueNow,
    TaskFilter.upcoming => upcoming,
    TaskFilter.future => future,
    TaskFilter.completed => completed,
  };

  TaskCounts afterStatusChange({
    required TaskStatus from,
    required TaskStatus to,
  }) {
    if (from == to) return this;
    int adjust(TaskStatus status, int value) {
      var next = value;
      if (status == from) next -= 1;
      if (status == to) next += 1;
      return next < 0 ? 0 : next;
    }

    return TaskCounts(
      all: all,
      overdue: adjust(TaskStatus.overdue, overdue),
      dueNow: adjust(TaskStatus.dueNow, dueNow),
      upcoming: adjust(TaskStatus.upcoming, upcoming),
      future: adjust(TaskStatus.future, future),
      completed: adjust(TaskStatus.complete, completed),
    );
  }
}

class ShopSuggestion {
  const ShopSuggestion({
    required this.name,
    this.description = '',
    this.googleMapUrl = '',
    this.aiSuggested = false,
  });

  final String name;
  final String description;
  final String googleMapUrl;
  final bool aiSuggested;

  factory ShopSuggestion.fromJson(Map<String, dynamic> json) {
    return ShopSuggestion(
      name: _text(json['name']),
      description: _text(json['description']),
      googleMapUrl: _text(json['google_map_url']),
      aiSuggested: _bool(json['ai_suggested']),
    );
  }

  String get mapUrl {
    if (googleMapUrl.isNotEmpty) return googleMapUrl;
    return 'https://www.google.com/maps/search/?api=1&query='
        '${Uri.encodeQueryComponent(name)}';
  }
}

class TaskResponse {
  const TaskResponse({
    required this.id,
    required this.itemId,
    required this.userId,
    required this.upcomingTask,
    required this.itemName,
    required this.description,
    required this.category,
    required this.recommendedInterval,
    required this.lastServiceAssumption,
    required this.nextDueMileage,
    required this.nextDueDate,
    required this.priority,
    required this.manufacturerIntervalUncertain,
    required this.status,
    required this.maintenanceHistory,
    required this.shopSuggestions,
    this.createdAt,
    this.itemLastServiceDate,
    this.receiptUrl,
    this.lastDate,
    this.dueAt,
    this.remindedAt,
  });

  final String id;
  final DateTime? createdAt;
  final String itemId;
  final String userId;
  final String upcomingTask;
  final String itemName;
  final String description;
  final String category;
  final String recommendedInterval;
  final String lastServiceAssumption;
  final String nextDueMileage;
  final String nextDueDate;
  final String priority;
  final bool manufacturerIntervalUncertain;
  final DateTime? itemLastServiceDate;
  final String? receiptUrl;
  final TaskStatus status;
  final DateTime? lastDate;
  final DateTime? dueAt;
  final DateTime? remindedAt;
  final List<String> maintenanceHistory;
  final List<ShopSuggestion> shopSuggestions;

  bool get isComplete => status.isComplete;
  bool get hasReceipt => receiptUrl != null && receiptUrl!.isNotEmpty;

  factory TaskResponse.fromJson(Map<String, dynamic> json) {
    final receipt = _text(json['receipt_url']);
    return TaskResponse(
      id: _text(json['id']),
      createdAt: _date(json['created_at']),
      itemId: _text(json['item_id']),
      userId: _text(json['user_id']),
      upcomingTask: _text(json['upcoming_task']),
      itemName: _text(json['item_name']),
      description: _text(json['description']),
      category: _text(json['category']),
      recommendedInterval: _text(json['recommended_interval']),
      lastServiceAssumption: _text(json['last_service_assumption']),
      nextDueMileage: _text(json['next_due_mileage']),
      nextDueDate: _text(json['next_due_date']),
      priority: _text(json['priority']),
      manufacturerIntervalUncertain: _bool(
        json['manufacturer_interval_uncertain'],
      ),
      itemLastServiceDate: _date(json['item_last_service_date']),
      receiptUrl: receipt.isEmpty ? null : receipt,
      status: TaskStatus.fromApi(_text(json['status'])),
      lastDate: _date(json['last_date']),
      dueAt: _date(json['due_at']),
      remindedAt: _date(json['reminded_at']),
      maintenanceHistory: _history(json['maintenance_history']),
      shopSuggestions: _shops(json['shop_suggestions']),
    );
  }

  static List<String> _history(Object? raw) {
    if (raw is! List) return const <String>[];
    return raw.map(_historyLine).where((line) => line.isNotEmpty).toList();
  }

  static String _historyLine(Object? entry) {
    if (entry == null) return '';
    if (entry is String) return entry.trim();
    if (entry is Map) {
      return entry.values
          .where((v) => v != null && v is! Map && v is! List)
          .map((v) => v.toString().trim())
          .where((s) => s.isNotEmpty)
          .join(' · ');
    }
    return entry.toString().trim();
  }

  static List<ShopSuggestion> _shops(Object? raw) {
    if (raw is! List) return const <ShopSuggestion>[];
    return <ShopSuggestion>[
      for (final e in raw)
        if (e is Map) ShopSuggestion.fromJson(Map<String, dynamic>.from(e)),
    ].where((s) => s.name.isNotEmpty).toList();
  }

  static int compareByUrgency(TaskResponse a, TaskResponse b) {
    final byStatus = a.status.index.compareTo(b.status.index);
    if (byStatus != 0) return byStatus;
    final ad = a.dueAt;
    final bd = b.dueAt;
    if (ad != null && bd != null) {
      final byDue = ad.compareTo(bd);
      if (byDue != 0) return byDue;
    } else if (ad != null) {
      return -1;
    } else if (bd != null) {
      return 1;
    }
    return a.upcomingTask.toLowerCase().compareTo(b.upcomingTask.toLowerCase());
  }

  static int compareByCompletion(TaskResponse a, TaskResponse b) {
    final ad = a.lastDate;
    final bd = b.lastDate;
    if (ad != null && bd != null) return bd.compareTo(ad);
    if (ad != null) return -1;
    if (bd != null) return 1;
    return a.upcomingTask.toLowerCase().compareTo(b.upcomingTask.toLowerCase());
  }
}

class TaskListResponse {
  const TaskListResponse({
    required this.success,
    required this.message,
    required this.tasks,
    this.filter = 'all',
    this.page = 1,
    this.limit = kTaskPageSize,
    this.total = 0,
    this.totalPages = 1,
    this.hasNextPage = false,
    this.hasPreviousPage = false,
    this.counts = TaskCounts.empty,
  });

  final bool success;
  final String message;
  final List<TaskResponse> tasks;
  final String filter;
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPreviousPage;
  final TaskCounts counts;

  factory TaskListResponse.fromJson(Map<String, dynamic> json) {
    final rawTasks = json['tasks'];
    final tasks = <TaskResponse>[
      if (rawTasks is List)
        for (final e in rawTasks)
          if (e is Map) TaskResponse.fromJson(Map<String, dynamic>.from(e)),
    ];
    final page = _int(json['page'], 1);
    final totalPages = _int(json['totalPages'], 1);
    final rawCounts = json['counts'];

    return TaskListResponse(
      success: json['success'] == true,
      message: _text(json['message']),
      tasks: tasks,
      filter: _text(json['filter']),
      page: page,
      limit: _int(json['limit'], kTaskPageSize),
      total: _int(json['total'], tasks.length),
      totalPages: totalPages,
      hasNextPage: json['hasNextPage'] is bool
          ? json['hasNextPage'] as bool
          : page < totalPages,
      hasPreviousPage: json['hasPreviousPage'] is bool
          ? json['hasPreviousPage'] as bool
          : page > 1,
      counts: TaskCounts.fromJson(
        rawCounts is Map ? Map<String, dynamic>.from(rawCounts) : null,
      ),
    );
  }
}