import 'dart:collection';

import 'package:flutter/material.dart';

import '../../data/models/guided_answer_model.dart';
import '../../data/models/guided_question_model.dart';
import '../../data/models/question_response_model.dart';
import '../../domain/entities/add_item_data.dart';
import '../../domain/repository/add_items_repository.dart';

/// State of the question flow that follows "add item" for premium users.
///
/// There are two flows, chosen by the item's category:
///  * **Vehicle**: one batch of Yes / No / Planned questions. Submitting returns
///    recommendations ([questionResponse] → [answeredResponse]).
///  * **Home and Other** ("guided"): typed questions in rounds. Each submit
///    returns the next round. The flow is over when a round comes back with no
///    questions ([guidedFinished]). No recommendations; the answers are kept in
///    [answeredQuestions] for the review screen.
///
/// This provider lives for the whole app, so [reset] / [start] clear everything
/// from the previous flow first.
class QuestionProvider extends ChangeNotifier {
  QuestionProvider(this._repository);

  final AddItemRepository _repository;

  /// The server decides when the rounds end (`questions: []`). This is only a
  /// guard so a misbehaving server can never keep the user answering forever.
  static const int _safetyMaxRounds = 5;

  // ================= SHARED STATE =================

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

  String _category = ItemCategory.vehicle;
  String get category => _category;

  /// Home and Other (and anything that is not a Vehicle) use the guided flow.
  bool get isGuidedFlow => _category != ItemCategory.vehicle;

  // ================= VEHICLE STATE =================

  QuestionsResponse? _questionResponse;
  QuestionsResponse? get questionResponse => _questionResponse;

  QuestionsResponse? _answeredResponse;
  QuestionsResponse? get answeredResponse => _answeredResponse;

  // ================= GUIDED (HOME / OTHER) STATE =================

  int _round = 1;
  int get round => _round;

  bool _guidedLoaded = false;

  /// True once the first questions were fetched successfully.
  bool get guidedLoaded => _guidedLoaded;

  List<GuidedQuestion> _pending = const [];

  /// Questions waiting for an answer in the current round.
  List<GuidedQuestion> get pendingQuestions => UnmodifiableListView(_pending);

  final List<AnsweredQuestion> _answered = [];

  /// Every question answered or skipped so far, across rounds, in order.
  List<AnsweredQuestion> get answeredQuestions =>
      UnmodifiableListView(_answered);

  /// No question is left to ask. Go to the review screen.
  bool get guidedFinished => _guidedLoaded && _pending.isEmpty;

  // ================= LIFECYCLE =================

  /// Clears everything. Call before starting a new flow.
  void reset() {
    _clearFlow();
    _isGenerateLoading = false;
    notifyListeners();
  }

  void _clearFlow() {
    _loading = false;
    _ploading = false;
    _taskGenerating = false;
    _error = '';
    _qItemId = '';
    _category = ItemCategory.vehicle;
    _questionResponse = null;
    _answeredResponse = null;
    _round = 1;
    _guidedLoaded = false;
    _pending = const [];
    _answered.clear();
  }

  /// Starts the flow for a saved item and loads its first questions.
  Future<void> start({
    required String itemId,
    required String category,
  }) async {
    _clearFlow();
    _qItemId = itemId;
    _category = category;
    notifyListeners();

    if (isGuidedFlow) {
      await _loadGuidedQuestions(itemId);
    } else {
      await getQuestion(itemId);
    }
  }

  /// Kept for existing callers. Vehicle only; use [start] for a category.
  Future<void> setQId(String id) =>
      start(itemId: id, category: ItemCategory.vehicle);

  // ================= VEHICLE =================

  Future<void> getQuestion(String id) async {
    _loading = true;
    _error = '';
    notifyListeners();

    final result = await _repository.getQuestion(id);

    // The flow was reset or restarted while this request was running.
    if (_qItemId != id) return;

    if (result != null) {
      _questionResponse = result;
    } else {
      _error = 'Failed to load questions';
    }

    _loading = false;
    notifyListeners();
  }

