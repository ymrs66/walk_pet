import '../../data/models/food.dart';

/// 食材ごとの絵文字
String foodEmoji(String foodId) {
  switch (foodId) {
    case 'kinomi':
      return '🫐';
    case 'ninjin':
      return '🥕';
    case 'osakana':
      return '🐟';
    default:
      return '🍽️';
  }
}

/// 餌やり時のリアクション文言
///
/// 差し替え・追加しやすいよう Map で管理。
/// 将来はランダム選択やペット種別で分岐も可能。
const Map<String, String> feedingReactions = {
  'kinomi': 'しゃくしゃく食べた！',
  'ninjin': 'うれしそうに食べた！',
  'osakana': '大好物みたい！',
};

/// 食材IDからリアクション文言を取得
String getFeedingReaction(String foodId) {
  return feedingReactions[foodId] ?? 'もぐもぐ食べた！';
}

/// 報酬の残り歩数メッセージ
String stepsRemainingMessage(Food food, int currentSteps) {
  final remaining = food.requiredSteps - currentSteps;
  if (remaining <= 0) return '達成！';
  return 'あと $remaining歩';
}

/// 食材の説明文を取得 (世界観)
String foodDescription(String foodId) {
  final food = findFoodById(foodId);
  return food?.description ?? '';
}
