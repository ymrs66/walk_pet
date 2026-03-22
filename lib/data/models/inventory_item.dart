/// インベントリアイテムモデル
class InventoryItem {
  final String foodId;
  final int count;

  const InventoryItem({
    required this.foodId,
    this.count = 0,
  });

  InventoryItem copyWith({int? count}) => InventoryItem(
        foodId: foodId,
        count: count ?? this.count,
      );

  Map<String, dynamic> toJson() => {
        'foodId': foodId,
        'count': count,
      };

  factory InventoryItem.fromJson(Map<String, dynamic> json) => InventoryItem(
        foodId: json['foodId'] as String,
        count: json['count'] as int,
      );
}
