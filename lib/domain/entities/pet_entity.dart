import '../../data/models/pet.dart';

/// ペットエンティティのドメインロジック
class PetEntity {
  /// EXP値からStageを判定
  static PetStage stageFromExp(int exp) => Pet.stageFromExp(exp);

  /// EXPを加算して成長判定
  static Pet applyExp(Pet pet, int expAmount) {
    return pet.copyWith(exp: pet.exp + expAmount);
  }

  /// 次のStageまでに必要なEXP
  static int expToNextStage(Pet pet) {
    switch (pet.stage) {
      case PetStage.stage1:
        return 5 - pet.exp; // Stage2は EXP 5
      case PetStage.stage2:
        return 12 - pet.exp; // Stage3は EXP 12
      case PetStage.stage3:
        return 0; // 最大Stage
    }
  }

  /// 現在Stageの進捗率 (0.0 〜 1.0)
  static double stageProgress(Pet pet) {
    switch (pet.stage) {
      case PetStage.stage1:
        return pet.exp / 5; // 0〜4 → 0.0〜0.8
      case PetStage.stage2:
        return (pet.exp - 5) / 7; // 5〜11 → 0.0〜0.86
      case PetStage.stage3:
        return 1.0; // 最大Stage
    }
  }

  /// 現在Stageの次のStage表示名
  static String? nextStageLabel(Pet pet) {
    switch (pet.stage) {
      case PetStage.stage1:
        return 'ひよこ';
      case PetStage.stage2:
        return 'げんきどり';
      case PetStage.stage3:
        return null; // 最大Stage
    }
  }
}
