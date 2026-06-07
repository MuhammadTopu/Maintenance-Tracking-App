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
      success: json['success'],
      message: json['message'],
      item: Item.fromJson(json['item']),
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
  final List<dynamic> issues;
  final String? taskId;        // ✅ nullable
  final String name;
  final String? description;   // ✅ nullable
  final String brand;
  final String model;
  final String vin;
  final String purchaseDate;
  final int totalMileage;
  final String lastServiceDate;
  final String lastServiceName;
  final String imageUrl;
  final String price;
  final String? image;         // ✅ nullable
  final String category;
  final List<String> serviceIntervals;
  final List<String> forumSuggestions;
  final User user;

  Item({
    required this.id,
    required this.createdAt,
    required this.userId,
    required this.issues,
    this.taskId,
    required this.name,
    this.description,
    required this.brand,
    required this.model,
    required this.vin,
    required this.purchaseDate,
    required this.totalMileage,
    required this.lastServiceDate,
    required this.lastServiceName,
    required this.imageUrl,
    required this.price,
    this.image,
    required this.category,
    required this.serviceIntervals,
    required this.forumSuggestions,
    required this.user,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'] ?? '',
      createdAt: json['created_at'] ?? '',
      userId: json['user_id'] ?? '',
      issues: List<dynamic>.from(json['issues'] ?? []),
      taskId: json['task_id'], // ✅ already nullable
      name: json['name'] ?? '',
      description: json['description'], // ✅ nullable
      brand: json['brand'] ?? '',
      model: json['model'] ?? '',
      vin: json['vin'] ?? '',
      purchaseDate: json['purchase_date'] ?? '',
      totalMileage: json['total_mileage'] ?? 0,
      lastServiceDate: json['last_service_date'] ?? '',
      lastServiceName: json['last_service_name'] ?? '',
      imageUrl: json['image_url'] ?? '',
      price: json['price'] ?? '0',
      image: json['image'], // ✅ nullable
      category: json['category'] ?? '',
      serviceIntervals: List<String>.from(json['service_intervals'] ?? []),
      forumSuggestions: List<String>.from(json['forum_suggestions'] ?? []),
      user: User.fromJson(json['user']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "created_at": createdAt,
      "user_id": userId,
      "issues": issues,
      "task_id": taskId,
      "name": name,
      "description": description,
      "brand": brand,
      "model": model,
      "vin": vin,
      "purchase_date": purchaseDate,
      "total_mileage": totalMileage,
      "last_service_date": lastServiceDate,
      "last_service_name": lastServiceName,
      "image_url": imageUrl,
      "price": price,
      "image": image,
      "category": category,
      "service_intervals": serviceIntervals,
      "forum_suggestions": forumSuggestions,
      "user": user.toJson(),
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
      email: json['email'],
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "email": email,
      "name": name,
    };
  }
}
