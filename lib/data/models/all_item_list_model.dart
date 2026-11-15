import 'item.dart';
export 'item.dart';

typedef Items = Item;

class AllItemListModel {
  final bool success;
  final String message;
  final List<Item> items;

  AllItemListModel({
    required this.success,
    required this.message,
    required this.items,
  });

  factory AllItemListModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    return AllItemListModel(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      items: rawItems is List
          ? [
        for (final element in rawItems)
          if (element is Map)
            Item.fromJson(Map<String, dynamic>.from(element)),
      ]
          : <Item>[],
    );
  }
}