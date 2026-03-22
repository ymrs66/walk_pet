/// 健康データアクセス権限の状態
enum HealthPermissionStatus {
  /// 未要求 (初期状態)
  unknown,

  /// 許可済み
  granted,

  /// 拒否された
  denied,

  /// 利用不可 (未対応端末 / Health Connect未導入等)
  unavailable,

  /// エラー (予期しない問題)
  error,
}
