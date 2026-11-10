class AuthResponseModel {
  final bool success;
  final String message;
  final String token;
  final String refreshToken;
  final AuthUserModel? user;

  AuthResponseModel({
    required this.success,
    required this.message,
    required this.token,
    required this.refreshToken,
    this.user,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      token: json['token'] ?? '',
      refreshToken: json['refreshToken'] ?? '',
      user: json['user'] != null
          ? AuthUserModel.fromJson(json['user'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'token': token,
      'refreshToken': refreshToken,
      'user': user?.toJson(),
    };
  }
}

class AuthUserModel {
  final String id;
  final String name;
  final String email;
  final String type;
  final String role;

  AuthUserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.type,
    required this.role,
  });

  factory AuthUserModel.fromJson(Map<String, dynamic> json) {
    return AuthUserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      type: json['type'] ?? '',
      role: json['role'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'type': type,
      'role': role,
    };
  }
}