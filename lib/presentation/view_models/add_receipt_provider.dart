import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:maintenance_genie/core/services/storage/token_storage_service.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;

import '../../core/constants/api_end_points.dart';

class AddReceiptProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _message = '';
  String get message => _message;

  File? imageFile;
  final ImagePicker _picker = ImagePicker();

  File? get getImageFile => imageFile;

  Future<bool> pickImage(ImageSource source, String taskId) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        imageFile = File(pickedFile.path);
        debugPrint('Image picked in AddItemProvider:');
        debugPrint('Image Path: ${pickedFile.path}');
        debugPrint('Image Name: ${path.basename(pickedFile.path)}');
        debugPrint('File exists: ${imageFile!.existsSync()}');
        final result = await addReceipt(taskId);
        debugPrint('Message: $_message');
        notifyListeners();
        return result;
      } else {
        debugPrint('No image selected in AddItemProvider.');
        _message = 'No image selected.';
        imageFile = null;
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('Error picking image in AddItemProvider: $e');
      imageFile = null;
      notifyListeners();
      return false;
    }
  }

  Future<bool> addReceipt(String taskId) async {
    _isLoading = true;
    notifyListeners();
    final url = Uri.parse(ApiEndPoints.addReceiptByTaskId(taskId));

    try {
      final accessToken = await TokenStorageService.instance.getToken();
      if (accessToken == null) {
        debugPrint('Access token not found. Cannot add item.');
        _message = 'Access token not found. Cannot add item.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Bearer $accessToken';

      if (imageFile != null) {
        String? mimeType = lookupMimeType(imageFile!.path);
        String filename = path.basename(imageFile!.path);

        request.files.add(
          await http.MultipartFile.fromPath(
            'img',
            imageFile!.path,
            filename: filename,
            contentType: mimeType != null ? MediaType.parse(mimeType) : null,
          ),
        );
      } else {
        debugPrint('No image selected to upload.');
      }

      final response = await request.send();
      final responseBody =
      await response.stream.bytesToString(); // Read response body

      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('Item added successfully. Status: ${response.statusCode}');
        debugPrint('Response Body: $responseBody');
        _message = 'Receipt uploaded and maintenance history will be updated soon.';
        notifyListeners();
        imageFile = null;
        _isLoading = false;
        notifyListeners();
        return true;
      }
      else if (response.statusCode == 400 || response.statusCode == 401) {
        _message = 'Could not extract readable data. Please try another receipt.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      else {
        debugPrint('Failed to add item. Status: ${response.statusCode}');
        debugPrint('Request URL: ${request.url}');
        debugPrint('Request Headers: ${request.headers}');
        debugPrint('Request Fields: ${request.fields}');
        debugPrint(
          'Response Body: $responseBody',
        );
        _isLoading = false;
        _message = 'Failed to add receipt. Please try again.';
        notifyListeners();
        return false;
      }
    } catch (error) {
      debugPrint('Error adding receipt: $error');
      _message = 'Failed to add receipt. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}