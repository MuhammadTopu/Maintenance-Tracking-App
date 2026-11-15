import 'item.dart';
export 'item.dart';

class OneItemModel {
  final bool success;
  final String message;
  final Item item;

  OneItemModel({
    required this.success,
    required this.message,
    required this.item,
  });

  factory OneItemModel.fromJson(Map<String, dynamic> json) {
    final rawItem = json['item'];
    return OneItemModel(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      item: Item.fromJson(
        rawItem is Map ? Map<String, dynamic>.from(rawItem) : <String, dynamic>{},
      ),
    );
  }
}