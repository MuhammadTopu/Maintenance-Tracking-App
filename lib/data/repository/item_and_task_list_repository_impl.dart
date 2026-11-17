// PLACE AT: lib/data/repository/item_and_task_list_repository_impl.dart
// (replaces the existing file; getAllItemsList / getOneItem are unchanged)

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:maintenance_genie/data/models/all_item_list_model.dart';
import 'package:maintenance_genie/data/models/one_item_model.dart';
import 'package:maintenance_genie/data/models/task_list_response_model.dart';
import 'package:maintenance_genie/shared/app_toast.dart';

import '../../core/constants/api_end_points.dart';
import '../../core/helper/logger.dart';
import '../../core/services/api/api_service.dart';
import '../../domain/repository/item_and_task_list_repository.dart';

class ItemAndTaskListRepositoryImpl implements ItemAndTaskListRepository {
  final ApiService _apiService;

  ItemAndTaskListRepositoryImpl(this._apiService);

  String _extractServerMessage(
      DioException e, {
        String fallback = "Unauthorized: Please Login Again.",
      }) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
      if (message is Map<String, dynamic>) {
        final nested = message['message'];
        if (nested is String && nested.trim().isNotEmpty) {
          return nested;
        }
      }
    }
    return fallback;
  }

  /// User-facing message for a failed task request. Unlike
  /// [_extractServerMessage] it never claims "Unauthorized" for a timeout or a
  /// 500.
  String _taskErrorMessage(DioException e) {
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
    return _extractServerMessage(
      e,
      fallback: 'Something went wrong. Please try again.',
    );
  }

  @override
  Future<AllItemListModel?> getAllItemsList() async {
    try {
      final response = await _apiService.get(ApiEndPoints.getAllItem);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data['success'] == true) {
          return AllItemListModel.fromJson(response.data);
        }
      }
      return null;
    } on DioException catch (e) {
      // A user with no items gets 404 "No items found for this user". That is
      // an empty list, not a failure, so the screen shows "No assets yet".
      final isNoItems =
          e.response?.statusCode == 404 &&
              _extractServerMessage(e, fallback: '').toLowerCase().contains(
                'no items',
              );
      if (isNoItems) {
        return AllItemListModel(
          success: true,
          message: 'No items found',
          items: <Item>[],
        );
      }
      // Other failures: the screen shows its generic error state.
      return null;
    } catch (e) {
      Log.error("Error in fetching all items : $e");
      throw Exception(e);
    }
  }

  @override
  Future<OneItemModel?> getOneItem({required String itemId}) async {
    try {
      final response = await _apiService.get(ApiEndPoints.getOneItem(itemId));

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data['success'] == true) {
          return OneItemModel.fromJson(response.data);
        }
      }
      return null;
    } on DioException catch (e) {
      String serverMessage = '';
      if (e.type == DioExceptionType.connectionError) {
        serverMessage = "Something went wrong!!! Check internet connection";
      } else {
        serverMessage = _extractServerMessage(e);
      }
      AppToast.showToast(serverMessage, backgroundColor: Colors.red);
      return null;
    } catch (e) {
      Log.error("Error in fetching one item : $e");
      throw Exception(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Tasks
  // ---------------------------------------------------------------------------

  @override
  Future<TaskListResponse?> getAllTasksList({
    TaskFilter filter = TaskFilter.all,
    int page = 1,
    int limit = kTaskPageSize,
  }) {
    return _fetchTaskPage(
      ApiEndPoints.getAllTaskList(filter: filter.apiValue, page: page, limit: limit),
      'all tasks (${filter.apiValue}, page $page)',
    );
  }

  @override
  Future<TaskListResponse?> getTaskListByItemId({
    required String itemId,
    TaskFilter filter = TaskFilter.all,
    int page = 1,
    int limit = kTaskPageSize,
  }) {
    return _fetchTaskPage(
      ApiEndPoints.getAllTaskListByItemId(
        itemId,
        filter: filter.apiValue,
        page: page,
        limit: limit,
      ),
      'tasks of item $itemId (${filter.apiValue}, page $page)',
    );
  }

  Future<TaskListResponse?> _fetchTaskPage(String url, String label) async {
    try {
      final response = await _apiService.get(url);
      final data = response.data;
      final ok = response.statusCode == 200 || response.statusCode == 201;

      if (ok && data is Map && data['success'] == true) {
        return TaskListResponse.fromJson(Map<String, dynamic>.from(data));
      }
      return null;
    } on DioException catch (e) {
      Log.error('Error fetching $label : ${e.message}');
      AppToast.showToast(_taskErrorMessage(e), backgroundColor: Colors.red);
      return null;
    } catch (e) {
      // Malformed payload etc. Never crash the screen over it.
      Log.error('Error parsing $label : $e');
      AppToast.showToast(
        'Something went wrong. Please try again.',
        backgroundColor: Colors.red,
      );
      return null;
    }
  }

  @override
  Future<TaskResponse?> toggleTaskStatus({required String taskId}) async {
    try {
      // PATCH with no body – the backend flips Complete <-> not complete and
      // returns the full updated task.
      final response = await _apiService.patch(
        ApiEndPoints.toggleTaskStatus(taskId),
      );
      final data = response.data;

      if (response.statusCode == 200 &&
          data is Map &&
          data['success'] == true &&
          data['task'] is Map) {
        return TaskResponse.fromJson(
          Map<String, dynamic>.from(data['task'] as Map),
        );
      }
      AppToast.showToast(
        'Could not update the task. Please try again.',
        backgroundColor: Colors.red,
      );
      return null;
    } on DioException catch (e) {
      Log.error('Error toggling task $taskId : ${e.message}');
      AppToast.showToast(_taskErrorMessage(e), backgroundColor: Colors.red);
      return null;
    } catch (e) {
      Log.error('Error parsing toggle response for $taskId : $e');
      AppToast.showToast(
        'Something went wrong. Please try again.',
        backgroundColor: Colors.red,
      );
      return null;
    }
  }
}