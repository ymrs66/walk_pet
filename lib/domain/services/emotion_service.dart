import '../../data/models/pet_emotion.dart';

/// 最終餌やり時刻から感情を判定するサービス
///
/// 判定ルール:
/// - 1時間以内: happy
/// - 1時間超〜6時間以内: normal
/// - 6時間超 or 未餌やり: hungry
class EmotionService {
  /// happy → normal に変わるまでの時間
  static const Duration happyDuration = Duration(hours: 1);

  /// normal → hungry に変わるまでの時間
  static const Duration hungryThreshold = Duration(hours: 6);

  /// 最終餌やり時刻から感情を判定
  static PetEmotion resolve(DateTime? lastFedAt) {
    if (lastFedAt == null) return PetEmotion.hungry;

    final elapsed = DateTime.now().difference(lastFedAt);

    if (elapsed <= happyDuration) return PetEmotion.happy;
    if (elapsed <= hungryThreshold) return PetEmotion.normal;
    return PetEmotion.hungry;
  }
}
