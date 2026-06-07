import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../domain/base_repository/add_items_repository.dart';

class AddItemProvider extends ChangeNotifier {
  final AddItemRepository _repository;

  AddItemProvider(this._repository);

  // ================= STATE =================
  bool isLoading = false;
  bool isModelLoading = false;

  int currentStep = 0;

  String? selectedCategory;
  String? selectedModel;
  String selectedBrand = 'Select';

  DateTime? selectedDate;
  DateTime? lastServiceDate;

  String name = '';
  String price = '';
  String issue = '';
  String yearOfModel = '';
  String totalMileage = '';
  String lastServiceName = '';

  File? imageFile;

  List<String> modelList = [];

  final ImagePicker _picker = ImagePicker();

  // ================= IMAGE =================
  Future<void> pickImage(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(source: source);

      if (file != null) {
        imageFile = File(file.path);
      } else {
        imageFile = null;
      }

      notifyListeners();
    } catch (_) {
      imageFile = null;
      notifyListeners();
    }
  }

  // ================= BRAND -> MODELS =================
  Future<void> getModels(String brand) async {
    isModelLoading = true;

    modelList = [];
    selectedModel = null;

    notifyListeners();

    final result = await _repository.getModelsByBrand(brand);

    modelList = result;

    isModelLoading = false;
    notifyListeners();
  }

  // ================= SETTERS =================
  void setCategory(String? value) {
    selectedCategory = value;
    notifyListeners();
  }

  void setModel(String? value) {
    selectedModel = value;
    notifyListeners();
  }

  void setBrand(String value) {
    selectedBrand = value;

    selectedModel = null;
    modelList = [];

    notifyListeners();
  }

  void setDate(DateTime? date) {
    selectedDate = date;
    notifyListeners();
  }

  void setLastServiceDate(DateTime? date) {
    lastServiceDate = date;
    notifyListeners();
  }

  void setName(String value) {
    name = value;
    notifyListeners();
  }

  void setPrice(String value) {
    price = value;
    notifyListeners();
  }

  void setIssue(String value) {
    issue = value;
    notifyListeners();
  }

  void setYearOfModel(String value) {
    yearOfModel = value;
    notifyListeners();
  }

  void setTotalMileage(String value) {
    totalMileage = value;
    notifyListeners();
  }

  void setLastServiceName(String value) {
    lastServiceName = value;
    notifyListeners();
  }

  // ================= ADD ITEM =================
  Future<bool> addItem() async {
    isLoading = true;
    notifyListeners();

    final result = await _repository.addItem(
      name: name,
      brand: selectedBrand,
      model: selectedModel ?? '',
      category: selectedCategory ?? '',
      purchaseDate: selectedDate?.toIso8601String() ?? '',
      totalMileage: totalMileage,
      yearOfModel: yearOfModel,
      imageFile: imageFile,
    );

    isLoading = false;
    notifyListeners();

    return result;
  }

  // ================= RESET =================
  void clearFields() {
    currentStep = 0;
    selectedCategory = null;
    selectedModel = null;
    selectedBrand = 'Select';
    selectedDate = null;
    lastServiceDate = null;

    name = '';
    price = '';
    issue = '';
    yearOfModel = '';
    totalMileage = '';
    lastServiceName = '';

    imageFile = null;
    modelList = [];

    notifyListeners();
  }
}