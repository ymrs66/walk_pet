import '../../data/models/pet.dart';

/// ペットの Stage ごとの世界観設定を1箇所に集約
///
/// hitokoto は PetDialogueResolver に移行 (emotion 対応)
/// 画像は PetAssetResolver に移行 (stage × emotion 対応)
class PetStageConfig {
  final PetStage stage;
  final String emoji;
  final String label;
  final String description;

  const PetStageConfig({
    required this.stage,
    required this.emoji,
    required this.label,
    required this.description,
  });

  /// Stage別の設定を取得
  static PetStageConfig forStage(PetStage stage) {
    return _configs[stage]!;
  }

  static const Map<PetStage, PetStageConfig> _configs = {
    PetStage.stage1: PetStageConfig(
      stage: PetStage.stage1,
      emoji: '🥚',
      label: 'たまご',
      description: 'おさんぽエネルギーで あたたまっている',
    ),
    PetStage.stage2: PetStageConfig(
      stage: PetStage.stage2,
      emoji: '🐣',
      label: 'ひよこ',
      description: 'げんきいっぱいの まいにち',
    ),
    PetStage.stage3: PetStageConfig(
      stage: PetStage.stage3,
      emoji: '🐓',
      label: 'げんきどり',
      description: 'たくさん歩いて りっぱに育った',
    ),
  };
}
