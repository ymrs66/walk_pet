import 'dart:io';

import '../config/debug_config.dart';

/// 広告ID設定
///
/// iOS: 本番ID / Android: テストID
class AdConfig {
  /// 広告を有効にするか
  /// debugMode時は無効にする
  static bool get adsEnabled => !DebugConfig.debugMode;

  // ----- iOS 本番ID -----
  static const String _iosBannerAdUnitId =
      'ca-app-pub-7942729921826461/8037537268';
  static const String _iosRewardAdUnitId =
      'ca-app-pub-7942729921826461/1336397545';

  // ----- Android テストID (Google公式) -----
  static const String _androidBannerAdUnitId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _androidRewardAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';

  /// バナー広告ユニットID (プラットフォーム別)
  static String get bannerAdUnitId =>
      Platform.isIOS ? _iosBannerAdUnitId : _androidBannerAdUnitId;

  /// リワード広告ユニットID (プラットフォーム別)
  static String get rewardAdUnitId =>
      Platform.isIOS ? _iosRewardAdUnitId : _androidRewardAdUnitId;
}
