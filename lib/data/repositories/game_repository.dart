import '../datasources/local_datasource.dart';
import '../models/pet.dart';
import '../models/inventory_item.dart';
import '../models/daily_reward_state.dart';
import '../models/food.dart';

/// ゲームデータ操作リポジトリ
class GameRepository {
  final LocalDatasource _datasource;

  GameRepository(this._datasource);

  // --- Pet ---

  Pet loadPet() => _datasource.loadPet();

  Future<void> savePet(Pet pet) => _datasource.savePet(pet);

  /// EXPを加算してStageを自動更新
  Future<Pet> addExp(int expAmount) async {
    final pet = loadPet();
    final updated = pet.copyWith(exp: pet.exp + expAmount);
    await savePet(updated);
    return updated;
  }

  // --- Inventory ---

  List<InventoryItem> loadInventory() => _datasource.loadInventory();

  Future<void> saveInventory(List<InventoryItem> items) =>
      _datasource.saveInventory(items);

  /// 食材を1つ追加
  Future<List<InventoryItem>> addFood(String foodId) async {
    final items = loadInventory();
    final index = items.indexWhere((item) => item.foodId == foodId);
    List<InventoryItem> updated;
    if (index >= 0) {
      updated = List.of(items);
      updated[index] = items[index].copyWith(count: items[index].count + 1);
    } else {
      updated = [...items, InventoryItem(foodId: foodId, count: 1)];
    }
    await saveInventory(updated);
    return updated;
  }

  /// 食材を1つ消費。成功時はtrue、在庫不足はfalse。
  Future<({List<InventoryItem> inventory, bool success})> consumeFood(
      String foodId) async {
    final items = loadInventory();
    final index = items.indexWhere((item) => item.foodId == foodId);
    if (index < 0 || items[index].count <= 0) {
      return (inventory: items, success: false);
    }
    final updated = List.of(items);
    final newCount = items[index].count - 1;
    if (newCount <= 0) {
      updated.removeAt(index);
    } else {
      updated[index] = items[index].copyWith(count: newCount);
    }
    await saveInventory(updated);
    return (inventory: updated, success: true);
  }

  // --- DailyRewardState ---

  DailyRewardState loadRewardState() => _datasource.loadRewardState();

  Future<void> saveRewardState(DailyRewardState state) =>
      _datasource.saveRewardState(state);

  /// 報酬を受け取る。未受取かつ歩数条件を満たしている場合のみ成功。
  Future<({DailyRewardState rewardState, List<InventoryItem> inventory, bool success})>
      claimReward(String foodId, int currentSteps) async {
    final food = findFoodById(foodId);
    if (food == null) {
      return (
        rewardState: loadRewardState(),
        inventory: loadInventory(),
        success: false,
      );
    }

    final rewardState = loadRewardState();

    // 既に受け取り済み
    if (rewardState.hasClaimed(foodId)) {
      return (
        rewardState: rewardState,
        inventory: loadInventory(),
        success: false,
      );
    }

    // 歩数条件を満たしていない
    if (currentSteps < food.requiredSteps) {
      return (
        rewardState: rewardState,
        inventory: loadInventory(),
        success: false,
      );
    }

    // 報酬を受け取り
    final updatedRewardState = rewardState.claim(foodId);
    await saveRewardState(updatedRewardState);
    final updatedInventory = await addFood(foodId);

    return (
      rewardState: updatedRewardState,
      inventory: updatedInventory,
      success: true,
    );
  }

  /// 餌やり: 食材消費 + EXP加算 + Stage更新
  Future<({Pet pet, List<InventoryItem> inventory, bool success})> feedPet(
      String foodId) async {
    final food = findFoodById(foodId);
    if (food == null) {
      return (pet: loadPet(), inventory: loadInventory(), success: false);
    }

    final consumeResult = await consumeFood(foodId);
    if (!consumeResult.success) {
      return (
        pet: loadPet(),
        inventory: consumeResult.inventory,
        success: false,
      );
    }

    final updatedPet = await addExp(food.expValue);
    return (
      pet: updatedPet,
      inventory: consumeResult.inventory,
      success: true,
    );
  }

  // --- Onboarding ---

  bool isOnboardingCompleted() => _datasource.isOnboardingCompleted();

  Future<void> setOnboardingCompleted(bool completed) =>
      _datasource.setOnboardingCompleted(completed);
}
