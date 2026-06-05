import 'package:flutter/material.dart';
import '../../core/services/storage/token_storage_service.dart';

class SplashController {
  final VoidCallback onShowContent;
  final VoidCallback onNavigateToHome;
  final VoidCallback onStayOnSplash;

  SplashController({
    required this.onShowContent,
    required this.onNavigateToHome,
    required this.onStayOnSplash,
  });

  Future<void> init() async {
    bool hasToken = false;

    final tokenFuture = TokenStorageService.instance.getToken();

    await Future.delayed(const Duration(seconds: 2));

    final token = await tokenFuture;
    hasToken = token != null && token.isNotEmpty;

    if (hasToken) {
      onNavigateToHome();
      return;
    }

    onShowContent();
    onStayOnSplash();
  }
}