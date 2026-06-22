import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:maintenance_genie/core/helper/logger.dart';
import 'package:maintenance_genie/core/services/storage/token_storage_service.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path;

import '../../core/constants/api_end_points.dart';
import '../../domain/base_repository/add_items_repository.dart';
import '../../shared/app_toast.dart';

class AddItemRepositoryImpl implements AddItemRepository {

  @override
  Future<List<String>> getModelsByBrand(String brandName) async {
    final url = Uri.parse(
      'https://vpic.nhtsa.dot.gov/api/vehicles/getmodelsformake/$brandName?format=json',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<String> models = [];

      for (var item in data['Results']) {
        models.add(item['Model_Name']);
      }

      models.sort();
      return models;
    }

    return [];
  }

  @override
  Future<bool> addItem({
    required String name,
    required String brand,
    required String model,
    required String category,
    required String purchaseDate,
    required int? totalMileage,
    required String yearOfModel,
    File? imageFile,
  }) async {
    final token = await TokenStorageService.instance.getToken();
    if (token == null) return false;

    final request = http.MultipartRequest(
      'POST',
      Uri.parse(ApiEndPoints.addItem),
    );

    request.headers['Authorization'] = 'Bearer $token';

    request.fields['name'] = name;
    request.fields['brand'] = brand;
    request.fields['model'] = model;
    request.fields['category'] = category;
    request.fields['purchase_date'] = purchaseDate;

    request.fields['year_of_the_model'] = yearOfModel;

    if (totalMileage != null) {
      request.fields['total_mileage'] = totalMileage.toString();
    }

    if (imageFile != null) {
      final mimeType = lookupMimeType(imageFile.path);
      final fileName = path.basename(imageFile.path);

      request.files.add(
        await http.MultipartFile.fromPath(
          'img',
          imageFile.path,
          filename: fileName,
          contentType: mimeType != null ? MediaType.parse(mimeType) : null,
        ),
      );
    }

    final response = await request.send();

    final responseBody = await response.stream.bytesToString();

    Log.debug('STATUS CODE: ${response.statusCode}');
    Log.debug('RESPONSE BODY: $responseBody');
    Log.debug('REASON PHRASE: ${response.reasonPhrase}');

    final res = response.statusCode >= 200 && response.statusCode < 300;
    if (res == false) {
      final decoded = jsonDecode(responseBody);
      AppToast.showToast(decoded['message'], backgroundColor: Colors.red);
      return false;
    } else {
      AppToast.showToast('Item added successfully');
      return true;
    }
  }
}