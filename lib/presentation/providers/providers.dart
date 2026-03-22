import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/datasources/local_datasource.dart';
import '../../data/datasources/health_datasource.dart';
import '../../data/repositories/health_repository.dart';
import '../../data/repositories/game_repository.dart';
import '../../data/repositories/save_repository.dart';
import '../../core/config/debug_config.dart';
import '../../core/pet_dialogue_resolver.dart';
import '../../data/models/step_state.dart';
import '../../data/models/pet.dart';
import '../../data/models/pet_emotion.dart';
import '../../data/models/inventory_item.dart';
import '../../data/models/daily_reward_state.dart';
import '../../data/models/health_permission_status.dart';
import '../../data/models/food.dart';
import '../../data/models/streak_state.dart';
import '../../domain/services/reward_service.dart';
import '../../domain/services/emotion_service.dart';
import '../../domain/services/streak_service.dart';

// =============================================================
// Core Providers (依存注入)
// =============================================================

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden at startup');
});

final localDatasourceProvider = Provider<LocalDatasource>((ref) {
  return LocalDatasource(ref.watch(sharedPreferencesProvider));
});

final healthDatasourceProvider = Provider<HealthDatasource>((ref) {
  return HealthDatasource();
});

/// HealthRepository の切替:
///   AppMode.dev        → DummyHealthRepository (ダミー歩数)
///   AppMode.testFlight → RealHealthRepository  (実歩数)
///   AppMode.release    → RealHealthRepository  (実歩数)
/// 切替は DebugConfig.currentMode を変更するだけでOK。
final healthRepositoryProvider = Provider<HealthRepository>((ref) {
  if (DebugConfig.debugMode && DebugConfig.useDummyHealth) {
    return DummyHealthRepository(dummySteps: DebugConfig.dummySteps);
  }
  return RealHealthRepository(ref.watch(healthDatasourceProvider));
});

final gameRepositoryProvider = Provider<GameRepository>((ref) {
  return GameRepository(ref.watch(localDatasourceProvider));
});

final saveRepositoryProvider = Provider<SaveRepository>((ref) {
  return SaveRepository(ref.watch(localDatasourceProvider));
});

// =============================================================
// Onboarding Provider
// =============================================================

class OnboardingNotifier extends StateNotifier<bool> {
  final GameRepository _gameRepo;

  OnboardingNotifier(this._gameRepo)
      : super(_gameRepo.isOnboardingCompleted());

  Future<void> complete() async {
    await _gameRepo.setOnboardingCompleted(true);
    state = true;
  }
}

final onboardingCompletedProvider =
    StateNotifierProvider<OnboardingNotifier, bool>((ref) {
  return OnboardingNotifier(ref.watch(gameRepositoryProvider));
});

// =============================================================
// Intro Provider
// =============================================================

class IntroNotifier extends StateNotifier<bool> {
  final LocalDatasource _datasource;

  IntroNotifier(this._datasource) : super(_datasource.isIntroShown());

  Future<void> markShown() async {
    await _datasource.setIntroShown(true);
    state = true;
  }
}

final introShownProvider =
    StateNotifierProvider<IntroNotifier, bool>((ref) {
  return IntroNotifier(ref.watch(localDatasourceProvider));
});

// =============================================================
// Health Permission Provider
// =============================================================

class HealthPermissionNotifier extends StateNotifier<HealthPermissionStatus> {
  final HealthRepository _healthRepo;
  bool _requesting = false; // 多重実行防止

  HealthPermissionNotifier(this._healthRepo)
      : super(HealthPermissionStatus.unknown);

  /// 権限状態を確認するだけ（ダイアログは出さない）
  Future<void> check() async {
    final result = await _healthRepo.checkPermissionStatus();
    debugPrint('[HealthPermission] check() → $result');
    state = result;
  }

  /// requestAuthorization を実行（ダイアログが出る可能性あり）
  Future<HealthPermissionStatus> request() async {
    if (_requesting) {
      debugPrint('[HealthPermission] request() スキップ（実行中）');
      return state;
    }
    _requesting = true;
    try {
      final result = await _healthRepo.requestPermission();
      debugPrint('[HealthPermission] request() → $result');
      state = result;
      return result;
    } finally {
      _requesting = false;
    }
  }

