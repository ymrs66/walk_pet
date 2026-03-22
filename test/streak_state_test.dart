import 'package:flutter_test/flutter_test.dart';
import 'package:walk_pet/data/models/streak_state.dart';

void main() {
  group('StreakState', () {
    test('デフォルトは streak=0, lastSuccessDate 空', () {
      const state = StreakState();
      expect(state.currentStreak, 0);
      expect(state.lastSuccessDate, '');
      expect(state.bonusClaimed3, isFalse);
      expect(state.bonusClaimed7, isFalse);
    });

    test('toJson / fromJson で往復できる', () {
      final state = StreakState(
        currentStreak: 5,
        lastSuccessDate: '2026-03-22',
        bonusClaimed3: true,
        bonusClaimed7: false,
      );
      final json = state.toJson();
      final restored = StreakState.fromJson(json);
      expect(restored.currentStreak, 5);
      expect(restored.lastSuccessDate, '2026-03-22');
      expect(restored.bonusClaimed3, isTrue);
      expect(restored.bonusClaimed7, isFalse);
    });

    test('isToday は今日の日付で true を返す', () {
      final todayStr = StreakState.dateStringFrom(DateTime.now());
      expect(StreakState.isToday(todayStr), isTrue);
    });

    test('isToday は昨日の日付で false を返す', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayStr = StreakState.dateStringFrom(yesterday);
      expect(StreakState.isToday(yesterdayStr), isFalse);
    });

    test('isYesterday は昨日の日付で true を返す', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayStr = StreakState.dateStringFrom(yesterday);
      expect(StreakState.isYesterday(yesterdayStr), isTrue);
    });

    test('isYesterday は今日の日付で false を返す', () {
      final todayStr = StreakState.dateStringFrom(DateTime.now());
      expect(StreakState.isYesterday(todayStr), isFalse);
    });

    test('copyWith で一部フィールドだけ変更できる', () {
      const state = StreakState(currentStreak: 3, lastSuccessDate: '2026-03-20');
      final updated = state.copyWith(currentStreak: 4);
      expect(updated.currentStreak, 4);
      expect(updated.lastSuccessDate, '2026-03-20');
    });

    test('fromJson で欠損フィールドのデフォルト値', () {
      final state = StreakState.fromJson({});
      expect(state.currentStreak, 0);
      expect(state.lastSuccessDate, '');
      expect(state.bonusClaimed3, isFalse);
    });
  });
}
