import 'dart:io';
import 'package:health/health.dart';
import '../models/health_permission_status.dart';

/// health プラグインのラッパー
///
/// プラグインの直接利用を datasource 層に閉じ込め、
/// repository / provider からはこのクラス経由でアクセスする。
class HealthDatasource {
  final Health _health = Health();
  bool _configured = false;

  /// health プラグインの初期化
  Future<void> configure() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }

  /// Android: Health Connect の利用可否を判定
  /// iOS: 常に null (HealthKit は OS 標準のため利用可能)
  Future<bool> isHealthConnectAvailable() async {
    if (!Platform.isAndroid) return true; // iOS は常に利用可能
    try {
      final status = await _health.getHealthConnectSdkStatus();
      return status == HealthConnectSdkStatus.sdkAvailable;
    } catch (_) {
      return false;
    }
  }

  /// 歩数読み取り権限をリクエスト
  Future<HealthPermissionStatus> requestStepPermission() async {
    try {
      // Android: Health Connect が利用できるか先にチェック
      if (!await isHealthConnectAvailable()) {
        return HealthPermissionStatus.unavailable;
      }

      await configure();

      final types = [HealthDataType.STEPS];
      final permissions = [HealthDataAccess.READ];

      final granted = await _health.requestAuthorization(
        types,
        permissions: permissions,
      );

      if (granted) {
        return HealthPermissionStatus.granted;
      } else {
        return HealthPermissionStatus.denied;
      }
    } catch (_) {
      return HealthPermissionStatus.error;
    }
  }

  /// 権限状態を確認 (権限要求なし)
  Future<HealthPermissionStatus> checkStepPermission() async {
    try {
      // Android: Health Connect が利用できるか先にチェック
      if (!await isHealthConnectAvailable()) {
        return HealthPermissionStatus.unavailable;
      }

      await configure();

      final types = [HealthDataType.STEPS];
      final permissions = [HealthDataAccess.READ];

      final hasPermissions = await _health.hasPermissions(
        types,
        permissions: permissions,
      );

      if (hasPermissions == true) {
        return HealthPermissionStatus.granted;
      } else {
        // false or null → 未許可 (denied として扱う)
        return HealthPermissionStatus.denied;
      }
    } catch (_) {
      return HealthPermissionStatus.error;
    }
  }

  /// 今日 0:00 〜 現在の歩数合計を取得
  /// 権限がない場合や取得失敗時は null を返す
  Future<int?> getTodayTotalSteps() async {
    try {
      await configure();

      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day);

      final steps = await _health.getTotalStepsInInterval(midnight, now);
      return steps;
    } catch (_) {
      return null;
    }
  }
}
