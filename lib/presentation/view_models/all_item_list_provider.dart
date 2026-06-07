import 'package:flutter/material.dart';
import 'package:maintenance_genie/core/helper/logger.dart';
import 'package:maintenance_genie/domain/base_repository/item_and_task_list_repository.dart';

import '../../data/models/all_item_list_model.dart';
import '../../data/models/one_item_model.dart';

class AllItemListProvider extends ChangeNotifier {
  final ItemAndTaskListRepository _repository;

  AllItemListProvider(this._repository);

  bool _loading = false;
  String _error = '';

  bool get loading => _loading;
  String get error => _error;

  void setLoading(bool loading) {
    _loading = loading;
    notifyListeners();
  }

  void setError(String error) {
    _error = error;
    notifyListeners();
  }

  AllItemListModel? _allItemListModel = AllItemListModel();
  AllItemListModel? get allItemListModel => _allItemListModel;
  OneItemModel? _oneItemModel;
  OneItemModel? get oneItemModel => _oneItemModel;

  Future<void> getAllItem() async {
    setLoading(true);

    final response = await _repository.getAllItemsList();

    if (response != null) {
      _allItemListModel = response;
      notifyListeners();
    } else {
      setError('Failed to fetch items');
    }

    setLoading(false);
  }

  void setId(String id) {
    Log.info('The single product id: $id');
    getOneItem(id);
  }

  Future<void> getOneItem(String itemId) async {
    setLoading(true);

    final response = await _repository.getOneItem(itemId: itemId);

    if (response != null) {
      _oneItemModel = response;
      notifyListeners();
    }

    setLoading(false);
  }

  void removeItems() {
    _allItemListModel?.items?.clear();
    notifyListeners();
  }
}
