import 'guided_question_model.dart';

class GuidedAnswer {
  const GuidedAnswer._({
    required this.questionId,
    required this.value,
    required this.isSkipped,
  });

  const GuidedAnswer.answered({
    required String questionId,
    required Object value,
  }) : this._(questionId: questionId, value: value, isSkipped: false);

  const GuidedAnswer.skip(String questionId)
      : this._(questionId: questionId, value: null, isSkipped: true);

  final String questionId;
  final Object? value;
  final bool isSkipped;

  Map<String, Object?> toJson() => {
    'question_id': questionId,
    if (isSkipped) 'skipped': true else 'answer': value,
  };

  String get displayValue => isSkipped ? 'Skipped' : formatAnswer(value);
}

class AnsweredQuestion {
  const AnsweredQuestion({
    required this.id,
    required this.round,
    required this.question,
    required this.answer,
    required this.skipped,
  });

  final String id;
  final int round;
  final String question;
  final String answer;
  final bool skipped;
}

String formatAnswer(Object? value) {
  if (value == null) return '';
  if (value is Iterable) {
    return value
        .map(formatAnswer)
        .where((text) => text.isNotEmpty)
        .join(', ');
  }
  if (value is num) {
    return value is double && value == value.truncateToDouble()
        ? value.toInt().toString()
        : value.toString();
  }
  return value.toString().trim();
}

class GuidedAnswerBuilder {
  GuidedAnswerBuilder._();

  static const String notSure = 'Not sure';

  static bool isBlank(Object? draft) {
    if (draft == null) return true;
    if (draft is String) return draft.trim().isEmpty;
    if (draft is Iterable) return draft.isEmpty;
    return false;
  }

  static ({GuidedAnswer? answer, String? error}) build(
      GuidedQuestion question,
      Object? draft,
      ) {
    if (isBlank(draft)) {
      return question.optional
          ? (answer: GuidedAnswer.skip(question.questionId), error: null)
          : (answer: null, error: 'This question is required');
    }

    switch (question.effectiveType) {
      case QuestionInputType.multiChoice:
        if (draft is! Iterable) {
          return (answer: null, error: 'Select at least one option');
        }
        final selected = [for (final item in draft) item.toString()];
        if (selected.any((item) => !question.choices.contains(item))) {
          return (answer: null, error: 'Choose from the listed options');
        }
        return (
        answer: GuidedAnswer.answered(
          questionId: question.questionId,
          value: selected,
        ),
        error: null,
        );

      case QuestionInputType.singleChoice:
      case QuestionInputType.yesNo:
        final choice = draft.toString().trim();
        if (choice != notSure && !question.choices.contains(choice)) {
          return (answer: null, error: 'Choose one of the options');
        }
        return (
        answer: GuidedAnswer.answered(
          questionId: question.questionId,
          value: choice,
        ),
        error: null,
        );

      case QuestionInputType.numeric:
        final typed = draft.toString().trim();
        if (typed == notSure) {
          return (
          answer: GuidedAnswer.answered(
            questionId: question.questionId,
            value: notSure,
          ),
          error: null,
          );
        }
        final number = num.tryParse(typed);
        if (number == null || !number.isFinite) {
          return (answer: null, error: 'Enter a valid number');
        }
        return (
        answer: GuidedAnswer.answered(
          questionId: question.questionId,
          value: number,
        ),
        error: null,
        );

      case QuestionInputType.text:
        return (
        answer: GuidedAnswer.answered(
          questionId: question.questionId,
          value: draft.toString().trim(),
        ),
        error: null,
        );
    }
  }
}