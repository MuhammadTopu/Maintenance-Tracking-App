import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:maintenance_genie/core/constants/api_end_points.dart';
import 'package:maintenance_genie/core/helper/logger.dart';
import 'package:maintenance_genie/core/services/storage/token_storage_service.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;

class AddReceiptProvider extends ChangeNotifier {
  static const Duration _timeout = Duration(seconds: 60);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _message = '';

  String get message => _message;

  File? _pendingFile;

  File? get pendingFile => _pendingFile;

  bool _disposed = false;

  Future<bool> uploadReceipt({
    required String taskId,
    required File file,
  }) async {
    if (_isLoading) return false;

    _isLoading = true;
    _pendingFile = file;
    _message = '';
    _notify();

    try {
      final token = await TokenStorageService.instance.getToken();
      if (token == null || token.isEmpty) {
        _message = 'Your session has expired. Please log in again.';
        return false;
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiEndPoints.addReceiptByTaskId(taskId)),
      )..headers['Authorization'] = 'Bearer $token';

      final mimeType = lookupMimeType(file.path);
      request.files.add(
        await http.MultipartFile.fromPath(
          'img',
          file.path,
          filename: path.basename(file.path),
          contentType: mimeType == null ? null : MediaType.parse(mimeType),
        ),
      );

      final streamed = await request.send().timeout(_timeout);
      final body = await streamed.stream.bytesToString();
      final status = streamed.statusCode;

      if (status >= 200 && status < 300) {
        _message =
        'Receipt uploaded and maintenance history will be updated soon.';
        return true;
      }

      Log.error('Receipt upload failed ($status): $body');
      _message = _messageFor(status, body);
      return false;
    } on TimeoutException {
      _message = 'The upload timed out. Please try again.';
      return false;
    } on SocketException {
      _message = 'No internet connection. Please try again.';
      return false;
    } catch (e) {
      Log.error('Error adding receipt: $e');
      _message = 'Failed to add receipt. Please try again.';
      return false;
    } finally {
      _isLoading = false;
      _pendingFile = null;
      _notify();
    }
  }

  String _messageFor(int status, String body) {
    final server = _serverMessage(body);
    switch (status) {
      case 400:
      case 422:
        return server ??
            'Could not extract readable data. Please try another receipt.';
      case 401:
        return 'Your session has expired. Please log in again.';
      case 403:
        return server ?? 'Receipts can only be uploaded by premium users.';
      case 413:
        return 'This image is too large. Please choose a smaller one.';
      default:
        return 'Failed to add receipt. Please try again.';
    }
  }

  String? _serverMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        final message = decoded['message'];
        if (message is String && message.trim().isNotEmpty) return message;
      }
    } catch (_) {
      // Not JSON – fall back to the generic message.
    }
    return null;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}