  Future<bool> answerQuestions(List<String> answers) async {
    if (_ploading) return false;

    final itemId = _qItemId;
    _ploading = true;
    _error = '';
    notifyListeners();

    final result = await _repository.answerQuestions(
      itemId: itemId,
      answers: answers,
    );

    if (_qItemId != itemId) return false;

    if (result != null) {
      _answeredResponse = result;
    } else {
      _error = 'Failed to answer questions';
    }

    _ploading = false;
    notifyListeners();

    return result != null;
  }

  // ================= GUIDED (HOME / OTHER) =================

  Future<void> _loadGuidedQuestions(String itemId) async {
    _loading = true;
    _error = '';
    notifyListeners();

    final result = await _repository.getGuidedQuestions(itemId);

    if (_qItemId != itemId) return;

    if (result != null) {
      _ingest(result);
      _guidedLoaded = true;
    } else {
      _error = 'Failed to load questions';
    }

    _loading = false;
    notifyListeners();
  }

  /// Sends the answers for [pendingQuestions] and moves to the next round.
  ///
  /// Returns `true` if the server accepted them. Check [guidedFinished]
  /// afterwards: `true` means go to the review screen, `false` means
  /// [pendingQuestions] now holds the next round. On failure nothing changes, so
  /// the user can fix the answers or try again.
  Future<bool> submitGuidedAnswers(List<GuidedAnswer> answers) async {
    if (_ploading) return false;

    final itemId = _qItemId;
    final submitted = List<GuidedQuestion>.of(_pending);

    _ploading = true;
    _error = '';
    notifyListeners();

    final result = await _repository.submitGuidedAnswers(
      itemId: itemId,
      answers: answers,
    );

    if (_qItemId != itemId) return false;

    var accepted = false;
    if (result != null) {
      _rememberSubmitted(submitted, answers);
      _ingest(result);
      accepted = true;
    } else {
      _error = 'Failed to submit answers';
    }

    _ploading = false;
    notifyListeners();
    return accepted;
  }

  /// Takes a server response: questions that already have an answer go to the
  /// history, the rest become the questions to show.
  void _ingest(GuidedQuestionsResponse response) {
    _round = response.round;

    final pending = <GuidedQuestion>[];
    for (final question in response.questions) {
      if (question.isAnswered) {
        _addAnswered(
          AnsweredQuestion(
            id: question.id,
            round: question.round,
            question: question.text,
            answer: question.skipped ? 'Skipped' : formatAnswer(question.answer),
            skipped: question.skipped,
          ),
        );
      } else {
        pending.add(question);
      }
    }

    _pending = response.round > _safetyMaxRounds ? const [] : pending;
  }

  void _rememberSubmitted(
      List<GuidedQuestion> questions,
      List<GuidedAnswer> answers,
      ) {
    final byQuestionId = {for (final a in answers) a.questionId: a};

    for (final question in questions) {
      final answer = byQuestionId[question.questionId];
      final skipped = answer == null || answer.isSkipped;
      _addAnswered(
        AnsweredQuestion(
          id: question.id,
          round: question.round,
          question: question.text,
          answer: (answer == null || answer.isSkipped)
              ? 'Skipped'
              : answer.displayValue,
          skipped: skipped,
        ),
      );
    }
  }

  void _addAnswered(AnsweredQuestion item) {
    if (_answered.any((existing) => existing.id == item.id)) return;
    _answered.add(item);
  }

  // ================= ALL CATEGORIES =================

  /// The server generates tasks once per item and returns the existing ones if
  /// called again, so a repeat call is safe. The flag stops a double tap.
  Future<bool> generateTasks() async {
    if (_taskGenerating) return false;

    final itemId = _qItemId;
    _taskGenerating = true;
    _error = '';
    notifyListeners();

    final success = await _repository.generateTasks(itemId: itemId);

    if (!success) {
      _error = 'Failed to generate tasks';
    }

    _taskGenerating = false;
    notifyListeners();

    return success;
  }
}