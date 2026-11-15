import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../core/constants/api_end_points.dart';
import '../../core/helper/logger.dart';
import '../../core/services/api/api_service.dart';
import '../../domain/repository/support_mail_repository.dart';
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

  void _handleDioError(DioException e) {
    final msg = e.type == DioExceptionType.connectionError
        ? "Something went wrong!!! Check internet connection"
        : _extractServerMessage(e);
    AppToast.showToast(msg, backgroundColor: Colors.red);
  }

  @override
  Future<String?> sendSupportMail({
    required String subject,
    required String message,
  }) async {
    try {
      final body = {"subject": subject, "message": message};
      final response =
      await _apiService.post(ApiEndPoints.sendMailToAdmin, data: body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data['success'] == true) {
          return response.data['data']['token'];
        }
      }
      return null;
    } on DioException catch (e) {
      _handleDioError(e);
      return null;
    } catch (e) {
      Log.error("Error in sending support mail : $e");
      throw Exception(e);
    }
  }

  @override
  Future<bool> deleteAccount({
    required String password,
    required String reason,
  }) async {
    try {
      final response = await _apiService.post(
        ApiEndPoints.deleteAccount,
        data: {"password": password, "reason": reason},
      );
      return response.statusCode == 200 && response.data['success'] == true;
    } on DioException catch (e) {
      _handleDioError(e);
      return false;
    } catch (e) {
      Log.error("Error deleting account : $e");
      AppToast.showToast("Something went wrong", backgroundColor: Colors.red);
      return false;
    }
  }

  @override
  Future<bool> reportIssue({
    required String type,
    required String subject,
    required String description,
  }) async {
    try {
      final response = await _apiService.post(
        ApiEndPoints.reportIssue,
        data: {
          "type": type,
          "subject": subject,
          "description": description,
        },
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException catch (e) {
      _handleDioError(e);
      return false;
    } catch (e) {
      Log.error("Error reporting issue : $e");
      AppToast.showToast("Something went wrong", backgroundColor: Colors.red);
      return false;
    }
  }
}