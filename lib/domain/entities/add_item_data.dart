import 'dart:convert';
import 'dart:io';

class ItemCategory {
  ItemCategory._();

  static const String vehicle = 'Vehicle';
  static const String home = 'Home';
  static const String other = 'Other';
}

class HomeSystems {
  HomeSystems._();

  static const Map<String, String> slugByLabel = {
    'Central HVAC / heat pump / furnace': 'central_hvac',
    'Window or mini-split AC': 'window_ac',
    'Water heater': 'water_heater',
    'Well': 'well',
    'Septic': 'septic',
    'Municipal water/sewer': 'municipal_water_sewer',
    'Gutters': 'gutters',
    'Fireplace / wood stove': 'fireplace_wood_stove',
    'Sump pump': 'sump_pump',
    'Basement / crawlspace': 'basement_crawlspace',
    'Garage': 'garage',
    'Deck / porch': 'deck_porch',
    'Pool / hot tub': 'pool_hot_tub',
    'Irrigation system': 'irrigation_system',
    'Generator': 'generator',
    'Water softener / filtration': 'water_softener_filtration',
  };

  static List<String> get labels => slugByLabel.keys.toList(growable: false);

  static List<String> slugsOf(Iterable<String> selectedLabels) {
    final selected = selectedLabels.toSet();
    return [
      for (final entry in slugByLabel.entries)
        if (selected.contains(entry.key)) entry.value,
    ];
  }
}

abstract class AddItemData {
  const AddItemData({required this.name, this.userNotes, this.imageFile});

  final String name;
  final String? userNotes;
  final File? imageFile;
  String get category;

  Map<String, String> toFormFields();
}

class VehicleItemData extends AddItemData {
  const VehicleItemData({
    required super.name,
    required this.brand,
    required this.model,
    required this.purchaseDate,
    required this.yearOfModel,
    this.totalMileage,
    this.engine,
    this.transmission,
    this.drivetrain,
    this.currentMileage,
    this.averageMileagePerYear,
    super.userNotes,
    super.imageFile,
  });

  final String brand;
  final String model;
  final DateTime purchaseDate;
  final String yearOfModel;
  final int? totalMileage;
  final String? engine;
  final String? transmission;
  final String? drivetrain;
  final int? currentMileage;
  final int? averageMileagePerYear;

  @override
  String get category => ItemCategory.vehicle;

  @override
  Map<String, String> toFormFields() => _compact({
    'category': category,
    'name': name,
    'brand': brand,
    'model': model,
    'purchase_date': _apiDate(purchaseDate),
    'year_of_the_model': yearOfModel,
    'total_mileage': totalMileage?.toString(),
    'engine': engine,
    'transmission': transmission,
    'drivetrain': drivetrain,
    'current_mileage': currentMileage?.toString(),
    'average_mileage_per_year': averageMileagePerYear?.toString(),
    'user_notes': userNotes,
  });
}

class HomeItemData extends AddItemData {
  const HomeItemData({
    required super.name,
    required this.propertyType,
    this.yearBuilt,
    this.zipCode,
    this.ownOrRent,
    this.systems = const [],
    super.userNotes,
    super.imageFile,
  });

  final String propertyType;
  final String? yearBuilt;
  final String? zipCode;
  final String? ownOrRent;
  final List<String> systems;
  static const int maxZipLength = 10;

  @override
  String get category => ItemCategory.home;

  @override
  Map<String, String> toFormFields() => _compact({
    'category': category,
    'name': name,
    'property_type': propertyType,
    'year_of_the_model': yearBuilt,
    'zip_code': zipCode,
    'own_or_rent': ownOrRent,
    'systems': systems.isEmpty ? null : jsonEncode(systems),
    'user_notes': userNotes,
  });
}

class OtherItemData extends AddItemData {
  const OtherItemData({
    required super.name,
    this.group,
    this.description,
    this.dueDate,
    this.repeat,
    this.reminder,
    super.userNotes,
    super.imageFile,
  });

  final String? group;
  final String? description;
  final DateTime? dueDate;
  final String? repeat;
  final String? reminder;

  @override
  String get category => ItemCategory.other;

  @override
  Map<String, String> toFormFields() => _compact({
    'category': category,
    'name': name,
    'group': group,
    'description': description,
    'due_date': dueDate == null ? null : _apiDate(dueDate!),
    'repeat': repeat,
    'reminder': reminder,
    'user_notes': userNotes,
  });
}

Map<String, String> _compact(Map<String, String?> raw) => {
  for (final entry in raw.entries)
    if (entry.value != null && entry.value!.trim().isNotEmpty)
      entry.key: entry.value!.trim(),
};

String _apiDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';