import '../../data/models/pet.dart';
import '../../data/models/pet_emotion.dart';

/// stage × emotion から画像アセットパスを解決する
///
/// 命名規則: assets/images/pet/{stage}_{emotion}.png
/// フォールバック: emotion画像なし → normal → 絵文字
class PetAssetResolver {
  /// アセットベースパス
  static const String _basePath = 'assets/images/pet';

  /// stage × emotion → アセットパス
  /// 画像ファイルが存在しない可能性があるため、呼び出し側でエラーハンドリングすること
  static String assetPath(PetStage stage, PetEmotion emotion) {
    return '$_basePath/${_stageName(stage)}_${emotion.name}.png';
  }

  /// フォールバック用: normal のアセットパス
  static String normalAssetPath(PetStage stage) {
    return '$_basePath/${_stageName(stage)}_normal.png';
  }

  /// Stage名 (ファイル名用)
  static String _stageName(PetStage stage) {
    switch (stage) {
      case PetStage.stage1:
        return 'stage1';
      case PetStage.stage2:
        return 'stage2';
      case PetStage.stage3:
        return 'stage3';
    }
  }

  /// 全ステージ × 全感情のアセットパスリスト (pubspec.yaml 参考用)
  static List<String> allAssetPaths() {
    final paths = <String>[];
    for (final stage in PetStage.values) {
      for (final emotion in PetEmotion.values) {
        paths.add(assetPath(stage, emotion));
      }
    }
    return paths;
  }
}
