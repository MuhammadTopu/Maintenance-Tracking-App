class GenerateTaskResponse {
  final bool success;
  final List<TaskResponse> tasks;

  GenerateTaskResponse({required this.success, required this.tasks});

  factory GenerateTaskResponse.fromJson(Map<String, dynamic> json) {
    return GenerateTaskResponse(
      success: json['success'],
      tasks: List<TaskResponse>.from(
        json['tasks'].map((x) => TaskResponse.fromJson(x)),
      ),
    );
  }
}

/// -------------------------------------------------------------------

class TaskListResponse {
  final bool success;
  final String message;
  List<TaskResponse> tasks;

  TaskListResponse({required this.success, required this.message, required this.tasks});

  factory TaskListResponse.fromJson(Map<String, dynamic> json) {
    return TaskListResponse(
      success: json['success'],
      message: json['message'] ?? '',
      tasks: List<TaskResponse>.from(
        json['tasks'].map((x) => TaskResponse.fromJson(x)),
      ),
    );
  }
}

class TaskResponse {
  final String taskId;
  final String itemId;
  final String userId;
  final String upcomingTask;
  final String itemName;
  final String description;
  final String? itemLastServiceDate; // Nullable
  final String? receiptUrl;         // Nullable
  final String status;
  final String? lastDate;           // Nullable
  final List<String> maintenanceHistory; // Changed to List<String>
  final List<SuggestionResponse> shopSuggestions;

  TaskResponse({
    required this.taskId,
    required this.itemId,
    required this.userId,
    required this.upcomingTask,
    required this.itemName,
    required this.description,
    this.itemLastServiceDate,
    this.receiptUrl,
    required this.status,
    this.lastDate,
    required this.maintenanceHistory,
    required this.shopSuggestions,
  });

  factory TaskResponse.fromJson(Map<String, dynamic> json) {
    return TaskResponse(
      taskId: json['id'] ?? '',
      itemId: json['item_id'] ?? '',
      userId: json['user_id'] ?? '',
      upcomingTask: json['upcoming_task'] ?? '',
      itemName: json['item_name'] ?? '',
      description: json['description'] ?? '',
      itemLastServiceDate: json['item_last_service_date'],
      receiptUrl: json['receipt_url'],
      status: json['status'] ?? '',
      lastDate: json['last_date'], // Nullable field
      maintenanceHistory: List<String>.from(
        (json['maintenance_history'] ?? []).map((x) => x.toString()),
      ),
      shopSuggestions: List<SuggestionResponse>.from(
        (json['shop_suggestions'] ?? [])
            .map((x) => SuggestionResponse.fromJson(x)),
      ),
    );
  }
}

class SuggestionResponse {
  final String name;
  final double rating;
  final String contact;
  final int totalReviews;
  final String googleMapUrl;

  SuggestionResponse({
    required this.name,
    required this.rating,
    required this.contact,
    required this.totalReviews,
    required this.googleMapUrl,
  });

  factory SuggestionResponse.fromJson(Map<String, dynamic> json) {
    return SuggestionResponse(
      name: json['name'] ?? '',
      rating: json['rating']?.toDouble() ?? 0.0, // Ensures correct double conversion
      contact: json['contact'] ?? '',
      totalReviews: json['total_reviews'] ?? 0,
      googleMapUrl: json['google_map_url'] ?? '',
    );
  }
}
