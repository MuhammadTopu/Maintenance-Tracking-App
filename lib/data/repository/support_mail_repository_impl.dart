import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../core/constants/api_end_points.dart';
import '../../core/helper/logger.dart';
import '../../core/services/api/api_service.dart';
import '../../domain/base_repository/support_mail_repository.dart';
import '../../shared/app_toast.dart';

class SupportMailRepositoryImpl implements SupportMailRepository {
  final ApiService _apiService;

  SupportMailRepositoryImpl(this._apiService);

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
  Future<String?> sendSupportMail({
    required String subject,
    required String message,
  }) async {
    try {
      final response = await _apiService.get(ApiEndPoints.getAllItem);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data['success'] == true) {
          return response.data['data']['token'];
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
}
