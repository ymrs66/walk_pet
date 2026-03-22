/// 日次報酬の受取状態
class DailyRewardState {
  final String date; // yyyy-MM-dd
  final List<String> claimedRewardIds;

  const DailyRewardState({
    required this.date,
    this.claimedRewardIds = const [],
  });

  /// 指定IDの報酬が受取済みかどうか
  bool hasClaimed(String rewardId) => claimedRewardIds.contains(rewardId);

  /// 報酬を受取済みにして新しいStateを返す
  DailyRewardState claim(String rewardId) => DailyRewardState(
        date: date,
        claimedRewardIds: [...claimedRewardIds, rewardId],
      );

  Map<String, dynamic> toJson() => {
        'date': date,
        'claimedRewardIds': claimedRewardIds,
      };

  factory DailyRewardState.fromJson(Map<String, dynamic> json) =>
      DailyRewardState(
        date: json['date'] as String,
        claimedRewardIds: List<String>.from(json['claimedRewardIds'] as List),
      );

  /// 今日の初期状態を生成
  factory DailyRewardState.today() => DailyRewardState(
        date: _todayString(),
      );

  static String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// 今日のデータかどうか
  bool get isToday => date == _todayString();
}
