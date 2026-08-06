import 'package:flutter/material.dart';

import '../../domain/base_repository/add_items_repository.dart';
import '../../data/models/question_response_model.dart';

class QuestionProvider extends ChangeNotifier {
  final AddItemRepository _repository;

  QuestionProvider(this._repository);

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

  bool _taskGenerating = false;
  bool get taskGenerating => _taskGenerating;

  String _error = '';
  String get message => _error;

  String _qItemId = '';
  String get qItemId => _qItemId;

  QuestionsResponse? _questionResponse;
  QuestionsResponse? get questionResponse => _questionResponse;

  QuestionsResponse? _answeredResponse;
  QuestionsResponse? get answeredResponse => _answeredResponse;

  Future<void> setQId(String id) async {
    _qItemId = id;
    notifyListeners();
    await getQuestion(id);
  }

  Future<void> getQuestion(String id) async {
    _loading = true;
    _error = '';
    notifyListeners();

    final result = await _repository.getQuestion(id);

    if (result != null) {
      _questionResponse = result;
    } else {
      _error = 'Failed to load questions';
    }

    _loading = false;
    notifyListeners();
  }

  Future<bool> answerQuestions(List<String> answers) async {
    _ploading = true;
    _error = '';
    notifyListeners();

    final result = await _repository.answerQuestions(
      itemId: _qItemId,
      answers: answers,
    );

    if (result != null) {
      _answeredResponse = result;
    } else {
      _error = 'Failed to answer questions';
    }

    _ploading = false;
    notifyListeners();

    return result != null;
  }

  Future<bool> generateTasks() async {
    _taskGenerating = true;
    _error = '';
    notifyListeners();

    final success = await _repository.generateTasks(itemId: _qItemId);

    if (!success) {
      _error = 'Failed to generate tasks';
    }

    _taskGenerating = false;
    notifyListeners();

    return success;
  }
}