import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:maintenance_genie/core/helper/logger.dart';
import 'package:maintenance_genie/core/services/storage/token_storage_service.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path;
import '../../core/constants/api_end_points.dart';
import '../../core/services/api/api_service.dart';
import '../../domain/repository/add_items_repository.dart';
import '../../domain/entities/add_item_data.dart';
import '../../shared/app_toast.dart';
import '../models/question_response_model.dart';

class AddItemRepositoryImpl implements AddItemRepository {
  final ApiService _apiService;

  AddItemRepositoryImpl(this._apiService);

  static const Duration _addItemTimeout = Duration(seconds: 120);

  static const String _genericError = 'Something went wrong. Please try again.';
  static const String _noInternet =
      'Something went wrong!!! Check internet connection';

  String _extractServerMessage(
      DioException e, {
        String fallback = "Something went wrong. Please try again.",
      }) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
    }
    return fallback;
  }

  @override
  Future<List<String>> getModelsByBrand(String brandName) async {
    final url = Uri.parse(
      'https://vpic.nhtsa.dot.gov/api/vehicles/getmodelsformake/$brandName?format=json',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<String> models = [];

      for (var item in data['Results']) {
        models.add(item['Model_Name']);
      }

      models.sort();
      return models;
    }

    return [];
  }

  // ================= ADD ITEM =================

  @override
  Future<String?> addItem(AddItemData data) async {
    final token = await TokenStorageService.instance.getToken();
    if (token == null) {
      _showError('Your session has expired. Please log in again.');
      return null;
    }

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiEndPoints.addItem),
      )
        ..headers['Authorization'] = 'Bearer $token'
        ..fields.addAll(data.toFormFields());

      final image = data.imageFile;
      if (image != null) {
        request.files.add(await _imagePart(image));
      }

      final response = await _send(request).timeout(_addItemTimeout);
      final body = utf8.decode(response.bodyBytes, allowMalformed: true);

      Log.debug('ADD ITEM STATUS: ${response.statusCode}');
      Log.debug('ADD ITEM BODY: $body');

      final decoded = _decodeJsonObject(body);
      final isSuccess =
          response.statusCode >= 200 && response.statusCode < 300;

      if (!isSuccess) {
        _showError(_failureMessage(response.statusCode, decoded, data));
        return null;
      }

      final item = decoded?['item'];
      final itemId = item is Map ? item['id']?.toString() : null;

      if (itemId == null || itemId.isEmpty) {
        Log.error('addItem succeeded but response had no item.id: $body');
        AppToast.showToast(
          'Item added, but something looked off. Please refresh.',
          backgroundColor: Colors.orange,
        );
        return null;
      }

      final message = decoded?['message'];
      AppToast.showToast(
        message is String && message.isNotEmpty
            ? message
            : 'Item added successfully',
      );
      return itemId;
    } on TimeoutException {
      _showError(
        'This is taking longer than expected. Please check your items before trying again.',
      );
      return null;
    } on SocketException {
      _showError(_noInternet);
      return null;
    } on http.ClientException {
      _showError(_noInternet);
      return null;
    } catch (e) {
      Log.error('Error adding item: $e');
      _showError(_genericError);
      return null;
    }
  }

  Future<http.Response> _send(http.MultipartRequest request) async =>
      http.Response.fromStream(await request.send());

  Future<http.MultipartFile> _imagePart(File file) async {
    final mimeType = lookupMimeType(file.path);
    return http.MultipartFile.fromPath(
      'img',
      file.path,
      filename: path.basename(file.path),
      contentType: mimeType != null ? MediaType.parse(mimeType) : null,
    );
  }

  Map<String, dynamic>? _decodeJsonObject(String body) {
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  String _failureMessage(
      int status,
      Map<String, dynamic>? body,
      AddItemData data,
      ) {
    final serverMessage = body?['message'];
    final hasServerMessage =
        serverMessage is String && serverMessage.trim().isNotEmpty;

    switch (status) {
      case 400:
      case 403:
      case 404:
        return hasServerMessage ? serverMessage : _genericError;
      case 401:
        return 'Your session has expired. Please log in again.';
      default:
        if (status >= 500) {
          return data.category == ItemCategory.vehicle
              ? 'We couldn\'t generate the maintenance data for this vehicle. Please try again.'
              : _genericError;
        }
        return hasServerMessage ? serverMessage : _genericError;
    }
  }

  void _showError(String message) =>
      AppToast.showToast(message, backgroundColor: Colors.red);

  // ================= QUESTIONS =================

  @override
  Future<QuestionsResponse?> getQuestion(String id) async {
    try {
      final response = await _apiService.get(ApiEndPoints.getQuestion(id));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return QuestionsResponse.fromJson(response.data);
      }

      AppToast.showToast(
        response.data['message'] ?? 'Failed to load questions',
        backgroundColor: Colors.red,
      );
      return null;
    } on DioException catch (e) {
      final serverMessage = e.type == DioExceptionType.connectionError
          ? "Something went wrong!!! Check internet connection"
          : _extractServerMessage(e);
      AppToast.showToast(serverMessage, backgroundColor: Colors.red);
      return null;
    } catch (e) {
      Log.error("Error fetching question: $e");
      return null;
    }
  }

  @override
  Future<QuestionsResponse?> answerQuestions({
    required String itemId,
    required List<String> answers,
  }) async {
    try {
      final body = {"answers": answers};

      final response = await _apiService.post(
        ApiEndPoints.answerQuestion(itemId),
        data: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data['questions'] != null) {
          return QuestionsResponse.fromJson(response.data);
        }
        AppToast.showToast('No recommendations found.', backgroundColor: Colors.orange);
        return null;
      }

      AppToast.showToast(
        response.data['message'] ?? 'Failed to answer questions',
        backgroundColor: Colors.red,
      );
      return null;
    } on DioException catch (e) {
      final serverMessage = e.type == DioExceptionType.connectionError
          ? "Something went wrong!!! Check internet connection"
          : _extractServerMessage(e);
      AppToast.showToast(serverMessage, backgroundColor: Colors.red);
      return null;
    } catch (e) {
      Log.error("Error answering questions: $e");
      return null;
    }
  }

  @override
  Future<bool> generateTasks({required String itemId}) async {
    try {
      final response = await _apiService.post(
        ApiEndPoints.generateTasks(itemId),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        AppToast.showToast(
          response.data['message'] ?? 'Tasks generated successfully',
          backgroundColor: Colors.green,
        );
        return true;
      }

      AppToast.showToast(
        response.data['message'] ?? 'Failed to generate tasks',
        backgroundColor: Colors.red,
      );
      return false;
    } on DioException catch (e) {
      final serverMessage = e.type == DioExceptionType.connectionError
          ? "Something went wrong!!! Check internet connection"
          : _extractServerMessage(e);
      AppToast.showToast(serverMessage, backgroundColor: Colors.red);
      return false;
    } catch (e) {
      Log.error("Error generating tasks: $e");
      return false;
    }
  }
}