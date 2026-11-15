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
import '../models/guided_answer_model.dart';
import '../models/guided_question_model.dart';
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

  /// Vehicle. `GET /items/:id/questions`.
  @override
  Future<QuestionsResponse?> getQuestion(String id) {
    return _call<QuestionsResponse>(
      label: 'getQuestion',
      failureMessage: 'Failed to load questions',
      request: () => _apiService.post(ApiEndPoints.getQuestion(id)),
      parse: QuestionsResponse.fromJson,
    );
  }

  /// Vehicle. Answers are Yes / No / Planned, one per question and in the order
  /// the questions were returned.
  @override
  Future<QuestionsResponse?> answerQuestions({
    required String itemId,
    required List<String> answers,
  }) {
    return _call<QuestionsResponse>(
      label: 'answerQuestions',
      failureMessage: 'Failed to answer questions',
      request: () => _apiService.post(
        ApiEndPoints.answerQuestion(itemId),
        data: {'answers': answers},
      ),
      parse: (json) {
        if (json['questions'] == null) {
          AppToast.showToast(
            'No recommendations found.',
            backgroundColor: Colors.orange,
          );
          return null;
        }
        return QuestionsResponse.fromJson(json);
      },
    );
  }

  /// Home and Other. `GET /items/:id/questions`.
  @override
  Future<GuidedQuestionsResponse?> getGuidedQuestions(String itemId) {
    return _call<GuidedQuestionsResponse>(
      label: 'getGuidedQuestions',
      failureMessage: 'Failed to load questions',
      request: () => _apiService.post(ApiEndPoints.getQuestion(itemId)),
      parse: GuidedQuestionsResponse.fromJson,
    );
  }

  /// Home and Other. Body: `{"answers": [{question_id, answer | skipped}]}`.
  @override
  Future<GuidedQuestionsResponse?> submitGuidedAnswers({
    required String itemId,
    required List<GuidedAnswer> answers,
  }) {
    return _call<GuidedQuestionsResponse>(
      label: 'submitGuidedAnswers',
      failureMessage: 'Failed to submit answers',
      request: () => _apiService.post(
        ApiEndPoints.answerQuestion(itemId),
        data: {
          'answers': [for (final answer in answers) answer.toJson()],
        },
      ),
      parse: GuidedQuestionsResponse.fromJson,
    );
  }

  @override
  Future<bool> generateTasks({required String itemId}) async {
    final done = await _call<bool>(
      label: 'generateTasks',
      failureMessage: 'Failed to generate tasks',
      request: () => _apiService.post(ApiEndPoints.generateTasks(itemId)),
      parse: (json) {
        final message = json['message'];
        AppToast.showToast(
          message is String && message.isNotEmpty
              ? message
              : 'Tasks generated successfully',
          backgroundColor: Colors.green,
        );
        return true;
      },
    );
    return done ?? false;
  }

  // ================= SHARED REQUEST HANDLING =================

  /// Runs [request], parses a 200/201 JSON object with [parse] and turns every
  /// failure into one toast for the user, then `null`. A 403 with
  /// `premiumRequired: true` carries its own message ("Upgrade to Premium…").
  Future<T?> _call<T>({
    required String label,
    required String failureMessage,
    required Future<Response<dynamic>> Function() request,
    required T? Function(Map<String, dynamic> json) parse,
  }) async {
    try {
      final response = await request();
      final json = _asJsonMap(response.data);
      final status = response.statusCode;

      if ((status == 200 || status == 201) && json != null) {
        return parse(json);
      }

      final message = json?['message'];
      _showError(
        message is String && message.trim().isNotEmpty
            ? message
            : failureMessage,
      );
      return null;
    } on DioException catch (e) {
      _showError(_dioMessage(e));
      return null;
    } catch (e) {
      Log.error('$label failed: $e');
      return null;
    }
  }

  Map<String, dynamic>? _asJsonMap(dynamic data) =>
      data is Map ? Map<String, dynamic>.from(data) : null;

  String _dioMessage(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionError:
        return _noInternet;
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'The request timed out. Please try again.';
      default:
        return _extractServerMessage(e);
    }
  }
}