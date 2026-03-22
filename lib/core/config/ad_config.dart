import '../config/debug_config.dart';

/// 広告ID設定
///
/// 本番切替時: テストIDを本番IDに変更する
class AdConfig {
  /// 広告を有効にするか
  /// debugMode時は無効にする
  static bool get adsEnabled => !DebugConfig.debugMode;

  // ----- テストID (Google公式) -----

  /// バナー広告テストID
  static const String bannerAdUnitId =
      'ca-app-pub-3940256099942544/6300978111';

  /// リワード広告テストID
  static const String rewardAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';

  // ----- 本番ID (リリース時にここを変更) -----
  // static const String bannerAdUnitId = 'ca-app-pub-XXXX/YYYY';
  // static const String rewardAdUnitId = 'ca-app-pub-XXXX/ZZZZ';
}
