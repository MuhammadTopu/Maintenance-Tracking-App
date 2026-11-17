// PLACE AT: lib/domain/repository/item_and_task_list_repository.dart
// (replaces the existing file)

import '../../data/models/all_item_list_model.dart';
import '../../data/models/one_item_model.dart';
import '../../data/models/task_list_response_model.dart';

abstract class ItemAndTaskListRepository {
  Future<AllItemListModel?> getAllItemsList();

  Future<OneItemModel?> getOneItem({required String itemId});

  Future<TaskListResponse?> getAllTasksList({
    TaskFilter filter = TaskFilter.all,
    int page = 1,
    int limit = kTaskPageSize,
  });

  Future<TaskListResponse?> getTaskListByItemId({
    required String itemId,
    TaskFilter filter = TaskFilter.all,
    int page = 1,
    int limit = kTaskPageSize,
  });

  Future<TaskResponse?> toggleTaskStatus({required String taskId});
}