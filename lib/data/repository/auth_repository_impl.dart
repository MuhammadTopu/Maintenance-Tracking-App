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

  // @override
  // Future<bool> register({
  //   required String firstName,
  //   required String lastName,
  //   required String email,
  //   required String password,
  //   required bool acceptTermsAndPolicy,
  // }) async {
  //   try {
  //
  //     final String? fcmToken = await SharedPreferenceData.getFcmToken();
  //
  //     final body = {
  //       "first_name": firstName,
  //       "last_name": lastName,
  //       "email": email,
  //       "password": password,
  //       "is_agrred_to_terms_and_policy": acceptTermsAndPolicy,
  //       "fcm_token": fcmToken,
  //     };
  //     final response = await _apiService.post(
  //       ApiEndPoints.register,
  //       data: body,
  //     );
  //
  //     if (response.statusCode == 200 || response.statusCode == 201) {
  //
  //       if (response.data['success'] == false) {
  //         AppUtils.showToast('Something went wrong', backgroundColor: Colors.red);
  //         return false;
  //       }
  //
  //       await TokenStorage().saveToken(response.data['data']['accessToken']);
  //       AppUtils.showToast(
  //         response.data['message'],
  //         backgroundColor: Colors.green,
  //       );
  //       return true;
  //     }
  //     AppUtils.showToast(response.data['message'], backgroundColor: Colors.red);
  //     return false;
  //   } on DioException catch (e) {
  //     final serverMessage =
  //         e.response?.data['message'] ??
  //             "Unauthorized: Please check your credentials.";
  //     AppUtils.showToast(serverMessage, backgroundColor: Colors.red);
  //     return false;
  //   } catch (e) {
  //     debugPrint("Error in sign up : $e");
  //     throw Exception(e);
  //   }
  // }

  @override
  Future<bool> login({required String email, required String password}) async {
    try {
      final body = {"email": email, "password": password};
      final response = await _apiService.post(ApiEndPoints.login, data: body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        await TokenStorageService.instance.saveToken(
          response.data['token'],
        );
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

  // @override
  // Future<bool> forgetPassword({required String email}) async {
  //   try {
  //     final body = {"email": email};
  //     final response = await _apiService.post(
  //       ApiEndPoints.forgetPassword,
  //       data: body,
  //     );
  //
  //     if (response.statusCode == 200 || response.statusCode == 201) {
  //       AppUtils.showToast(
  //         response.data['message'],
  //         backgroundColor: Colors.green,
  //       );
  //       return true;
  //     }
  //     AppUtils.showToast(response.data['message'], backgroundColor: Colors.red);
  //     return false;
  //   } on DioException catch (e) {
  //     final serverMessage =
  //         e.response?.data['message']['message'] ??
  //             "Unauthorized: Please check your credentials.";
  //     AppUtils.showToast(serverMessage, backgroundColor: Colors.red);
  //     return false;
  //   } catch (e) {
  //     debugPrint("Error in sending code for forget pass : $e");
  //     throw Exception(e);
  //   }
  // }
  //
  // @override
  // Future<bool> resendCode({required String email}) async {
  //   try {
  //     final body = {"email": email};
  //     final response = await _apiService.post(
  //       ApiEndPoints.resendCode,
  //       data: body,
  //     );
  //
  //     if (response.statusCode == 200 || response.statusCode == 201) {
  //       AppUtils.showToast(
  //         response.data['message'],
  //         backgroundColor: Colors.green,
  //       );
  //       return true;
  //     }
  //     AppUtils.showToast(response.data['message'], backgroundColor: Colors.red);
  //     return false;
  //   } on DioException catch (e) {
  //     final serverMessage =
  //         e.response?.data['message']['message'] ??
  //             "Unauthorized: Please check your credentials.";
  //     AppUtils.showToast(serverMessage, backgroundColor: Colors.red);
  //     return false;
  //   } catch (e) {
  //     debugPrint("Error in resending code for forget pass : $e");
  //     throw Exception(e);
  //   }
  // }
  //
  // @override
  // Future<bool> verifyOtp({required String email, required String otp}) async {
  //   try {
  //     final body = {
  //       "email": email,
  //       "otp": otp
  //     };
  //     final response = await _apiService.post(
  //       ApiEndPoints.verifyOtp,
  //       data: body,
  //     );
  //
  //     if (response.statusCode == 200 || response.statusCode == 201) {
  //       if (response.data['success'] == true) {
  //         await TokenStorage().saveToken(
  //           response.data['token'],
  //         );
  //       }
  //       AppUtils.showToast(
  //         response.data['message'],
  //         backgroundColor: Colors.green,
  //       );
  //       return true;
  //     }
  //     AppUtils.showToast(response.data['message'], backgroundColor: Colors.red);
  //     return false;
  //   } on DioException catch (e) {
  //     final serverMessage =
  //         e.response?.data['message']['message'] ??
  //             "Unauthorized: Please check your credentials.";
  //     AppUtils.showToast(serverMessage, backgroundColor: Colors.red);
  //     return false;
  //   } catch (e) {
  //     debugPrint("Error in verify otp : $e");
  //     throw Exception(e);
  //   }
  // }
  //
  // @override
  // Future<bool> resetPassword({required String password}) async {
  //   try {
  //     final body = {"password": password};
  //     final response = await _apiService.post(
  //       ApiEndPoints.resetPassword,
  //       data: body,
  //     );
  //
  //     if (response.statusCode == 200 || response.statusCode == 201) {
  //       AppUtils.showToast(
  //         response.data['data']['message'],
  //         backgroundColor: Colors.green,
  //       );
  //       return true;
  //     }
  //     AppUtils.showToast(response.data['data']['message'], backgroundColor: Colors.red);
  //     return false;
  //   } on DioException catch (e) {
  //     final serverMessage =
  //         e.response?.data['message']['message'] ??
  //             "Unauthorized: Please check your credentials.";
  //     AppUtils.showToast(serverMessage, backgroundColor: Colors.red);
  //     return false;
  //   } catch (e) {
  //     debugPrint("Error in reset password : $e");
  //     throw Exception(e);
  //   }
  // }
}
