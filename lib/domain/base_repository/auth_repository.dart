abstract class AuthRepository {

  Future<bool> login({required String email, required String password});
  Future<bool> registerStep1({required String email});
  Future<bool> verifyEmailOtp({required String email, required String otp});
  Future<bool> registerStep3({required String name, required String password});
  Future<bool> forgetPassword({required String email});
  Future<bool> verifyResetPassOtp({required String email, required String otp});
  Future<bool> resetPass({required String password});
}
