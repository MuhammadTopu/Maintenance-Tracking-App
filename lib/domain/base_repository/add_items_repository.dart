import 'dart:io';

import '../../data/models/question_response_model.dart';
import '../../data/models/task_list_response_model.dart';

abstract class AddItemRepository {
  Future<List<String>> getModelsByBrand(String brandName);

  Future<String?> addItem({
    required String name,
    required String brand,
    required String model,
    required String category,
    required String purchaseDate,
    required int? totalMileage,
    required String yearOfModel,
    File? imageFile,
    String? engine,
    String? transmission,
    String? drivetrain,
    int? currentMileage,
    int? averageMileagePerYear,
    String? userNotes,
  });

  Future<QuestionsResponse?> getQuestion(String id);

  Future<GenerateTaskResponse?> answerQuestions({
    required String itemId,
    required List<String> answers,
  });
}