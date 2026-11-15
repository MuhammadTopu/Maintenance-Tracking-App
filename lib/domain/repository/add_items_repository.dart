import '../../data/models/guided_answer_model.dart';
import '../../data/models/guided_question_model.dart';
import '../../data/models/question_response_model.dart';
import '../entities/add_item_data.dart';

abstract class AddItemRepository {
  Future<List<String>> getModelsByBrand(String brandName);

  Future<String?> addItem(AddItemData data);

  // ---- Vehicle: Yes / No / Planned questions with recommendations ----

  Future<QuestionsResponse?> getQuestion(String id);

  Future<QuestionsResponse?> answerQuestions({
    required String itemId,
    required List<String> answers,
  });

  // ---- Home and Other: typed questions in rounds, no recommendations ----

  /// `GET /items/:id/questions` for a Home or Other item.
  Future<GuidedQuestionsResponse?> getGuidedQuestions(String itemId);

  /// `POST /items/:id/submit-answers` for a Home or Other item. Returns the
  /// next round (empty `questions` when there is nothing left to ask).
  Future<GuidedQuestionsResponse?> submitGuidedAnswers({
    required String itemId,
    required List<GuidedAnswer> answers,
  });

  // ---- All categories ----

  Future<bool> generateTasks({required String itemId});
}