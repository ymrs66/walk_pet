/// ─── アプリ動作モード切り替え ───
///
/// 切替方法: [currentMode] を変更するだけで歩数ソース・デバッグUI・広告が連動します。
///
///   AppMode.dev        → ダミー歩数 + デバッグUI + 広告OFF
///   AppMode.testFlight → 実歩数    + デバッグUI + 広告OFF
///   AppMode.release    → 実歩数    + UI非表示  + 広告ON
enum AppMode { dev, testFlight, release }

/// デバッグ設定
///
/// 各フラグは [currentMode] から自動導出されるため、
/// 個別に書き換える必要はありません。
class DebugConfig {
  // ↓ ここを変更するだけ ↓
  static const AppMode currentMode = AppMode.testFlight;

  // --- derived flags ---

  /// デバッグモード (dev / testFlight で true)
  static bool get debugMode => currentMode != AppMode.release;

  /// ダミー歩数を使用する (dev のみ)
  static bool get useDummyHealth => currentMode == AppMode.dev;

  /// ダミー歩数の値
  static const int dummySteps = 9000;

  /// デバッグ情報をUI上に表示する (dev のみ)
  static bool get showDebugBanner => currentMode == AppMode.dev;
}
