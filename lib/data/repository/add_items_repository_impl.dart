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
import '../../domain/base_repository/add_items_repository.dart';
import '../../shared/app_toast.dart';
import '../models/question_response_model.dart';
import '../models/task_list_response_model.dart';

class AddItemRepositoryImpl implements AddItemRepository {
  final ApiService _apiService;

  AddItemRepositoryImpl(this._apiService);

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

  @override
  Future<String?> addItem({
    required String name,
    required String brand,
    required String model,
    required String category,
    required String purchaseDate,
    required int? totalMileage,
    required String yearOfModel,
    File? imageFile,
    String? engine,
    String? transmission,
    String? drivetrain,
    int? currentMileage,
    int? averageMileagePerYear,
    String? userNotes,
  }) async {
    final token = await TokenStorageService.instance.getToken();
    if (token == null) return null;

    final request = http.MultipartRequest(
      'POST',
      Uri.parse(ApiEndPoints.addItem),
    );

    request.headers['Authorization'] = 'Bearer $token';

    request.fields['name'] = name;
    request.fields['brand'] = brand;
    request.fields['model'] = model;
    request.fields['category'] = category;
    request.fields['purchase_date'] = purchaseDate;
    request.fields['year_of_the_model'] = yearOfModel;

    if (totalMileage != null) {
      request.fields['total_mileage'] = totalMileage.toString();
    }

    if (engine != null && engine.isNotEmpty) {
      request.fields['engine'] = engine;
    }
    if (transmission != null && transmission.isNotEmpty) {
      request.fields['transmission'] = transmission;
    }
    if (drivetrain != null && drivetrain.isNotEmpty) {
      request.fields['drivetrain'] = drivetrain;
    }
    if (currentMileage != null) {
      request.fields['current_mileage'] = currentMileage.toString();
    }
    if (averageMileagePerYear != null) {
      request.fields['average_mileage_per_year'] = averageMileagePerYear.toString();
    }
    if (userNotes != null && userNotes.isNotEmpty) {
      request.fields['user_notes'] = userNotes;
    }

    if (imageFile != null) {
      final mimeType = lookupMimeType(imageFile.path);
      final fileName = path.basename(imageFile.path);

      request.files.add(
        await http.MultipartFile.fromPath(
          'img',
          imageFile.path,
          filename: fileName,
          contentType: mimeType != null ? MediaType.parse(mimeType) : null,
        ),
      );
    }

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    Log.debug('STATUS CODE: ${response.statusCode}');
    Log.debug('RESPONSE BODY: $responseBody');
    Log.debug('REASON PHRASE: ${response.reasonPhrase}');

    final isSuccess = response.statusCode >= 200 && response.statusCode < 300;

    Map<String, dynamic>? decoded;
    try {
      decoded = jsonDecode(responseBody) as Map<String, dynamic>;
    } catch (e) {
      Log.error('Failed to decode addItem response: $e');
      decoded = null;
    }

    if (!isSuccess) {
      final message = decoded?['message'] as String? ?? 'Something went wrong';
      AppToast.showToast(message, backgroundColor: Colors.red);
      return null;
    }

    final itemId = decoded?['item']?['id'] as String?;

    if (itemId == null) {
      Log.error('addItem succeeded but response had no item.id: $responseBody');
      AppToast.showToast('Item added, but something looked off. Please refresh.', backgroundColor: Colors.orange);
      return null;
    }

    AppToast.showToast(decoded?['message'] as String? ?? 'Item added successfully');
    return itemId;
  }

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
  Future<GenerateTaskResponse?> answerQuestions({
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
        if (response.data['tasks'] != null) {
          return GenerateTaskResponse.fromJson(response.data);
        }
        AppToast.showToast('No tasks found.', backgroundColor: Colors.orange);
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
}