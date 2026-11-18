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
      data: UserData.fromJson(
        json['data'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data.toJson(),
    };
  }
}

class UserData {
  final String id;
  final String name;
  final String email;
  final String? avatar;
  final String? address;
  final String? provider;
  final DateTime? subscribedAt;
  final DateTime? subscriptionValidUntil;
  final String? subscriptionStatus;
  final String? imageUrl;
  final bool isPremium;
  final SubscriptionData? subscription;

  UserData({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
    this.address,
    this.provider,
    this.subscribedAt,
    this.subscriptionValidUntil,
    this.subscriptionStatus,
    this.imageUrl,
    required this.isPremium,
    this.subscription,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      avatar: json['avatar'],
      address: json['address'],
      provider: json['provider'],
      subscribedAt: json['subscribed_at'] != null
          ? DateTime.tryParse(json['subscribed_at'].toString())
          : null,
      subscriptionValidUntil:
      json['subscription_valid_until'] != null
          ? DateTime.tryParse(
        json['subscription_valid_until'].toString(),
      )
          : null,
      subscriptionStatus: json['subscription_status'],
      imageUrl: json['imageUrl'],
      isPremium: json['isPremium'] ?? false,
      subscription: json['subscription'] != null
          ? SubscriptionData.fromJson(
        json['subscription'] as Map<String, dynamic>,
      )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatar': avatar,
      'address': address,
      'provider': provider,
      'subscribed_at': subscribedAt?.toIso8601String(),
      'subscription_valid_until':
      subscriptionValidUntil?.toIso8601String(),
      'subscription_status': subscriptionStatus,
      'imageUrl': imageUrl,
      'isPremium': isPremium,
      'subscription': subscription?.toJson(),
    };
  }
}

class SubscriptionData {
  final String? plan;
  final String? status;
  final bool isLifetime;
  final DateTime? expiresAt;
  final bool? willRenew;
  final bool? inGracePeriod;
  final String? store;

  SubscriptionData({
    this.plan,
    this.status,
    this.isLifetime = false,
    this.expiresAt,
    this.willRenew,
    this.inGracePeriod,
    this.store,
  });

  factory SubscriptionData.fromJson(Map<String, dynamic> json) {
    return SubscriptionData(
      plan: json['plan'],
      status: json['status'],
      isLifetime: json['isLifetime'] ?? false,
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'].toString())
          : null,
      willRenew: json['willRenew'],
      inGracePeriod: json['inGracePeriod'],
      store: json['store'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'plan': plan,
      'status': status,
      'isLifetime': isLifetime,
      'expiresAt': expiresAt?.toIso8601String(),
      'willRenew': willRenew,
      'inGracePeriod': inGracePeriod,
      'store': store,
    };
  }
}
