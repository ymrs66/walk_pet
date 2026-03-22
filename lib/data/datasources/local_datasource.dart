import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pet.dart';
import '../models/inventory_item.dart';
import '../models/daily_reward_state.dart';

/// SharedPreferencesを使ったローカルデータソース
class LocalDatasource {
  static const _petKey = 'pet_data';
  static const _inventoryKey = 'inventory_data';
  static const _rewardStateKey = 'reward_state_data';
  static const _onboardingKey = 'onboarding_completed';
  static const _introShownKey = 'intro_shown';
  static const _lastFedAtKey = 'last_fed_at';

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
}
