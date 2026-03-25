import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import '../../core/config/ad_config.dart';

/// 広告ブートストラップサービス
///
/// ATT → AdMob初期化 の順序を保証する。
/// - iOS: 初回のみ事前説明 → ATTリクエスト → MobileAds.init
/// - Android: MobileAds.init のみ
/// - TestFlight/dev (adsEnabled == false): 何もしない
class AdsBootstrapService {
  static bool _initialized = false;
  static bool _initializing = false;

  /// 広告SDKが初期化済みか
  static bool get isInitialized => _initialized;

  static const _prefKey = 'ads_bootstrap_done';

  /// 広告SDKを初期化する（1回のみ）
  ///
  /// [context] は ATT 事前説明ダイアログ表示に必要。
  /// [prefs] を渡すと SharedPreferences.getInstance() の重複取得を省略できる。
  /// 複数回呼んでも安全（初期化済みなら即 return）。
  static Future<void> ensureInitialized(
    BuildContext context, {
    SharedPreferences? prefs,
  }) async {
    if (_initialized || !AdConfig.adsEnabled) return;
    if (_initializing) return; // 多重実行防止
    _initializing = true;

    try {
      final sp = prefs ?? await SharedPreferences.getInstance();
      final alreadyBootstrapped = sp.getBool(_prefKey) ?? false;

      // iOS: 初回のみ ATT 処理
      if (Platform.isIOS && !alreadyBootstrapped) {
        // 事前説明ダイアログ
        if (context.mounted) {
          await _showAttExplanationDialog(context);
        }

        // ATT リクエスト (OS標準ダイアログ)
        await AppTrackingTransparency.requestTrackingAuthorization();
      }

      // AdMob 初期化
      if (Platform.isIOS || Platform.isAndroid) {
        await MobileAds.instance.initialize();
      }

      _initialized = true;
      await sp.setBool(_prefKey, true);
      debugPrint('[AdsBootstrap] 初期化完了');
    } finally {
      _initializing = false;
    }
  }

  /// ATT 事前説明ダイアログ
  ///
  /// OS標準の ATT ダイアログの前に、なぜトラッキング許可が必要かを説明する。
  static Future<void> _showAttExplanationDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Text('📢', style: TextStyle(fontSize: 28)),
            SizedBox(width: 8),
            Expanded(child: Text('広告について')),
          ],
        ),
        content: const Text(
          'このアプリは無料でお楽しみいただくために'
          '広告を表示しています。\n\n'
          '次の画面で「許可」を選ぶと、'
          'あなたに合った広告が表示されます。\n'
          '「許可しない」を選んでも、'
          'アプリは問題なくご利用いただけます。',
          style: TextStyle(fontSize: 14, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
