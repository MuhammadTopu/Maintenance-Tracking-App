import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:maintenance_genie/core/services/storage/token_storage_service.dart';

import '../../core/constants/api_end_points.dart';
import '../../data/models/question_response_model.dart';
import '../../data/models/task_list_response_model.dart';

class QuestionProvider extends ChangeNotifier {

  bool _isGenerateLoading = false;
  bool get isGenerateLoading => _isGenerateLoading;

  void setIsGenerateLoading(bool value) {
    _isGenerateLoading = value;
    notifyListeners();
  }

  bool _loading = false;
  bool get isLoading => _loading;

  bool _ploading = false;
  bool get postLoading => _ploading;

  String _error = '';
  String get message => _error;

  String _qItemId = '';
  String get qItemId => _qItemId;

  Future<void> setQId(String id) async {
    _qItemId = id;
    notifyListeners();
    await getQuestion(id);
  }

  QuestionsResponse? _questionResponse;
  QuestionsResponse? get questionResponse => _questionResponse;

  GenerateTaskResponse? _generateTaskResponse;
  GenerateTaskResponse? get generateTaskResponse => _generateTaskResponse;

  Future<void> getQuestion(String id) async {
    final url = Uri.parse(ApiEndPoints.getQuestion(id));
    try {
      _loading = true;
      _error = '';
      notifyListeners();

      final token = await TokenStorageService.instance.getToken();
      if (token == null) {
        _error = 'No authentication token found';
        debugPrint(_error);
        _loading = false;
        notifyListeners();
        return;
      }
      debugPrint('Token: $token');

      final response = await http
          .get(url, headers: {'Authorization': 'Bearer $token'})
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        _questionResponse = QuestionsResponse.fromJson(jsonResponse);
        debugPrint('Response Body: ${response.body}');
      } else {
        _error =
        'Failed to load questions: ${response.statusCode} - ${response.reasonPhrase}';
        debugPrint(_error);
      }
    } catch (error) {
      _error = 'Error fetching questions: $error';
      debugPrint(_error);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> answerQuestions(List<String> ans) async {
    final url = Uri.parse(ApiEndPoints.answerQuestion(_qItemId));
    debugPrint('URL: $url');
    debugPrint('Answers: $ans');

    try {
      _ploading = true;
      _error = '';
      notifyListeners();

      final data = {
        "answers": ans, // Passing the list of answers
      };

      final token = await TokenStorageService.instance.getToken();
      if (token == null) {
        _error = 'No authentication token found';
        debugPrint(_error);
        _ploading = false;
        notifyListeners();
        return;
      }

      final response = await http
          .post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json', // Important: Set content-type to JSON
        },
        body: jsonEncode(data), // This encodes the entire body as a JSON string
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        debugPrint('Response Body: ${response.body}');
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        // Check if the 'tasks' key exists and contains a valid list
        if (jsonResponse['tasks'] != null) {
          _generateTaskResponse = GenerateTaskResponse.fromJson(jsonResponse);
        } else {
          // Handle the case when there are no tasks
          _error = "No tasks found.";
          debugPrint(_error);
        }
      } else {
        _error = 'Failed to answer questions: ${response.statusCode} - ${response.reasonPhrase}';
        debugPrint(_error);
      }
    } catch (error) {
      _error = 'Failed to answer questions. error: $error';
      debugPrint(_error);
    } finally {
      _ploading = false;
      notifyListeners();
    }
    debugPrint('Generate Task Body: $_generateTaskResponse');
  }
}
