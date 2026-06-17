import 'dart:io';

import '../../data/models/user_response_model.dart';

abstract class AuthRepository {

  Future<bool> login({required String email, required String password});
  Future<bool> registerStep1({required String email});
  Future<bool> verifyEmailOtp({required String email, required String otp});
  Future<bool> registerStep3({required String name, required String password});
  Future<bool> forgetPassword({required String email});
  Future<bool> verifyResetPassOtp({required String email, required String otp});
  Future<bool> resetPass({required String password});
  Future<UserResponse?> getUserDetails();
  Future<bool> updateProfileImage(File image);
  Future<bool> updateProfileDetails({
    required String name,
    required String address,
  });
  Future<bool> updatePassword({required String oldPassword, required String newPassword});
}
