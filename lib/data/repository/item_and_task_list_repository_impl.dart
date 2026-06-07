import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:maintenance_genie/data/models/all_item_list_model.dart';
import 'package:maintenance_genie/data/models/one_item_model.dart';
import 'package:maintenance_genie/data/models/task_list_response_model.dart';
import 'package:maintenance_genie/shared/app_toast.dart';

import '../../core/constants/api_end_points.dart';
import '../../core/helper/logger.dart';
import '../../core/services/api/api_service.dart';
import '../../domain/base_repository/item_and_task_list_repository.dart';

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
      String serverMessage = '';
      if (e.type == DioExceptionType.connectionError) {
        serverMessage = "Something went wrong!!! Check internet connection";
      } else {
        serverMessage = _extractServerMessage(e);
      }
      AppToast.showToast(serverMessage, backgroundColor: Colors.red);
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

  @override
  Future<TaskListResponse?> getAllTasksList() async {
    try {
      final response = await _apiService.get(ApiEndPoints.getAllTaskList);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data['success'] == true) {
          return TaskListResponse.fromJson(response.data);
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
      Log.error("Error in fetching all tasks : $e");
      throw Exception(e);
    }
  }

  @override
  Future<TaskListResponse?> getTaskListByItemId({
    required String itemId,
  }) async {
    try {
      final response = await _apiService.get(
        ApiEndPoints.getAllTaskListByItemId(itemId),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return TaskListResponse.fromJson(response.data);
      }

      return null;
    } on DioException catch (e) {
      AppToast.showToast(_extractServerMessage(e), backgroundColor: Colors.red);
      return null;
    }
  }

  @override
  Future<bool> toggleTaskStatus({required String taskId}) async {
    try {
      final response = await _apiService.patch(
        ApiEndPoints.toggleTaskStatus(taskId),
      );

      return response.statusCode == 200;
    } on DioException catch (e) {
      AppToast.showToast(_extractServerMessage(e), backgroundColor: Colors.red);

      return false;
    }
  }
}
