class OneItemModel {
  final bool success;
  final String message;
  final Item item;

  OneItemModel({
    required this.success,
    required this.message,
    required this.item,
  });

  factory OneItemModel.fromJson(Map<String, dynamic> json) {
    return OneItemModel(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      item: Item.fromJson(json['item'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "success": success,
      "message": message,
      "item": item.toJson(),
    };
  }
}

class Item {
  final String id;
  final String createdAt;
  final String userId;
  final String? taskId;
  final String name;
  final String brand;
  final String model;
  final String purchaseDate;
  final int? totalMileage;
  final int? averageMileagePerYear;
  final String engine;
  final int? currentMileage;
  final String transmission;
  final String drivetrain;
  final String currentDate;
  final String yearOfTheModel;
  final String imageUrl;
  final String category;
  final String? userNotes;
  final List<String> serviceIntervals;
  final List<ForumSuggestion> forumSuggestions;
  final User user;

  Item({
    required this.id,
    required this.createdAt,
    required this.userId,
    this.taskId,
    required this.name,
    required this.brand,
    required this.model,
    required this.purchaseDate,
    this.totalMileage,
    this.averageMileagePerYear,
    required this.engine,
    this.currentMileage,
    required this.transmission,
    required this.drivetrain,
    required this.currentDate,
    required this.yearOfTheModel,
    required this.imageUrl,
    required this.category,
    this.userNotes,
    required this.serviceIntervals,
    required this.forumSuggestions,
    required this.user,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'] ?? '',
      createdAt: json['created_at'] ?? '',
      userId: json['user_id'] ?? '',
      taskId: json['task_id'],
      name: json['name'] ?? '',
      brand: json['brand'] ?? '',
      model: json['model'] ?? '',
      purchaseDate: json['purchase_date'] ?? '',
      totalMileage: json['total_mileage'],
      averageMileagePerYear: json['average_mileage_per_year'],
      engine: json['engine'] ?? '',
      currentMileage: json['current_mileage'],
      transmission: json['transmission'] ?? '',
      drivetrain: json['drivetrain'] ?? '',
      currentDate: json['current_date'] ?? '',
      yearOfTheModel: json['year_of_the_model'] ?? '',
      imageUrl: json['image_url'] ?? '',
      category: json['category'] ?? '',
      userNotes: json['user_notes'],
      serviceIntervals: List<String>.from(json['service_intervals'] ?? []),
      forumSuggestions: (json['forum_suggestions'] as List<dynamic>? ?? [])
          .map((e) => ForumSuggestion.fromJson(e))
          .toList(),
      user: User.fromJson(json['user'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "created_at": createdAt,
      "user_id": userId,
      "task_id": taskId,
      "name": name,
      "brand": brand,
      "model": model,
      "purchase_date": purchaseDate,
      "total_mileage": totalMileage,
      "average_mileage_per_year": averageMileagePerYear,
      "engine": engine,
      "current_mileage": currentMileage,
      "transmission": transmission,
      "drivetrain": drivetrain,
      "current_date": currentDate,
      "year_of_the_model": yearOfTheModel,
      "image_url": imageUrl,
      "category": category,
      "user_notes": userNotes,
      "service_intervals": serviceIntervals,
      "forum_suggestions": forumSuggestions.map((e) => e.toJson()).toList(),
      "user": user.toJson(),
    };
  }
}

class ForumSuggestion {
  final String reason;
  final String category;
  final String appliesTo;
  final String confidence;
  final String sourceUrl;
  final String sourceForum;
  final String maintenanceItem;
  final String manufacturerInterval;
  final String forumRecommendedInterval;

  ForumSuggestion({
    required this.reason,
    required this.category,
    required this.appliesTo,
    required this.confidence,
    required this.sourceUrl,
    required this.sourceForum,
    required this.maintenanceItem,
    required this.manufacturerInterval,
    required this.forumRecommendedInterval,
  });

  factory ForumSuggestion.fromJson(Map<String, dynamic> json) {
    return ForumSuggestion(
      reason: json['reason'] ?? '',
      category: json['category'] ?? '',
      appliesTo: json['applies_to'] ?? '',
      confidence: json['confidence'] ?? '',
      sourceUrl: json['source_url'] ?? '',
      sourceForum: json['source_forum'] ?? '',
      maintenanceItem: json['maintenance_item'] ?? '',
      manufacturerInterval: json['manufacturer_interval'] ?? '',
      forumRecommendedInterval: json['forum_recommended_interval'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "reason": reason,
      "category": category,
      "applies_to": appliesTo,
      "confidence": confidence,
      "source_url": sourceUrl,
      "source_forum": sourceForum,
      "maintenance_item": maintenanceItem,
      "manufacturer_interval": manufacturerInterval,
      "forum_recommended_interval": forumRecommendedInterval,
    };
  }
}

class User {
  final String email;
  final String name;

  User({
    required this.email,
    required this.name,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      email: json['email'] ?? '',
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "email": email,
      "name": name,
    };
  }
}