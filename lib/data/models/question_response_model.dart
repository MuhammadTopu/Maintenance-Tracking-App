class QuestionsResponse {
  final bool success;
  final List<MaintenanceQuestion> questions;

  QuestionsResponse({
    required this.success,
    required this.questions,
  });

  factory QuestionsResponse.fromJson(Map<String, dynamic> json) {
    return QuestionsResponse(
      success: json['success'] ?? false,
      questions: (json['questions'] as List<dynamic>?)
          ?.map((e) => MaintenanceQuestion.fromJson(e))
          .toList() ??
          [],
    );
  }
}

class MaintenanceQuestion {
  final String id;
  final DateTime createdAt;
  final String itemId;
  final String maintenanceItem;
  final String itemKey;
  final String category;
  final String priority;
  final String question;
  final String reason;
  final String? userAnswer;
  final List<QuestionRecommendation> recommendations;

  MaintenanceQuestion({
    required this.id,
    required this.createdAt,
    required this.itemId,
    required this.maintenanceItem,
    required this.itemKey,
    required this.category,
    required this.priority,
    required this.question,
    required this.reason,
    this.userAnswer,
    this.recommendations = const [],
  });

  factory MaintenanceQuestion.fromJson(Map<String, dynamic> json) {
    return MaintenanceQuestion(
      id: json['id'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      itemId: json['itemId'] ?? '',
      maintenanceItem: json['maintenanceItem'] ?? '',
      itemKey: json['itemKey'] ?? '',
      category: json['category'] ?? '',
      priority: json['priority'] ?? '',
      question: json['question'] ?? '',
      reason: json['reason'] ?? '',
      userAnswer: json['userAnswer'],
      recommendations: (json['recommendations'] as List<dynamic>?)
          ?.map((e) => QuestionRecommendation.fromJson(e))
          .toList() ??
          const [],
    );
  }

  MaintenanceQuestion copyWith({
    String? id,
    DateTime? createdAt,
    String? itemId,
    String? maintenanceItem,
    String? itemKey,
    String? category,
    String? priority,
    String? question,
    String? reason,
    String? userAnswer,
    List<QuestionRecommendation>? recommendations,
  }) {
    return MaintenanceQuestion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      itemId: itemId ?? this.itemId,
      maintenanceItem: maintenanceItem ?? this.maintenanceItem,
      itemKey: itemKey ?? this.itemKey,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      question: question ?? this.question,
      reason: reason ?? this.reason,
      userAnswer: userAnswer ?? this.userAnswer,
      recommendations: recommendations ?? this.recommendations,
    );
  }
}

class QuestionRecommendation {
  final String id;
  final String questionId;
  final String option;
  final String status;
  final String message;

  QuestionRecommendation({
    required this.id,
    required this.questionId,
    required this.option,
    required this.status,
    required this.message,
  });

  factory QuestionRecommendation.fromJson(Map<String, dynamic> json) {
    return QuestionRecommendation(
      id: json['id'] ?? '',
      questionId: json['questionId'] ?? '',
      option: json['option'] ?? '',
      status: json['status'] ?? '',
      message: json['message'] ?? '',
    );
  }
}