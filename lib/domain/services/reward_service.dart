import '../../data/models/food.dart';
import '../../data/models/daily_reward_state.dart';

/// 報酬判定に関するドメインロジック
class RewardService {
  /// 現在の歩数で受取可能な報酬一覧を返す
  /// (未受取のもののみ)
  static List<Food> getAvailableRewards(
      int currentSteps, DailyRewardState rewardState) {
    return allFoods.where((food) {
      return currentSteps >= food.requiredSteps &&
          !rewardState.hasClaimed(food.id);
    }).toList();
  }

  /// 全報酬の状態を返す (受取済み、受取可能、未到達)
  static List<RewardStatus> getAllRewardStatuses(
      int currentSteps, DailyRewardState rewardState) {
    return allFoods.map((food) {
      if (rewardState.hasClaimed(food.id)) {
        return RewardStatus(food: food, status: RewardStatusType.claimed);
      }
      if (currentSteps >= food.requiredSteps) {
        return RewardStatus(food: food, status: RewardStatusType.available);
      }
      return RewardStatus(food: food, status: RewardStatusType.locked);
    }).toList();
  }
}

enum RewardStatusType {
  claimed, // 受取済み
  available, // 受取可能
  locked, // 未到達
}

class RewardStatus {
  final Food food;
  final RewardStatusType status;

  const RewardStatus({required this.food, required this.status});
}
