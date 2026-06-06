import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:maintenance_genie/core/helper/logger.dart';
import 'package:maintenance_genie/core/services/storage/token_storage_service.dart';
import '../../core/constants/api_end_points.dart';
import '../../core/services/api/api_service.dart';
import '../../domain/base_repository/auth_repository.dart';
import '../../shared/app_toast.dart';

class AuthRepositoriesImpl implements AuthRepository {
  final ApiService _apiService;

  AuthRepositoriesImpl(this._apiService);

  @override
  Future<bool> login({required String email, required String password}) async {
    try {
      final body = {"email": email, "password": password};
      final response = await _apiService.post(ApiEndPoints.login, data: body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        await TokenStorageService.instance.saveToken(response.data['token']);
        AppToast.showToast(
          response.data['message'],
          backgroundColor: Colors.green,
        );
        return true;
      }
      AppToast.showToast(response.data['message'], backgroundColor: Colors.red);
      return false;
    } on DioException catch (e) {
      final serverMessage =
          e.response?.data['message']['message'] ??
          "Unauthorized: Please check your credentials.";
      AppToast.showToast(serverMessage, backgroundColor: Colors.red);
      return false;
    } catch (e) {
      Log.error("Error in sign in : $e");
      throw Exception(e);
    }
  }

  @override
  Future<bool> registerStep1({required String email}) async {
    try {
      final body = {"email": email};
      final response = await _apiService.post(
        ApiEndPoints.register1,
        data: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        AppToast.showToast(
          response.data['message'],
          backgroundColor: Colors.green,
        );
        return true;
      }
      AppToast.showToast(response.data['message'], backgroundColor: Colors.red);
      return false;
    } on DioException catch (e) {
      final serverMessage =
          e.response?.data['message'] ??
          "Unauthorized: Please check your credentials.";
      AppToast.showToast(serverMessage, backgroundColor: Colors.red);
      return false;
    } catch (e) {
      Log.error("Error in sign up step 1 : $e");
      throw Exception(e);
    }
  }

  @override
  Future<bool> verifyEmailOtp({required String email, required String otp}) async {
    try {
      final body = {"email": email, "otp": otp};
      final response = await _apiService.post(
        ApiEndPoints.verifyOtp,
        data: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data['success'] == true) {await TokenStorageService.instance.saveToken(response.data['token']);}
        AppToast.showToast(response.data['message'], backgroundColor: Colors.green,);
        return true;
      }
      AppToast.showToast(response.data['message'], backgroundColor: Colors.red);
      return false;
    } on DioException catch (e) {
      final serverMessage = e.response?.data['message'] ?? "Unauthorized: Please check your credentials.";
      AppToast.showToast(serverMessage, backgroundColor: Colors.red);
      return false;
    } catch (e) {
      Log.error("Error in verify otp : $e");
      throw Exception(e);
    }
  }

  @override
  Future<bool> registerStep3({required String name, required String password}) async {
    try {
      final body = {"name": name, "password": password};
      final response = await _apiService.post(
        ApiEndPoints.register3,
        data: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        AppToast.showToast(response.data['message'], backgroundColor: Colors.green,);
        return true;
      }
      AppToast.showToast(response.data['message'], backgroundColor: Colors.red);
      return false;
    } on DioException catch (e) {
      final serverMessage = e.response?.data['message'] ?? "Unauthorized: Please check your credentials.";
      AppToast.showToast(serverMessage, backgroundColor: Colors.red);
      return false;
    } catch (e) {
      Log.error("Error in register step 3 : $e");
      throw Exception(e);
    }
  }

  @override
  Future<bool> forgetPassword({required String email}) async {
    try {
      final body = {"email": email};
      final response = await _apiService.post(
        ApiEndPoints.forgetPassword,
        data: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        AppToast.showToast(response.data['message'], backgroundColor: Colors.green,);
        return true;
      }
      AppToast.showToast(response.data['message'], backgroundColor: Colors.red);
      return false;
    } on DioException catch (e) {
      final serverMessage = e.response?.data['message'] ?? "Unauthorized: Please check your credentials.";
      AppToast.showToast(serverMessage, backgroundColor: Colors.red);
      return false;
    } catch (e) {
      Log.error("Error in sending code for forget pass : $e");
      throw Exception(e);
    }
  }

  @override
  Future<bool> verifyResetPassOtp({required String email, required String otp}) async {
    try {
      final body = {"email": email, "otp": otp};
      final response = await _apiService.post(
        ApiEndPoints.resetPasswordOtp,
        data: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data['success'] == true) {await TokenStorageService.instance.saveToken(response.data['token']);}
        AppToast.showToast(response.data['message'], backgroundColor: Colors.green,);
        return true;
      }
      AppToast.showToast(response.data['message'], backgroundColor: Colors.red);
      return false;
    } on DioException catch (e) {
      final serverMessage = e.response?.data['message'] ?? "Unauthorized: Please check your credentials.";
      AppToast.showToast(serverMessage, backgroundColor: Colors.red);
      return false;
    } catch (e) {
      Log.error("Error in verify reset pass otp : $e");
      throw Exception(e);
    }
  }

  @override
  Future<bool> resetPass({required String password}) async {
    try {
      final body = {"newPassword": password};
      final response = await _apiService.post(
        ApiEndPoints.resetPassword,
        data: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        AppToast.showToast(response.data['message'], backgroundColor: Colors.green,);
        return true;
      }
      AppToast.showToast(response.data['message'], backgroundColor: Colors.red);
      return false;
    } on DioException catch (e) {
      final serverMessage = e.response?.data['message'] ?? "Unauthorized: Please check your credentials.";
      AppToast.showToast(serverMessage, backgroundColor: Colors.red);
      return false;
    } catch (e) {
      Log.error("Error in reset pass : $e");
      throw Exception(e);
    }
  }

}
