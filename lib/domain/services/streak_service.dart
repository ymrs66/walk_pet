import '../../data/models/streak_state.dart';

/// 連続達成(streak) のドメインロジック
///
/// 1日1000歩以上を「おさんぽ成功日」とする。
/// 純粋関数ベースでテストしやすい設計。
class StreakService {
  /// おさんぽ成功とみなす最低歩数
  static const int successThreshold = 1000;

  /// streak を更新する
  ///
  /// [todaySteps] が閾値以上で、かつ今日まだ記録していなければ:
  /// - lastSuccessDate が昨日 → streak +1（連続）
  /// - lastSuccessDate が昨日以外 → streak = 1（リセット）
  /// 閾値未満 or 今日すでに記録済み → 変更なし
  static StreakState updateStreak(
    StreakState current,
    int todaySteps,
    String todayDate,
  ) {
    // 歩数が閾値未満 → 変更なし
    if (todaySteps < successThreshold) return current;

    // 今日すでに記録済み → 変更なし
    if (current.lastSuccessDate == todayDate) return current;

    // 昨日が成功日 → 連続
    if (StreakState.isYesterday(current.lastSuccessDate)) {
      return current.copyWith(
        currentStreak: current.currentStreak + 1,
        lastSuccessDate: todayDate,
      );
    }

    // それ以外 → リセットして1から
    return current.copyWith(
      currentStreak: 1,
      lastSuccessDate: todayDate,
      bonusClaimed3: false,
      bonusClaimed7: false,
    );
  }

  /// ボーナス判定結果
  static StreakBonusResult checkBonus(StreakState state) {
    final List<StreakBonus> bonuses = [];

    if (state.currentStreak >= 3 && !state.bonusClaimed3) {
      bonuses.add(StreakBonus.day3);
    }
    if (state.currentStreak >= 7 && !state.bonusClaimed7) {
      bonuses.add(StreakBonus.day7);
    }

    return StreakBonusResult(bonuses: bonuses);
  }

  /// ボーナスを受取済みにする
  static StreakState claimBonus(StreakState state, StreakBonus bonus) {
    switch (bonus) {
      case StreakBonus.day3:
        return state.copyWith(bonusClaimed3: true);
      case StreakBonus.day7:
        return state.copyWith(bonusClaimed7: true);
    }
  }
}

enum StreakBonus {
  day3, // 3日連続ボーナス
  day7, // 7日連続ボーナス
}

class StreakBonusResult {
  final List<StreakBonus> bonuses;

  const StreakBonusResult({this.bonuses = const []});

  bool get hasBonuses => bonuses.isNotEmpty;
}
