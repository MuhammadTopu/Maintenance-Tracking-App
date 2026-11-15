import 'package:maintenance_genie/domain/entities/add_item_data.dart';

sealed class Item {
  Item._fromJson(Map<String, dynamic> json)
      : id = _asString(json['id']) ?? '',
        name = _asString(json['name']) ?? '',
        userNotes = _asString(json['user_notes']),
        createdAt = _asString(json['created_at']),
        currentDate = _asString(json['current_date']),
        imageUrl = _asString(json['image_url']),
        user = _asUser(json['user']),
  // Returned for every category (Vehicle, Home and Other), detail only.
        serviceIntervals = _asStringList(json['service_intervals']),
        forumSuggestions = _asForumSuggestions(json['forum_suggestions']);

  factory Item.fromJson(Map<String, dynamic> json) {
    switch (json['category']) {
      case ItemCategory.vehicle:
        return VehicleItem.fromJson(json);
      case ItemCategory.home:
        return HomeItem.fromJson(json);
      case ItemCategory.other:
        return OtherItem.fromJson(json);
      default:
        return UnknownItem.fromJson(json);
    }
  }

  final String id;
  final String name;
  final String? userNotes;

  final String? createdAt;
  final String? currentDate;

  final String? imageUrl;
  final User? user;

  final List<String> serviceIntervals;
  final List<ForumSuggestion> forumSuggestions;

  String get category;
}

final class VehicleItem extends Item {
  VehicleItem.fromJson(Map<String, dynamic> json)
      : brand = _asString(json['brand']) ?? '',
        model = _asString(json['model']) ?? '',
        yearOfTheModel = _asString(json['year_of_the_model']),
        engine = _asString(json['engine']),
        transmission = _asString(json['transmission']),
        drivetrain = _asString(json['drivetrain']),
        currentMileage = _asInt(json['current_mileage']),
        averageMileagePerYear = _asInt(json['average_mileage_per_year']),
        purchaseDate = _asString(json['purchase_date']),
        totalMileage = _asInt(json['total_mileage']),
        super._fromJson(json);

  final String brand;
  final String model;
  final String? yearOfTheModel;
  final String? engine;
  final String? transmission;
  final String? drivetrain;
  final int? currentMileage;
  final int? averageMileagePerYear;
  final String? purchaseDate;
  final int? totalMileage;

  @override
  String get category => ItemCategory.vehicle;
}

final class HomeItem extends Item {
  HomeItem.fromJson(Map<String, dynamic> json)
      : propertyType = _asString(json['property_type']) ?? '',
        yearBuilt = _asString(json['year_of_the_model']),
        zipCode = _asString(json['zip_code']),
        ownOrRent = _asString(json['own_or_rent']),
        systems = _asStringList(json['systems']),
        super._fromJson(json);

  final String propertyType;

  final String? yearBuilt;
  final String? zipCode;

  final String? ownOrRent;

  final List<String> systems;

  List<String> get systemLabels => [
    for (final slug in systems) HomeSystems.labelOf(slug),
  ];

  @override
  String get category => ItemCategory.home;
}

final class OtherItem extends Item {
  OtherItem.fromJson(Map<String, dynamic> json)
      : group = _asString(json['group']),
        subCategory = _asString(json['sub_category']),
        description = _asString(json['description']),
        dueDate = _asString(json['due_date']),
        repeat = _asString(json['repeat']),
        reminder = _asString(json['reminder']),
        super._fromJson(json);

  final String? group;
  final String? subCategory;
  final String? description;

  final String? dueDate;
  final String? repeat;
  final String? reminder;

  @override
  String get category => ItemCategory.other;
}

final class UnknownItem extends Item {
  UnknownItem.fromJson(Map<String, dynamic> json)
      : rawCategory = _asString(json['category']) ?? '',
        super._fromJson(json);

  final String rawCategory;

  @override
  String get category => rawCategory;
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

  User({required this.email, required this.name});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(email: json['email'] ?? '', name: json['name'] ?? '');
  }

  Map<String, dynamic> toJson() {
    return {"email": email, "name": name};
  }
}

// ---------------------------------------------------------------------------
// Tolerant JSON readers. The API sends null for missing optional values and
// may send empty strings, so blank text is normalised to null.
// ---------------------------------------------------------------------------

String? _asString(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim());
  return null;
}

List<String> _asStringList(dynamic value) {
  if (value is! List) return const [];
  return [
    for (final element in value)
      if (element != null) element.toString(),
  ];
}

List<ForumSuggestion> _asForumSuggestions(dynamic value) {
  if (value is! List) return const [];
  return [
    for (final element in value)
      if (element is Map)
        ForumSuggestion.fromJson(Map<String, dynamic>.from(element)),
  ];
}

User? _asUser(dynamic value) =>
    value is Map ? User.fromJson(Map<String, dynamic>.from(value)) : null;