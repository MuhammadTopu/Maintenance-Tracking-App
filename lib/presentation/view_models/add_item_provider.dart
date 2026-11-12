import 'package:flutter/foundation.dart';
import '../../core/helper/logger.dart';
import '../../domain/repository/add_items_repository.dart';
import '../../domain/entities/add_item_data.dart';
export '../../domain/entities/add_item_data.dart';

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
    if (isLoading) return false;

    isLoading = true;
    lastAddedItemId = null;
    notifyListeners();

    Log.debug('Adding ${data.category} item: ${data.name}');

    String? itemId;
    try {
      itemId = await _repository.addItem(data);
    } catch (e) {
      Log.error('addItem failed: $e');
    } finally {
      lastAddedItemId = itemId;
      isLoading = false;
      notifyListeners();
    }

    Log.debug('Item added with id: $itemId');
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