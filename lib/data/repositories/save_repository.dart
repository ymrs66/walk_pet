import '../datasources/local_datasource.dart';
import '../models/pet.dart';
import '../models/inventory_item.dart';
import '../models/daily_reward_state.dart';

/// ローカル保存の抽象化レイヤー
///
/// 将来的にクラウド保存等への拡張が容易になるよう、
/// LocalDatasourceをラップして保存操作を提供する。
class SaveRepository {
  final LocalDatasource _datasource;

  SaveRepository(this._datasource);

  // --- Save ---

  Future<void> savePet(Pet pet) => _datasource.savePet(pet);

  Future<void> saveInventory(List<InventoryItem> items) =>
      _datasource.saveInventory(items);

  Future<void> saveRewardState(DailyRewardState state) =>
      _datasource.saveRewardState(state);

  // --- Load ---

  Pet loadPet() => _datasource.loadPet();

  List<InventoryItem> loadInventory() => _datasource.loadInventory();

  DailyRewardState loadRewardState() => _datasource.loadRewardState();

  // --- Utility ---

  /// 全データを保存
  Future<void> saveAll({
    required Pet pet,
    required List<InventoryItem> inventory,
    required DailyRewardState rewardState,
  }) async {
    await Future.wait([
      savePet(pet),
      saveInventory(inventory),
      saveRewardState(rewardState),
    ]);
  }
}
