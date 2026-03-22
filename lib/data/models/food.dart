/// 食材モデル
class Food {
  final String id;
  final String name;
  final int expValue;
  final int requiredSteps;
  final String description; // 世界観サブ文言

  const Food({
    required this.id,
    required this.name,
    required this.expValue,
    required this.requiredSteps,
    this.description = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'expValue': expValue,
        'requiredSteps': requiredSteps,
      };

  factory Food.fromJson(Map<String, dynamic> json) => Food(
        id: json['id'] as String,
        name: json['name'] as String,
        expValue: json['expValue'] as int,
        requiredSteps: json['requiredSteps'] as int,
      );
}

/// マスターデータ: 全食材一覧
const List<Food> allFoods = [
  Food(
    id: 'kinomi',
    name: 'きのみ',
    expValue: 1,
    requiredSteps: 1000,
    description: 'ちいさな森のめぐみ',
  ),
  Food(
    id: 'ninjin',
    name: 'にんじん',
    expValue: 3,
    requiredSteps: 3000,
    description: 'あまくて元気が出る',
  ),
  Food(
    id: 'osakana',
    name: 'おさかな',
    expValue: 5,
    requiredSteps: 5000,
    description: 'ちょっと特別なごちそう',
  ),
];

/// IDから食材を検索
Food? findFoodById(String id) {
  try {
    return allFoods.firstWhere((f) => f.id == id);
  } catch (_) {
    return null;
  }
}
