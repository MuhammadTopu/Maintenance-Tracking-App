abstract class AuthRepository {
  // Future<bool> register({
  //   required String firstName,
  //   required String lastName,
  //   required String email,
  //   required String password,
  //   required bool acceptTermsAndPolicy,
  // });
  Future<bool> login({required String email, required String password});
  // Future<bool> forgetPassword({required String email});
  // Future<bool> resendCode({required String email});
  // Future<bool> verifyOtp({required String email, required String otp});
  // Future<bool> resetPassword({required String password});
}
