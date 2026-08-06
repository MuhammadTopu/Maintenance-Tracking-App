import 'package:flutter/material.dart';

import '../../domain/base_repository/add_items_repository.dart';
import '../../data/models/question_response_model.dart';
import '../../data/models/task_list_response_model.dart';

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

  String _error = '';
  String get message => _error;

  String _qItemId = '';
  String get qItemId => _qItemId;

  QuestionsResponse? _questionResponse;
  QuestionsResponse? get questionResponse => _questionResponse;

  GenerateTaskResponse? _generateTaskResponse;
  GenerateTaskResponse? get generateTaskResponse => _generateTaskResponse;

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

  Future<void> answerQuestions(List<String> ans) async {
    _ploading = true;
    _error = '';
    notifyListeners();

    final result = await _repository.answerQuestions(
      itemId: _qItemId,
      answers: ans,
    );

    if (result != null) {
      _generateTaskResponse = result;
    } else {
      _error = 'Failed to answer questions';
    }

    _ploading = false;
    notifyListeners();
  }
}