import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/helper/logger.dart';
import '../../domain/base_repository/add_items_repository.dart';

class AddItemData {
  final String name;
  final String brand;
  final String model;
  final String category;
  final DateTime purchaseDate;
  final String yearOfModel;
  final int? totalMileage;
  final String? engine;
  final String? transmission;
  final String? drivetrain;
  final int? currentMileage;
  final int? averageMileagePerYear;
  final String? userNotes;
  final File? imageFile;

  const AddItemData({
    required this.name,
    required this.brand,
    required this.model,
    required this.category,
    required this.purchaseDate,
    required this.yearOfModel,
    this.totalMileage,
    this.engine,
    this.transmission,
    this.drivetrain,
    this.currentMileage,
    this.averageMileagePerYear,
    this.userNotes,
    this.imageFile,
  });
}

class AddItemProvider extends ChangeNotifier {
  final AddItemRepository _repository;

  AddItemProvider(this._repository);

  // ================= STATE =================
  bool isLoading = false;
  bool isModelLoading = false;

  String? lastAddedItemId;
  List<String> modelList = [];

  String? _modelsRequestBrand;

  // ================= BRAND -> MODELS =================
  Future<void> getModels(String brand) async {
    _modelsRequestBrand = brand;
    isModelLoading = true;
    modelList = [];
    notifyListeners();

    List<String> result = [];
    try {
      result = await _repository.getModelsByBrand(brand);
    } catch (e) {
      Log.debug('getModels failed: $e');
    }

    if (_modelsRequestBrand != brand) return;

    modelList = result;
    isModelLoading = false;
    notifyListeners();
  }

  // ================= ADD ITEM =================
  Future<bool> addItem(AddItemData data) async {
    isLoading = true;
    notifyListeners();

    Log.debug('Adding item: ${data.name}');

    String? itemId;
    try {
      itemId = await _repository.addItem(
        name: data.name,
        brand: data.brand,
        model: data.model,
        category: data.category,
        purchaseDate: data.purchaseDate.toIso8601String(),
        totalMileage: data.totalMileage,
        yearOfModel: data.yearOfModel,
        imageFile: data.imageFile,
        engine: data.engine,
        transmission: data.transmission,
        drivetrain: data.drivetrain,
        currentMileage: data.currentMileage,
        averageMileagePerYear: data.averageMileagePerYear,
        userNotes: data.userNotes,
      );
    } catch (e) {
      Log.debug('addItem failed: $e');
    }

    Log.debug('Item added with id: $itemId');

    lastAddedItemId = itemId;
    isLoading = false;
    notifyListeners();

    return itemId != null;
  }

  // ================= RESET =================
  void clearFields() {
    modelList = [];
    _modelsRequestBrand = null;
    isModelLoading = false;
    notifyListeners();
  }

  void clearLastAddedItemId() {
    lastAddedItemId = null;
    notifyListeners();
  }
}