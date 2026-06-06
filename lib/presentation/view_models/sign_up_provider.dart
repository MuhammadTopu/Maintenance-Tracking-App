import 'package:flutter/material.dart';

import '../../domain/base_repository/auth_repository.dart';
import '../../shared/app_toast.dart';

class SignUpProvider extends ChangeNotifier {
  final AuthRepository _repository;

  SignUpProvider(this._repository);

  bool _isLoading = false;
  bool _isChecked = false;
  String _email = '';

  bool get isLoading => _isLoading;
  bool get isChecked => _isChecked;
  String get email => _email;

  void toggleCheck(bool val) {
    _isChecked = val;
    notifyListeners();
  }

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void setEmail(String value) {
    _email = value;
    notifyListeners();
  }

  Future<bool> register1({
    required String email,
  }) async {

    if (_isChecked == false) {
      AppToast.showToast("Please accept terms and conditions", backgroundColor: Colors.red);
      return false;
    }

    setLoading(true);
    final result = await _repository.registerStep1(email: email);
    setLoading(false);
    setEmail(email);
    return result;
  }

  Future<bool> register2({
    required String otp,
  }) async {
    setLoading(true);
    final result = await _repository.verifyEmailOtp(email: email, otp: otp);
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

  Future<bool> register3({
    required String name,
    required String password
  }) async {
    setLoading(true);
    final result = await _repository.registerStep3(name: name, password: password);
    setLoading(false);
    return result;
  }

}