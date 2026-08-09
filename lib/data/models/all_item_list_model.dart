class AllItemListModel {
  final bool success;
  final String message;
  final List<Items> items;

  AllItemListModel({
    required this.success,
    required this.message,
    required this.items,
  });

  factory AllItemListModel.fromJson(Map<String, dynamic> json) {
    return AllItemListModel(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      items: (json['items'] as List<dynamic>?)
          ?.map((e) => Items.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
    );
  }
}

class Items {
  final String id;
  final String category;
  final String name;
  final String model;
  final String brand;
  final String yearOfTheModel;
  final String? engine;
  final String? transmission;
  final String? drivetrain;
  final int? currentMileage;
  final int? averageMileagePerYear;
  final String? userNotes;

  Items({
    required this.id,
    required this.category,
    required this.name,
    required this.model,
    required this.brand,
    required this.yearOfTheModel,
    this.engine,
    this.transmission,
    this.drivetrain,
    this.currentMileage,
    this.averageMileagePerYear,
    this.userNotes,
  });

  factory Items.fromJson(Map<String, dynamic> json) {
    return Items(
      id: json['id'] ?? '',
      category: json['category'] ?? '',
      name: json['name'] ?? '',
      model: json['model'] ?? '',
      brand: json['brand'] ?? '',
      yearOfTheModel: json['year_of_the_model'] ?? '',
      engine: json['engine'],
      transmission: json['transmission'],
      drivetrain: json['drivetrain'],
      currentMileage: json['current_mileage'],
      averageMileagePerYear: json['average_mileage_per_year'],
      userNotes: json['user_notes'],
    );
  }

  Items copyWith({
    String? id,
    String? category,
    String? name,
    String? model,
    String? brand,
    String? yearOfTheModel,
    String? engine,
    String? transmission,
    String? drivetrain,
    int? currentMileage,
    int? averageMileagePerYear,
    String? userNotes,
  }) {
    return Items(
      id: id ?? this.id,
      category: category ?? this.category,
      name: name ?? this.name,
      model: model ?? this.model,
      brand: brand ?? this.brand,
      yearOfTheModel: yearOfTheModel ?? this.yearOfTheModel,
      engine: engine ?? this.engine,
      transmission: transmission ?? this.transmission,
      drivetrain: drivetrain ?? this.drivetrain,
      currentMileage: currentMileage ?? this.currentMileage,
      averageMileagePerYear:
      averageMileagePerYear ?? this.averageMileagePerYear,
      userNotes: userNotes ?? this.userNotes,
    );
  }
}