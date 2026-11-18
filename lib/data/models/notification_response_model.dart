import 'dart:convert';

const int kNotificationPageSize = 20;

enum NotificationType {
  login('login'),
  welcome('welcome'),
  itemAdded('item_added'),
  tasksCreated('tasks_created'),
  taskReminder('task_reminder'),
  premiumActivated('premium_activated'),
  premiumRenewed('premium_renewed'),
  premiumCancelled('premium_cancelled'),
  premiumPaymentIssue('premium_payment_issue'),
  premiumExpired('premium_expired'),
  premiumRefunded('premium_refunded'),
  reportUpdate('report_update'),
  system('system'),
  unknown('');

  const NotificationType(this.apiValue);

  final String apiValue;

  static NotificationType fromApi(String? value) {
    final key = value?.trim().toLowerCase();
    if (key == null || key.isEmpty) return NotificationType.unknown;
    for (final type in NotificationType.values) {
      if (type.apiValue == key) return type;
    }
    return NotificationType.unknown;
  }
}

// -----------------------------------------------------------------------------
// Small parsing helpers
// -----------------------------------------------------------------------------

String? _string(Object? value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

DateTime? _date(Object? value) {
  final text = _string(value);
  return text == null ? null : DateTime.tryParse(text);
}

int _int(Object? value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

Map<String, dynamic> decodeNotificationData(Object? raw) {
  if (raw is Map) return Map<String, dynamic>.from(raw);
  if (raw is String && raw.trim().isNotEmpty) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {
      // Not JSON: treat as "no extra data".
    }
  }
  return const <String, dynamic>{};
}

({String? itemId, String? taskId}) _resolveIds(
    NotificationType type,
    String? entityId,
    Map<String, dynamic> data,
    ) {
  final itemId =
      _string(data['itemId']) ??
          _string(data['item_id']) ??
          (type == NotificationType.itemAdded ||
              type == NotificationType.tasksCreated
              ? entityId
              : null);

  final taskId =
      _string(data['taskId']) ??
          _string(data['task_id']) ??
          (type == NotificationType.taskReminder ? entityId : null);

  return (itemId: itemId, taskId: taskId);
}

// -----------------------------------------------------------------------------
// One notification
// -----------------------------------------------------------------------------

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    this.entityId,
    this.itemId,
    this.taskId,
    this.data = const <String, dynamic>{},
    this.readAt,
    this.createdAt,
  });

  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final bool isRead;
  final String? entityId;
  final String? itemId;
  final String? taskId;

  final Map<String, dynamic> data;
  final DateTime? readAt;
  final DateTime? createdAt;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final type = NotificationType.fromApi(_string(json['type']));
    final entityId = _string(json['entity_id']);
    final data = decodeNotificationData(json['data']);
    final ids = _resolveIds(type, entityId, data);

    return AppNotification(
      id: _string(json['id']) ?? '',
      type: type,
      title: _string(json['title']) ?? 'Notification',
      body: _string(json['body']) ?? '',
      isRead: json['is_read'] == true,
      entityId: entityId,
      itemId: ids.itemId,
      taskId: ids.taskId,
      data: data,
      readAt: _date(json['read_at']),
      createdAt: _date(json['created_at']),
    );
  }

  AppNotification withRead(bool read, {DateTime? readAt}) {
    return AppNotification(
      id: id,
      type: type,
      title: title,
      body: body,
      isRead: read,
      entityId: entityId,
      itemId: itemId,
      taskId: taskId,
      data: data,
      readAt: read ? (readAt ?? this.readAt ?? DateTime.now().toUtc()) : null,
      createdAt: createdAt,
    );
  }
}

// -----------------------------------------------------------------------------
// Where a tap should go
// -----------------------------------------------------------------------------

class NotificationTarget {
  const NotificationTarget({required this.type, this.itemId, this.taskId});

  final NotificationType type;
  final String? itemId;
  final String? taskId;

  bool get opensTask =>
      type == NotificationType.taskReminder && itemId != null && taskId != null;

  factory NotificationTarget.fromPush(Map<String, dynamic> payload) {
    final type = NotificationType.fromApi(_string(payload['type']));
    final entityId = _string(payload['entityId'] ?? payload['entity_id']);
    final data = decodeNotificationData(payload['data']);
    final ids = _resolveIds(type, entityId, data);
    return NotificationTarget(
      type: type,
      itemId: ids.itemId,
      taskId: ids.taskId,
    );
  }

  factory NotificationTarget.fromNotification(AppNotification notification) {
    return NotificationTarget(
      type: notification.type,
      itemId: notification.itemId,
      taskId: notification.taskId,
    );
  }
}

// -----------------------------------------------------------------------------
// GET /notifications
// -----------------------------------------------------------------------------

class NotificationListResponse {
  const NotificationListResponse({
    required this.notifications,
    required this.unreadCount,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  final List<AppNotification> notifications;

  final int unreadCount;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  bool get hasNextPage => page < totalPages;

  factory NotificationListResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['notifications'];
    final items = <AppNotification>[
      if (raw is List)
        for (final entry in raw)
          if (entry is Map)
            AppNotification.fromJson(Map<String, dynamic>.from(entry)),
    ].where((n) => n.id.isNotEmpty).toList();

    return NotificationListResponse(
      notifications: items,
      unreadCount: _int(json['unreadCount']),
      page: _int(json['page'], 1),
      limit: _int(json['limit'], kNotificationPageSize),
      total: _int(json['total'], items.length),
      totalPages: _int(json['totalPages'], 1),
    );
  }
}

int? parseUnreadCount(Object? value) {
  if (value == null) return null;
  return _int(value, -1) < 0 ? null : _int(value);
}