import 'package:flutter/material.dart';

import '../../domain/base_repository/support_mail_repository.dart';

class SupportMailProvider extends ChangeNotifier {
  final SupportMailRepository _repository;

  SupportMailProvider(this._repository);

  bool _isLoading = false;
  String _error = '';
  String _supportMailToken = '';

  bool get isLoading => _isLoading;
  String get error => _error;
  String get supportMailToken => _supportMailToken;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<bool> sendSupportMail(String subject, String message) async {
    _setLoading(true);
    _error = '';

    try {
      final token = await _repository.sendSupportMail(
        subject: subject,
        message: message,
      );

      if (token != null) {
        _supportMailToken = token;
        _setLoading(false);
        return true;
      }

      _error = 'Failed to send support mail';
      _setLoading(false);
      return false;
    } catch (e) {
      _error = 'Something went wrong';
      _setLoading(false);
      return false;
    }
  }
}