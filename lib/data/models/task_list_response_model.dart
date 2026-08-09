class TaskListResponse {
  final bool success;
  final String message;
  final List<TaskResponse> tasks;

  TaskListResponse({
    required this.success,
    required this.message,
    required this.tasks,
  });

  factory TaskListResponse.fromJson(Map<String, dynamic> json) {
    return TaskListResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      tasks: (json['tasks'] as List<dynamic>?)
          ?.map((e) => TaskResponse.fromJson(e))
          .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'tasks': tasks.map((e) => e.toJson()).toList(),
    };
  }
}

class TaskResponse {
  final String id;
  final DateTime createdAt;
  final String itemId;
  final String userId;
  final String upcomingTask;
  final String itemName;
  final String description;
  final String category;
  final String recommendedInterval;
  final String lastServiceAssumption;
  final String nextDueMileage;
  final String nextDueDate;
  final String priority;
  final bool manufacturerIntervalUncertain;
  final DateTime? itemLastServiceDate;
  final String? receiptUrl;
  final String status;
  final DateTime? lastDate;
  final List<dynamic> maintenanceHistory;
  final dynamic shopSuggestions;

  TaskResponse({
    required this.id,
    required this.createdAt,
    required this.itemId,
    required this.userId,
    required this.upcomingTask,
    required this.itemName,
    required this.description,
    required this.category,
    required this.recommendedInterval,
    required this.lastServiceAssumption,
    required this.nextDueMileage,
    required this.nextDueDate,
    required this.priority,
    required this.manufacturerIntervalUncertain,
    this.itemLastServiceDate,
    this.receiptUrl,
    required this.status,
    this.lastDate,
    required this.maintenanceHistory,
    this.shopSuggestions,
  });

  factory TaskResponse.fromJson(Map<String, dynamic> json) {
    return TaskResponse(
      id: json['id'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      itemId: json['item_id'] ?? '',
      userId: json['user_id'] ?? '',
      upcomingTask: json['upcoming_task'] ?? '',
      itemName: json['item_name'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      recommendedInterval: json['recommended_interval'] ?? '',
      lastServiceAssumption: json['last_service_assumption'] ?? '',
      nextDueMileage: json['next_due_mileage'] ?? '',
      nextDueDate: json['next_due_date'] ?? '',
      priority: json['priority'] ?? '',
      manufacturerIntervalUncertain:
      json['manufacturer_interval_uncertain'] ?? false,
      itemLastServiceDate: json['item_last_service_date'] != null
          ? DateTime.parse(json['item_last_service_date'])
          : null,
      receiptUrl: json['receipt_url'],
      status: json['status'] ?? '',
      lastDate: json['last_date'] != null
          ? DateTime.parse(json['last_date'])
          : null,
      maintenanceHistory:
      List<dynamic>.from(json['maintenance_history'] ?? []),
      shopSuggestions: json['shop_suggestions'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'item_id': itemId,
      'user_id': userId,
      'upcoming_task': upcomingTask,
      'item_name': itemName,
      'description': description,
      'category': category,
      'recommended_interval': recommendedInterval,
      'last_service_assumption': lastServiceAssumption,
      'next_due_mileage': nextDueMileage,
      'next_due_date': nextDueDate,
      'priority': priority,
      'manufacturer_interval_uncertain': manufacturerIntervalUncertain,
      'item_last_service_date': itemLastServiceDate?.toIso8601String(),
      'receipt_url': receiptUrl,
      'status': status,
      'last_date': lastDate?.toIso8601String(),
      'maintenance_history': maintenanceHistory,
      'shop_suggestions': shopSuggestions,
    };
  }

  TaskResponse copyWith({
    String? id,
    DateTime? createdAt,
    String? itemId,
    String? userId,
    String? upcomingTask,
    String? itemName,
    String? description,
    String? category,
    String? recommendedInterval,
    String? lastServiceAssumption,
    String? nextDueMileage,
    String? nextDueDate,
    String? priority,
    bool? manufacturerIntervalUncertain,
    DateTime? itemLastServiceDate,
    String? receiptUrl,
    String? status,
    DateTime? lastDate,
    List<dynamic>? maintenanceHistory,
    dynamic shopSuggestions,
  }) {
    return TaskResponse(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      itemId: itemId ?? this.itemId,
      userId: userId ?? this.userId,
      upcomingTask: upcomingTask ?? this.upcomingTask,
      itemName: itemName ?? this.itemName,
      description: description ?? this.description,
      category: category ?? this.category,
      recommendedInterval:
      recommendedInterval ?? this.recommendedInterval,
      lastServiceAssumption:
      lastServiceAssumption ?? this.lastServiceAssumption,
      nextDueMileage: nextDueMileage ?? this.nextDueMileage,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      priority: priority ?? this.priority,
      manufacturerIntervalUncertain:
      manufacturerIntervalUncertain ??
          this.manufacturerIntervalUncertain,
      itemLastServiceDate:
      itemLastServiceDate ?? this.itemLastServiceDate,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      status: status ?? this.status,
      lastDate: lastDate ?? this.lastDate,
      maintenanceHistory:
      maintenanceHistory ?? this.maintenanceHistory,
      shopSuggestions: shopSuggestions ?? this.shopSuggestions,
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