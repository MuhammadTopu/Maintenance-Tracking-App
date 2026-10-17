import 'package:flutter/material.dart';
import 'package:maintenance_genie/core/services/storage/token_storage_service.dart';
import '../../core/helper/logger.dart';
import '../../core/services/notification/notification_service.dart';
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
    try {
      final fcmToken = await NotificationService.instance.getTokenForLogin();
      if (fcmToken == null) {
        Log.error("FCM token is null");
        return false;
      }

      return await _repository.login(
        email: email,
        password: password,
        fcmToken: fcmToken,
      );
    } finally {
      setLoading(false);
    }
  }

  Future<void> logOut() async {
    await TokenStorageService.instance.clearToken();
    try {
      await NotificationService.instance.clearFcmToken();
    } catch (e) {
      Log.error("Error clearing FCM token on logout: $e");
    }
  }
}