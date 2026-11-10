import 'dart:async';

import 'package:flutter/material.dart';
import 'package:maintenance_genie/core/services/storage/token_storage_service.dart';

import '../../core/helper/logger.dart';
import '../../core/services/navigation_service.dart';
import '../../core/services/notification/notification_service.dart';
import '../../shared/app_toast.dart';
import '../routes/route_names.dart';
import 'auth_event_controller.dart';

class AuthSessionHandler {
  AuthSessionHandler._();
  static final AuthSessionHandler instance = AuthSessionHandler._();

  StreamSubscription<AuthEvent>? _sub;
  bool _handling = false;

  void init() {
    _sub ??= AuthEventController.instance.stream.listen((event) {
      if (event == AuthEvent.sessionExpired) _onSessionExpired();
    });
  }

  Future<void> _onSessionExpired() async {
    if (_handling) return;
    _handling = true;
    try {
      await TokenStorageService.instance.clearAll();
      try {
        await NotificationService.instance.clearFcmToken();
      } catch (e) {
        Log.error('Error clearing FCM token on session end: $e');
      }

      AppToast.showToast(
        'Session expired. Please log in again.',
        backgroundColor: Colors.red,
      );

      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        RouteName.login,
            (route) => false,
      );
    } finally {
      _handling = false;
    }
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
  }
}