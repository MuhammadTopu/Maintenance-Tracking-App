import '../../data/models/guided_answer_model.dart';
import '../../data/models/guided_question_model.dart';
import '../../data/models/question_response_model.dart';
import '../entities/add_item_data.dart';

abstract class AddItemRepository {
  Future<List<String>> getModelsByBrand(String brandName);

  Future<String?> addItem(AddItemData data);

  Future<QuestionsResponse?> getQuestion(String id);

  Future<QuestionsResponse?> answerQuestions({
    required String itemId,
    required List<String> answers,
  });

  Future<GuidedQuestionsResponse?> getGuidedQuestions(String itemId);

  Future<GuidedQuestionsResponse?> submitGuidedAnswers({
    required String itemId,
    required List<GuidedAnswer> answers,
  });

  Future<bool> generateTasks({required String itemId});
}