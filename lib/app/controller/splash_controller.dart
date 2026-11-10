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
    final storage = TokenStorageService.instance;

    final accessFuture = storage.getToken();
    final refreshFuture = storage.getRefreshToken();

    await Future.delayed(const Duration(seconds: 2));

    final access = await accessFuture;
    final refresh = await refreshFuture;
    final hasSession =
        (refresh != null && refresh.isNotEmpty) ||
            (access != null && access.isNotEmpty);

    if (hasSession) {
      onNavigateToHome();
      return;
    }

    onShowContent();
    onStayOnSplash();
  }
}