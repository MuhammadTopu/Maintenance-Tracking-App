import 'package:flutter/material.dart';

import '../../domain/base_repository/auth_repository.dart';

class ForgetPassProvider extends ChangeNotifier {
  final AuthRepository _repository;

  ForgetPassProvider(this._repository);

  bool _isLoading = false;
  String _email = '';

  bool get isLoading => _isLoading;
  String get email => _email;

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void setEmail(String value) {
    _email = value;
    notifyListeners();
  }

  Future<bool> forgetPass({
    required String email,
  }) async {
    setLoading(true);
    final result = await _repository.forgetPassword(email: email);
    setLoading(false);
    setEmail(email);
    return result;
  }

  Future<bool> verifyResetPassOtp({
    required String otp,
  }) async {
    setLoading(true);
    final result = await _repository.verifyResetPassOtp(email: email, otp: otp);
    setLoading(false);
    return result;
  }

  bool _hasMinLength = false;
  bool _hasUpperAndLower = false;
  bool _hasNumber = false;
  bool _hasSymbol = false;

  bool get hasMinLength => _hasMinLength;
  bool get hasUpperAndLower => _hasUpperAndLower;
  bool get hasNumber => _hasNumber;
  bool get hasSymbol => _hasSymbol;

  bool get isPasswordValid =>
      _hasMinLength &&
          _hasUpperAndLower &&
          _hasNumber &&
          _hasSymbol;


  void validatePassword(String password) {
    _hasMinLength = password.length >= 8;

    _hasUpperAndLower =
        RegExp(r'(?=.*[a-z])(?=.*[A-Z])').hasMatch(password);

    _hasNumber =
        RegExp(r'(?=.*[0-9])').hasMatch(password);

    _hasSymbol =
        RegExp(r'(?=.*[!@#$%^&*(),.?":{}|<>])').hasMatch(password);

    notifyListeners();
  }

  Future<bool> resetPass({
    required String password
  }) async {
    setLoading(true);
    final result = await _repository.resetPass(password: password);
    setLoading(false);
    return result;
  }
}