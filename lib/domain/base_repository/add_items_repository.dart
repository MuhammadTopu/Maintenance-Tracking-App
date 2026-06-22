import 'dart:io';
abstract class AddItemRepository {
  Future<List<String>> getModelsByBrand(String brandName);

  Future<bool> addItem({
    required String name,
    required String brand,
    required String model,
    required String category,
    required String purchaseDate,
    required int? totalMileage,
    required String yearOfModel,
    File? imageFile,
  });
}