import 'package:maintenance_genie/data/models/notification_response_model.dart';

class NotificationFailure implements Exception {
  const NotificationFailure(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  bool get isNotFound => statusCode == 404;

  @override
  String toString() => 'NotificationFailure($statusCode): $message';
}

abstract class NotificationRepository {
  Future<NotificationListResponse> getNotifications({
    int page = 1,
    int limit = kNotificationPageSize,
  });

  Future<AppNotification?> markAsRead(String id);

  Future<int?> markAllAsRead();

  Future<void> deleteNotification(String id);
}