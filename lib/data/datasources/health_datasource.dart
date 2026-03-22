import 'dart:io';
import 'package:flutter/foundation.dart';
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
    debugPrint('[HealthDatasource] configure() 開始');
    await _health.configure();
    _configured = true;
    debugPrint('[HealthDatasource] configure() 完了');
  }

  /// Android: Health Connect の利用可否を判定
  /// iOS: 常に true (HealthKit は OS 標準のため利用可能)
  Future<bool> isHealthConnectAvailable() async {
    if (!Platform.isAndroid) return true; // iOS は常に利用可能
    try {
      final status = await _health.getHealthConnectSdkStatus();
      final available = status == HealthConnectSdkStatus.sdkAvailable;
      debugPrint('[HealthDatasource] Health Connect available=$available (status=$status)');
      return available;
    } catch (e) {
      debugPrint('[HealthDatasource] Health Connect check error: $e');
      return false;
    }
  }

  /// 歩数読み取り権限をリクエスト
  Future<HealthPermissionStatus> requestStepPermission() async {
    debugPrint('[HealthDatasource] requestStepPermission() 開始');
    try {
      // Android: Health Connect が利用できるか先にチェック
      if (!await isHealthConnectAvailable()) {
        debugPrint('[HealthDatasource] → unavailable');
        return HealthPermissionStatus.unavailable;
      }

      await configure();

      final types = [HealthDataType.STEPS];
      final permissions = [HealthDataAccess.READ];

      debugPrint('[HealthDatasource] requestAuthorization() 実行中...');
      final granted = await _health.requestAuthorization(
        types,
        permissions: permissions,
      );

      final result = granted
          ? HealthPermissionStatus.granted
          : HealthPermissionStatus.denied;
      debugPrint('[HealthDatasource] requestAuthorization() → $result (granted=$granted)');
      return result;
    } catch (e) {
      debugPrint('[HealthDatasource] requestStepPermission() error: $e');
      return HealthPermissionStatus.error;
    }
  }

  /// 権限状態を確認 (権限要求なし)
  Future<HealthPermissionStatus> checkStepPermission() async {
    debugPrint('[HealthDatasource] checkStepPermission() 開始');
    try {
      // Android: Health Connect が利用できるか先にチェック
      if (!await isHealthConnectAvailable()) {
        debugPrint('[HealthDatasource] → unavailable');
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
        debugPrint('[HealthDatasource] checkStepPermission() → granted');
        return HealthPermissionStatus.granted;
      } else {
        // false or null → 未許可 (denied として扱う)
        debugPrint('[HealthDatasource] checkStepPermission() → denied (hasPermissions=$hasPermissions)');
        return HealthPermissionStatus.denied;
      }
    } catch (e) {
      debugPrint('[HealthDatasource] checkStepPermission() error: $e');
      return HealthPermissionStatus.error;
    }
  }

  /// 今日 0:00 〜 現在の歩数合計を取得
  /// 権限がない場合や取得失敗時は null を返す
  Future<int?> getTodayTotalSteps() async {
    debugPrint('[HealthDatasource] getTodayTotalSteps() 開始');
    try {
      await configure();

      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day);

      final steps = await _health.getTotalStepsInInterval(midnight, now);
      debugPrint('[HealthDatasource] getTodayTotalSteps() → $steps 歩');
      return steps;
    } catch (e) {
      debugPrint('[HealthDatasource] getTodayTotalSteps() error: $e');
      return null;
    }
  }
}
