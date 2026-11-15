/// Questions for Home and Other items.
///
/// Vehicle keeps its own format (`question_response_model.dart`): fixed
/// Yes / No / Planned answers and recommendations. Home and Other questions are
/// generated per item, come in rounds, and each one says how it must be
/// answered (`input_type`).

/// How a question has to be answered. Drives which widget is shown.
enum QuestionInputType {
  singleChoice,
  multiChoice,
  yesNo,
  numeric,
  text;

  /// An unknown or missing value becomes [text], so a new input type added on
  /// the server still gives the user a way to answer.
  static QuestionInputType fromApi(String? raw) {
    switch (raw?.trim().toLowerCase()) {
      case 'single_choice':
        return singleChoice;
      case 'multi_choice':
        return multiChoice;
      case 'yes_no':
        return yesNo;
      case 'numeric':
        return numeric;
      default:
        return text;
    }
  }
}

class GuidedQuestion {
  const GuidedQuestion({
    required this.id,
    required this.questionId,
    required this.text,
    required this.inputType,
    required this.options,
    required this.optional,
    required this.reason,
    required this.maintenanceImpact,
    required this.round,
    this.answer,
    this.skipped = false,
  });

  /// Database id. The API also accepts this in place of [questionId].
  final String id;

  /// Stable key such as `septic_last_pumped`. This is what an answer refers to.
  final String questionId;
  final String text;
  final QuestionInputType inputType;
  final List<String> options;

  /// Optional questions may be skipped.
  final bool optional;
  final String reason;
  final String? maintenanceImpact;
  final int round;

  /// Saved answer, if this question was already answered: a string, a number or
  /// a list of strings.
  final Object? answer;
  final bool skipped;

  static const List<String> _defaultYesNo = ['Yes', 'No', 'Not sure'];

  /// Choices to show. A `yes_no` question without options still gets
  /// Yes / No / Not sure.
  List<String> get choices {
    if (options.isNotEmpty) return options;
    return inputType == QuestionInputType.yesNo ? _defaultYesNo : const [];
  }

  /// The input type to actually render. A choice question that arrives without
  /// any options is shown as a text field, so the user is never stuck.
  QuestionInputType get effectiveType {
    switch (inputType) {
      case QuestionInputType.singleChoice:
      case QuestionInputType.multiChoice:
        return options.isEmpty ? QuestionInputType.text : inputType;
      case QuestionInputType.yesNo:
      case QuestionInputType.numeric:
      case QuestionInputType.text:
        return inputType;
    }
  }

  /// True once an answer is saved on the server, or the question was skipped.
  bool get isAnswered => skipped || _hasValue(answer);

  factory GuidedQuestion.fromJson(Map<String, dynamic> json) {
    final id = _string(json['id']);
    final questionId = _string(json['question_id']);
    final rawOptions = json['options'];

    return GuidedQuestion(
      id: id,
      questionId: questionId.isNotEmpty ? questionId : id,
      text: _string(json['question_text']).isNotEmpty
          ? _string(json['question_text'])
          : _string(json['question']),
      inputType: QuestionInputType.fromApi(json['input_type']?.toString()),
      options: rawOptions is List
          ? [for (final option in rawOptions) option.toString()]
          : const <String>[],
      optional: json['optional'] == true,
      reason: _string(json['reason']),
      maintenanceImpact: _nullableString(json['maintenance_impact']),
      round: _int(json['round']) ?? 1,
      answer: json['answer'],
      skipped: json['skipped'] == true,
    );
  }
}

/// One page of the `GET /items/:id/questions` and
/// `POST /items/:id/submit-answers` responses for Home and Other.
class GuidedQuestionsResponse {
  const GuidedQuestionsResponse({
    required this.success,
    required this.round,
    required this.needsMoreInformation,
    required this.questions,
  });

  final bool success;
  final int round;

  /// `true` while there are unanswered questions or another round to come.
  final bool needsMoreInformation;
  final List<GuidedQuestion> questions;

  factory GuidedQuestionsResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['questions'];
    final questions = raw is List
        ? [
      for (final element in raw)
        if (element is Map)
          GuidedQuestion.fromJson(Map<String, dynamic>.from(element)),
    ]
        : <GuidedQuestion>[];

    return GuidedQuestionsResponse(
      success: json['success'] == true,
      round: _int(json['round']) ??
          (questions.isEmpty ? 1 : questions.first.round),
      needsMoreInformation: json['needs_more_information'] == true,
      questions: questions,
    );
  }
}

String _string(dynamic value) => value == null ? '' : value.toString().trim();

String? _nullableString(dynamic value) {
  final text = _string(value);
  return text.isEmpty ? null : text;
}

int? _int(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim());
  return null;
}

bool _hasValue(Object? value) {
  if (value == null) return false;
  if (value is String) return value.trim().isNotEmpty;
  if (value is Iterable) return value.isNotEmpty;
  return true;
}