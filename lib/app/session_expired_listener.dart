// lib/app/session_expired_listener.dart
import 'dart:async';
import 'package:flutter/material.dart';

import 'package:maintenance_genie/core/services/storage/token_storage_service.dart';
import '../app/routes/route_names.dart';
import '../core/services/navigation_service.dart';
import 'controller/auth_event_controller.dart';

/// Wrap your app's root (below MaterialApp's navigator) with this widget.
/// It listens globally for session-expired events and reacts exactly once.
class SessionExpiredListener extends StatefulWidget {
  final Widget child;
  const SessionExpiredListener({super.key, required this.child});

  @override
  State<SessionExpiredListener> createState() => _SessionExpiredListenerState();
}

class _SessionExpiredListenerState extends State<SessionExpiredListener> {
  StreamSubscription<AuthEvent>? _sub;
  bool _isHandlingExpiry = false;

  @override
  void initState() {
    super.initState();
    _sub = AuthEventController.instance.stream.listen((event) {
      if (event == AuthEvent.sessionExpired) {
        _handleSessionExpired();
      }
    });
  }

  Future<void> _handleSessionExpired() async {
    // Guard: if 3 parallel API calls all 401 at once, only handle the first.
    if (_isHandlingExpiry) return;
    _isHandlingExpiry = true;

    // Clear the dead token immediately so no further requests use it.
    await TokenStorageService.instance.clearToken();

    final ctx = navigatorKeyContext;
    if (ctx == null) {
      _isHandlingExpiry = false;
      return;
    }

    await showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Session Expired'),
        content: const Text('Your session has expired. Please log in again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    Navigator.of(ctx).pushNamedAndRemoveUntil(
      RouteName.login,
          (route) => false,
    );

    _isHandlingExpiry = false;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}