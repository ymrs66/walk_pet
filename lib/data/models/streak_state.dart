/// 連続達成日数（streak）の状態モデル
class StreakState {
  final int currentStreak;
  final String lastSuccessDate; // yyyy-MM-dd or ''
  final bool bonusClaimed3;
  final bool bonusClaimed7;

  const StreakState({
    this.currentStreak = 0,
    this.lastSuccessDate = '',
    this.bonusClaimed3 = false,
    this.bonusClaimed7 = false,
  });

  StreakState copyWith({
    int? currentStreak,
    String? lastSuccessDate,
    bool? bonusClaimed3,
    bool? bonusClaimed7,
  }) =>
      StreakState(
        currentStreak: currentStreak ?? this.currentStreak,
        lastSuccessDate: lastSuccessDate ?? this.lastSuccessDate,
        bonusClaimed3: bonusClaimed3 ?? this.bonusClaimed3,
        bonusClaimed7: bonusClaimed7 ?? this.bonusClaimed7,
      );

  Map<String, dynamic> toJson() => {
        'currentStreak': currentStreak,
        'lastSuccessDate': lastSuccessDate,
        'bonusClaimed3': bonusClaimed3,
        'bonusClaimed7': bonusClaimed7,
      };

  factory StreakState.fromJson(Map<String, dynamic> json) => StreakState(
        currentStreak: json['currentStreak'] as int? ?? 0,
        lastSuccessDate: json['lastSuccessDate'] as String? ?? '',
        bonusClaimed3: json['bonusClaimed3'] as bool? ?? false,
        bonusClaimed7: json['bonusClaimed7'] as bool? ?? false,
      );

  // --- 日付ヘルパー ---

  /// 指定日付が「今日」かどうか
  static bool isToday(String dateStr) => dateStr == _todayString();

  /// 指定日付が「昨日」かどうか
  static bool isYesterday(String dateStr) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return dateStr == _dateString(yesterday);
  }

  /// 今日のデータで成功済みかどうか
  bool get isSuccessToday => isToday(lastSuccessDate);

  static String _todayString() => _dateString(DateTime.now());

  static String _dateString(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  /// テスト用: 任意の DateTime から日付文字列を生成
  static String dateStringFrom(DateTime dt) => _dateString(dt);
}