  /// 初回起動用: check → 未許可なら自動で request（1回だけ）
  Future<void> ensureAuthorized() async {
    final checkResult = await _healthRepo.checkPermissionStatus();
    debugPrint('[HealthPermission] ensureAuthorized() check → $checkResult');
    state = checkResult;

    if (checkResult != HealthPermissionStatus.granted) {
      debugPrint('[HealthPermission] ensureAuthorized() → request 実行');
      await request();
    }
  }
}

final healthPermissionProvider = StateNotifierProvider<
    HealthPermissionNotifier, HealthPermissionStatus>((ref) {
  return HealthPermissionNotifier(ref.watch(healthRepositoryProvider));
});

// =============================================================
// Step Provider
// =============================================================

final stepProvider = FutureProvider.autoDispose<StepState>((ref) async {
  final repo = ref.watch(healthRepositoryProvider);
  return repo.getTodaySteps();
});

// =============================================================
// Pet Provider
// =============================================================

class PetNotifier extends StateNotifier<Pet> {
  final GameRepository _gameRepo;

  PetNotifier(this._gameRepo) : super(_gameRepo.loadPet());

  void refresh() {
    state = _gameRepo.loadPet();
  }
}

final petProvider = StateNotifierProvider<PetNotifier, Pet>((ref) {
  return PetNotifier(ref.watch(gameRepositoryProvider));
});

// =============================================================
// Emotion Provider — 最終餌やり時刻から判定
// =============================================================

class EmotionNotifier extends StateNotifier<PetEmotion> {
  final LocalDatasource _datasource;
  DateTime? _debugOverride;

  EmotionNotifier(this._datasource)
      : super(EmotionService.resolve(_datasource.loadLastFedAt()));

  /// 餌やり時に呼ぶ → happy に遷移
  Future<void> onFed() async {
    final now = DateTime.now();
    await _datasource.saveLastFedAt(now);
    _debugOverride = null;
    state = PetEmotion.happy;
  }

  /// 時間経過による再判定
  void refresh() {
    if (_debugOverride != null) return; // デバッグ上書き中は更新しない
    state = EmotionService.resolve(_datasource.loadLastFedAt());
  }

  /// デバッグ: 感情を直接設定
  void debugSetEmotion(PetEmotion emotion) {
    _debugOverride = DateTime.now();
    state = emotion;
  }
}

final emotionProvider =
    StateNotifierProvider<EmotionNotifier, PetEmotion>((ref) {
  return EmotionNotifier(ref.watch(localDatasourceProvider));
});

// =============================================================
// Inventory Provider
// =============================================================

class InventoryNotifier extends StateNotifier<List<InventoryItem>> {
  final GameRepository _gameRepo;

  InventoryNotifier(this._gameRepo) : super(_gameRepo.loadInventory());

  void refresh() {
    state = _gameRepo.loadInventory();
  }
}

final inventoryProvider =
    StateNotifierProvider<InventoryNotifier, List<InventoryItem>>((ref) {
  return InventoryNotifier(ref.watch(gameRepositoryProvider));
});

// =============================================================
// Reward Provider
// =============================================================

class RewardNotifier extends StateNotifier<DailyRewardState> {
  final GameRepository _gameRepo;

  RewardNotifier(this._gameRepo) : super(_gameRepo.loadRewardState());

  void refresh() {
    state = _gameRepo.loadRewardState();
  }
}

final rewardStateProvider =
    StateNotifierProvider<RewardNotifier, DailyRewardState>((ref) {
  return RewardNotifier(ref.watch(gameRepositoryProvider));
});

// =============================================================
// Streak Provider
// =============================================================

class StreakNotifier extends StateNotifier<StreakState> {
  final LocalDatasource _datasource;

  StreakNotifier(this._datasource) : super(_datasource.loadStreak());

  /// streak を更新 (歩数取得時に呼ばれる)
  Future<List<StreakBonus>> updateToday(int todaySteps) async {
    final todayDate = StreakState.dateStringFrom(DateTime.now());
    final updated = StreakService.updateStreak(state, todaySteps, todayDate);

    if (updated.lastSuccessDate != state.lastSuccessDate ||
        updated.currentStreak != state.currentStreak) {
      // streak が変化した場合のみ保存
      await _datasource.saveStreak(updated);
      state = updated;
    }

    // ボーナスチェック
    final bonusResult = StreakService.checkBonus(state);
    return bonusResult.bonuses;
  }

