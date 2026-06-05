import 'package:flutter/material.dart';
import '../../domain/base_repository/auth_repository.dart';

class LoginProvider extends ChangeNotifier {
  final AuthRepository _repository;
  LoginProvider(this._repository);

  bool _isPasswordVisible = true;
  bool _isLoading = false;

  bool get isPasswordVisible => _isPasswordVisible;
  bool get isLoading => _isLoading;

  void togglePasswordVisibility() {
    _isPasswordVisible = !_isPasswordVisible;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    setLoading(true);
    final result = await _repository.login(email: email, password: password);
    setLoading(false);
    return result;
  }
}