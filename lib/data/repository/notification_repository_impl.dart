import 'package:dio/dio.dart';
import 'package:maintenance_genie/core/constants/api_end_points.dart';
import 'package:maintenance_genie/core/helper/logger.dart';
import 'package:maintenance_genie/core/services/api/api_service.dart';
import 'package:maintenance_genie/data/models/notification_response_model.dart';
import 'package:maintenance_genie/domain/repository/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl(this._apiService);

  final ApiService _apiService;

  // ---------------------------------------------------------------------------
  // Errors
  // ---------------------------------------------------------------------------

  String? _serverMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) return message;
      if (message is Map) {
        final nested = message['message'];
        if (nested is String && nested.trim().isNotEmpty) return nested;
      }
    }
    return null;
  }

  String _messageFor(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionError:
        return 'Check your internet connection and try again.';
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'The request timed out. Please try again.';
      default:
        break;
    }
    final status = e.response?.statusCode ?? 0;
    if (status >= 500) {
      return 'Something went wrong on our side. Please try again.';
    }
    return _serverMessage(e) ?? 'Something went wrong. Please try again.';
  }

  Future<T> _guard<T>(String label, Future<T> Function() run) async {
    try {
      return await run();
    } on NotificationFailure {
      rethrow;
    } on DioException catch (e) {
      Log.error('Notifications – $label failed: ${e.message}');
      throw NotificationFailure(
        _messageFor(e),
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      Log.error('Notifications – $label failed: $e');
      throw const NotificationFailure('Something went wrong. Please try again.');
    }
  }

  bool _isOk(Response<dynamic> response) {
    final code = response.statusCode;
    return code == 200 || code == 201;
  }

  // ---------------------------------------------------------------------------
  // Calls
  // ---------------------------------------------------------------------------

  @override
  Future<NotificationListResponse> getNotifications({
    int page = 1,
    int limit = kNotificationPageSize,
  }) {
    return _guard('load page $page', () async {
      final response = await _apiService.get(
        ApiEndPoints.notifications(
          page: page,
          limit: limit,
        ),
      );
      final data = response.data;

      if (_isOk(response) && data is Map && data['success'] == true) {
        return NotificationListResponse.fromJson(
          Map<String, dynamic>.from(data),
        );
      }
      throw const NotificationFailure(
        'Could not load notifications. Please try again.',
      );
    });
  }

  @override
  Future<AppNotification?> markAsRead(String id) {
    return _guard('mark $id as read', () async {
      final response = await _apiService.patch(
        ApiEndPoints.readNotification(id),
      );
      final data = response.data;

      if (_isOk(response) && data is Map && data['success'] == true) {
        final raw = data['notification'];
        return raw is Map
            ? AppNotification.fromJson(Map<String, dynamic>.from(raw))
            : null;
      }
      throw const NotificationFailure(
        'Could not update the notification. Please try again.',
      );
    });
  }

  @override
  Future<int?> markAllAsRead() {
    return _guard('mark all as read', () async {
      final response = await _apiService.patch(
        ApiEndPoints.readAllNotifications,
      );
      final data = response.data;

      if (_isOk(response) && data is Map && data['success'] == true) {
        return parseUnreadCount(data['unreadCount']);
      }
      throw const NotificationFailure(
        'Could not mark notifications as read. Please try again.',
      );
    });
  }

  @override
  Future<void> deleteNotification(String id) {
    return _guard<void>('delete $id', () async {
      try {
        final response = await _apiService.delete(
          ApiEndPoints.deleteNotification(id),
        );
        final data = response.data;
        final success = data is Map ? data['success'] != false : true;

        if (_isOk(response) && success) return;
        throw const NotificationFailure(
          'Could not delete the notification. Please try again.',
        );
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) return;
        rethrow;
      }
    });
  }
}