  /// ボーナスを受取済みにする
  Future<void> claimBonus(StreakBonus bonus) async {
    final updated = StreakService.claimBonus(state, bonus);
    await _datasource.saveStreak(updated);
    state = updated;
  }

  void refresh() {
    state = _datasource.loadStreak();
  }
}

final streakProvider =
    StateNotifierProvider<StreakNotifier, StreakState>((ref) {
  return StreakNotifier(ref.watch(localDatasourceProvider));
});

// =============================================================
// Reward Status Provider
// =============================================================

final rewardStatusListProvider = Provider<List<RewardStatus>>((ref) {
  final stepAsync = ref.watch(stepProvider);
  final rewardState = ref.watch(rewardStateProvider);

  return stepAsync.when(
    data: (stepState) =>
        RewardService.getAllRewardStatuses(stepState.steps, rewardState),
    loading: () => [],
    error: (_, _) => [],
  );
});

// =============================================================
// Dialogue Context Provider
// =============================================================

final dialogueContextProvider = Provider<DialogueContext>((ref) {
  final rewardStatuses = ref.watch(rewardStatusListProvider);
  final streak = ref.watch(streakProvider);

  // 受取可能報酬があれば最優先
  final hasAvailable =
      rewardStatuses.any((rs) => rs.status == RewardStatusType.available);
  if (hasAvailable) return DialogueContext.rewardAvailable;

  // 連続達成中 (2日以上)
  if (streak.currentStreak >= 2) return DialogueContext.onStreak;

  return DialogueContext.normal;
});

// =============================================================
// Game Actions
// =============================================================

final gameActionsProvider = Provider<GameActions>((ref) {
  return GameActions(ref);
});

class GameActions {
  final Ref _ref;

  GameActions(this._ref);

  GameRepository get _gameRepo => _ref.read(gameRepositoryProvider);

  Future<bool> claimReward(String foodId) async {
    final stepState = await _ref.read(stepProvider.future);
    final result = await _gameRepo.claimReward(foodId, stepState.steps);

    if (result.success) {
      _ref.read(rewardStateProvider.notifier).refresh();
      _ref.read(inventoryProvider.notifier).refresh();
    }

    return result.success;
  }

  /// 餌やり — 成功時に emotion も happy にする
  Future<bool> feedPet(String foodId) async {
    final result = await _gameRepo.feedPet(foodId);

    if (result.success) {
      _ref.read(petProvider.notifier).refresh();
      _ref.read(inventoryProvider.notifier).refresh();
      await _ref.read(emotionProvider.notifier).onFed();
    }

    return result.success;
  }

  void refreshSteps() {
    _ref.invalidate(stepProvider);
  }

  /// streak を更新し、ボーナスがあれば付与
  Future<List<StreakBonus>> checkAndUpdateStreak() async {
    final stepState = await _ref.read(stepProvider.future);
    final bonuses =
        await _ref.read(streakProvider.notifier).updateToday(stepState.steps);

    // ボーナス付与
    for (final bonus in bonuses) {
      await _gameRepo.addFood('kinomi'); // きのみ1個
      await _ref.read(streakProvider.notifier).claimBonus(bonus);
    }
    if (bonuses.isNotEmpty) {
      _ref.read(inventoryProvider.notifier).refresh();
    }

    return bonuses;
  }

  // =============================================================
  // Debug Actions
  // =============================================================

  Future<void> debugResetRewards() async {
    await _gameRepo.saveRewardState(DailyRewardState.today());
    _ref.read(rewardStateProvider.notifier).refresh();
  }

  Future<void> debugAddExp(int amount) async {
    await _gameRepo.addExp(amount);
    _ref.read(petProvider.notifier).refresh();
  }

  Future<void> debugAddAllFoods() async {
    for (final food in allFoods) {
      await _gameRepo.addFood(food.id);
    }
    _ref.read(inventoryProvider.notifier).refresh();
  }

  void debugSetEmotion(PetEmotion emotion) {
    _ref.read(emotionProvider.notifier).debugSetEmotion(emotion);
  }
}
