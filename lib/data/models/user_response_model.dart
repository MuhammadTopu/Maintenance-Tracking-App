class UserResponse {
  final bool success;
  final String message;
  final UserData data;

  UserResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory UserResponse.fromJson(Map<String, dynamic> json) {
    return UserResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: UserData.fromJson(json['data']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "success": success,
      "message": message,
      "data": data.toJson(),
    };
  }
}

class UserData {
  final String id;
  final String name;
  final String email;
  final String? avatar;
  final String createdAt;
  final String updatedAt;
  final String? address;
  final String role;
  final String type;
  final String status;
  final String billingId;
  final String? imageUrl;
  final bool isPremium;

  UserData({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
    required this.createdAt,
    required this.updatedAt,
    this.address,
    required this.role,
    required this.type,
    required this.status,
    required this.billingId,
    this.imageUrl,
    required this.isPremium,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      avatar: json['avatar'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      address: json['address'],
      role: json['role'] ?? '',
      type: json['type'] ?? '',
      status: json['status'] ?? '',
      billingId: json['billing_id'] ?? '',
      imageUrl: json['imageUrl'],
      isPremium: json['isPremium'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "email": email,
      "avatar": avatar,
      "created_at": createdAt,
      "updated_at": updatedAt,
      "address": address,
      "role": role,
      "type": type,
      "status": status,
      "billing_id": billingId,
      "imageUrl": imageUrl,
      "isPremium": isPremium,
    };
  }
}
