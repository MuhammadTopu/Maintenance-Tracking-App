import 'guided_question_model.dart';

/// One entry of the `answers` array sent to `POST /items/:id/submit-answers`
/// for Home and Other.
class GuidedAnswer {
  const GuidedAnswer._({
    required this.questionId,
    required this.value,
    required this.isSkipped,
  });

  /// An answered question. [value] is a string, a number, or a list of strings,
  /// depending on the question's input type.
  const GuidedAnswer.answered({
    required String questionId,
    required Object value,
  }) : this._(questionId: questionId, value: value, isSkipped: false);

  /// A skipped question. The API only allows this for optional questions.
  const GuidedAnswer.skip(String questionId)
      : this._(questionId: questionId, value: null, isSkipped: true);

  final String questionId;
  final Object? value;
  final bool isSkipped;

  Map<String, Object?> toJson() => {
    'question_id': questionId,
    if (isSkipped) 'skipped': true else 'answer': value,
  };

  /// Text for the read-only review screen.
  String get displayValue => isSkipped ? 'Skipped' : formatAnswer(value);
}

/// A question together with the answer the user gave, for the review screen.
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

  /// Already formatted for display. "Skipped" when [skipped].
  final String answer;
  final bool skipped;
}

/// Turns an answer (string, number, list) into display text.
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

/// Validates what the user entered and builds the request entry for it. All
/// rules are here, in plain Dart, so they can be unit tested.
///
/// The "draft" a question's widget produces is:
///  * single choice and yes/no: the selected `String`
///  * multiple choice: a `List<String>`
///  * numeric and text: the typed `String`
///  * "Not sure" on a numeric or text question: the `String` [notSure]
class GuidedAnswerBuilder {
  GuidedAnswerBuilder._();

  /// Accepted by the API as the answer to a question of any type.
  static const String notSure = 'Not sure';

  /// Nothing entered: no value, blank text, or an empty selection.
  static bool isBlank(Object? draft) {
    if (draft == null) return true;
    if (draft is String) return draft.trim().isEmpty;
    if (draft is Iterable) return draft.isEmpty;
    return false;
  }

  /// Either the entry to send or the reason the draft is not valid. Exactly one
  /// of the two is set.
  static ({GuidedAnswer? answer, String? error}) build(
      GuidedQuestion question,
      Object? draft,
      ) {
    if (isBlank(draft)) {
      // A blank optional question is sent as skipped. A blank required one
      // blocks the submit.
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
        // The API wants a real number, not a numeric string.
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