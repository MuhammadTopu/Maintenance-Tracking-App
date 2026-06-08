class QuestionsResponse {
  final bool success;
  final List<String> questions;

  QuestionsResponse({
    required this.success,
    required this.questions,
  });

  factory QuestionsResponse.fromJson(Map<String, dynamic> json) {
    return QuestionsResponse(
      success: json['success'] ?? false,
      questions: List<String>.from(json['questions'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'questions': questions,
    };
  }
}
