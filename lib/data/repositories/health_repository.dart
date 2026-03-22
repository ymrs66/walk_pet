import '../models/step_state.dart';
import '../models/health_permission_status.dart';
import '../datasources/health_datasource.dart';

/// 歩数データ取得の抽象クラス
abstract class HealthRepository {
  /// 今日の歩数を取得
  Future<StepState> getTodaySteps();

  /// 健康データへのアクセス許可をリクエスト
  Future<HealthPermissionStatus> requestPermission();

  /// 現在の権限状態を確認 (権限要求なし)
  Future<HealthPermissionStatus> checkPermissionStatus();

  /// 設定画面を開く
  Future<void> openSettings();
}

// =============================================================
// 実機用: HealthKit / Health Connect から歩数を取得
// =============================================================

/// 実機の歩数を取得するリポジトリ
class RealHealthRepository implements HealthRepository {
  final HealthDatasource _datasource;

  RealHealthRepository(this._datasource);

  @override
  Future<StepState> getTodaySteps() async {
    final steps = await _datasource.getTodayTotalSteps();
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return StepState(date: dateStr, steps: steps ?? 0);
  }

  @override
  Future<HealthPermissionStatus> requestPermission() async {
    return _datasource.requestStepPermission();
  }

  @override
  Future<HealthPermissionStatus> checkPermissionStatus() async {
    return _datasource.checkStepPermission();
  }

  @override
  Future<void> openSettings() async {
    await _datasource.openSettings();
  }
}

// =============================================================
// テスト用: ダミー歩数を返す実装
// =============================================================

/// Step1互換: ダミー歩数を返す実装
class DummyHealthRepository implements HealthRepository {
  final int dummySteps;

  DummyHealthRepository({required this.dummySteps});

  @override
  Future<StepState> getTodaySteps() async {
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return StepState(date: dateStr, steps: dummySteps);
  }

  @override
  Future<HealthPermissionStatus> requestPermission() async {
    return HealthPermissionStatus.granted;
  }

  @override
  Future<HealthPermissionStatus> checkPermissionStatus() async {
    return HealthPermissionStatus.granted;
  }

  @override
  Future<void> openSettings() async {
    // ダミー: 何もしない
  }
}
