import '../../data/models/all_item_list_model.dart';
import '../../data/models/one_item_model.dart';
import '../../data/models/task_list_response_model.dart';

abstract class ItemAndTaskListRepository {
  Future<AllItemListModel?> getAllItemsList();
  Future<OneItemModel?> getOneItem({required String itemId});
  Future<TaskListResponse?> getAllTasksList();
  Future<TaskListResponse?> getTaskListByItemId({required String itemId});
  Future<bool> toggleTaskStatus({required String taskId});

}
