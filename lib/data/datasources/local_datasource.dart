import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pet.dart';
import '../models/inventory_item.dart';
import '../models/daily_reward_state.dart';
import '../models/streak_state.dart';

/// SharedPreferencesを使ったローカルデータソース
class LocalDatasource {
  static const _petKey = 'pet_data';
  static const _inventoryKey = 'inventory_data';
  static const _rewardStateKey = 'reward_state_data';
  static const _onboardingKey = 'onboarding_completed';
  static const _introShownKey = 'intro_shown';
  static const _lastFedAtKey = 'last_fed_at';
  static const _streakKey = 'streak_data';
  static const _lifetimeStepsKey = 'lifetime_steps_total';
  static const _snapshotDateKey = 'daily_step_snapshot_date';
  static const _snapshotValueKey = 'daily_step_snapshot_value';

  final SharedPreferences _prefs;

  LocalDatasource(this._prefs);

  // --- Pet ---

  Future<void> savePet(Pet pet) async {
    await _prefs.setString(_petKey, jsonEncode(pet.toJson()));
  }

  Pet loadPet() {
    final json = _prefs.getString(_petKey);
    if (json == null) return Pet.defaultPet;
    return Pet.fromJson(jsonDecode(json) as Map<String, dynamic>);
  }

  // --- Inventory ---

  Future<void> saveInventory(List<InventoryItem> items) async {
    final jsonList = items.map((item) => item.toJson()).toList();
    await _prefs.setString(_inventoryKey, jsonEncode(jsonList));
  }

  List<InventoryItem> loadInventory() {
    final json = _prefs.getString(_inventoryKey);
    if (json == null) return [];
    final list = jsonDecode(json) as List;
    return list
        .map((e) => InventoryItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // --- DailyRewardState ---

  Future<void> saveRewardState(DailyRewardState state) async {
    await _prefs.setString(_rewardStateKey, jsonEncode(state.toJson()));
  }

  DailyRewardState loadRewardState() {
    final json = _prefs.getString(_rewardStateKey);
    if (json == null) return DailyRewardState.today();
    final state = DailyRewardState.fromJson(
        jsonDecode(json) as Map<String, dynamic>);
    // 日付が変わっていたらリセット
    if (!state.isToday) return DailyRewardState.today();
    return state;
  }

  // --- Onboarding ---

  Future<void> setOnboardingCompleted(bool completed) async {
    await _prefs.setBool(_onboardingKey, completed);
  }

  bool isOnboardingCompleted() {
    return _prefs.getBool(_onboardingKey) ?? false;
  }

  // --- Intro ---

  Future<void> setIntroShown(bool shown) async {
    await _prefs.setBool(_introShownKey, shown);
  }

  bool isIntroShown() {
    return _prefs.getBool(_introShownKey) ?? false;
  }

  // --- Last Fed At ---

  Future<void> saveLastFedAt(DateTime time) async {
    await _prefs.setString(_lastFedAtKey, time.toIso8601String());
  }

  DateTime? loadLastFedAt() {
    final str = _prefs.getString(_lastFedAtKey);
    if (str == null) return null;
    return DateTime.tryParse(str);
  }

  // --- Streak ---

  Future<void> saveStreak(StreakState state) async {
    await _prefs.setString(_streakKey, jsonEncode(state.toJson()));
  }

  StreakState loadStreak() {
    final json = _prefs.getString(_streakKey);
    if (json == null) return const StreakState();
    return StreakState.fromJson(jsonDecode(json) as Map<String, dynamic>);
  }

  // --- Step Snapshot (総歩数) ---

  /// 総歩数を取得
  int loadLifetimeSteps() => _prefs.getInt(_lifetimeStepsKey) ?? 0;

  /// 総歩数を保存
  Future<void> saveLifetimeSteps(int total) async {
    await _prefs.setInt(_lifetimeStepsKey, total);
  }

  /// 日次スナップショットの日付 (yyyy-MM-dd)
  String? loadSnapshotDate() => _prefs.getString(_snapshotDateKey);

  /// 日次スナップショットの歩数値
  int loadSnapshotValue() => _prefs.getInt(_snapshotValueKey) ?? 0;

  /// 日次スナップショットを保存
  Future<void> saveSnapshot(String date, int steps) async {
    await _prefs.setString(_snapshotDateKey, date);
    await _prefs.setInt(_snapshotValueKey, steps);
  }

  // --- Reset ---

  /// ゲームデータを全初期化する。
  ///
  /// 以下は **残す**（再表示しない）:
  /// - オンボーディング完了フラグ (_onboardingKey)
  /// - イントロ表示済みフラグ (_introShownKey)
  /// - 広告ブートストラップフラグ (ads_bootstrap_done)
  Future<void> resetAll() async {
    await _prefs.remove(_petKey);
    await _prefs.remove(_inventoryKey);
    await _prefs.remove(_rewardStateKey);
    await _prefs.remove(_lastFedAtKey);
    await _prefs.remove(_streakKey);
    await _prefs.remove(_lifetimeStepsKey);
    await _prefs.remove(_snapshotDateKey);
    await _prefs.remove(_snapshotValueKey);
  }
}
