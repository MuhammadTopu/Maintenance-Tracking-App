import 'package:flutter/material.dart';
import 'package:maintenance_genie/core/helper/logger.dart';
import 'package:maintenance_genie/domain/base_repository/item_and_task_list_repository.dart';

import '../../data/models/all_item_list_model.dart';
import '../../data/models/one_item_model.dart';

class AllItemListProvider extends ChangeNotifier {
  final ItemAndTaskListRepository _repository;

  AllItemListProvider(this._repository);

  bool _loading = false;
  String? _error1 = '';
  String? _error2 = '';

  bool get loading => _loading;
  String? get errorFetchingAllItems => _error1;
  String? get errorFetchingOneItem => _error2;

  void setLoading(bool loading) {
    _loading = loading;
    notifyListeners();
  }

  void setError1(String error) {
    _error1 = error;
    notifyListeners();
  }

  void setError2(String error) {
    _error2 = error;
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
      Log.error('-------------Failed to fetch items-------------');
      setError1('Failed to fetch items');
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
    } else {
      setError2('Failed to fetch item');
    }

    setLoading(false);
  }

  void removeItems() {
    _allItemListModel?.items?.clear();
    notifyListeners();
  }
}
