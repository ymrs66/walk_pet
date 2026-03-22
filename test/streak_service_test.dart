import 'package:flutter_test/flutter_test.dart';
import 'package:walk_pet/data/models/streak_state.dart';
import 'package:walk_pet/domain/services/streak_service.dart';

void main() {
  group('StreakService.updateStreak', () {
    late String today;
    late String yesterday;

    setUp(() {
      today = StreakState.dateStringFrom(DateTime.now());
      yesterday = StreakState.dateStringFrom(
          DateTime.now().subtract(const Duration(days: 1)));
    });

    test('1000歩以上で streak が 1 になる（初回）', () {
      const state = StreakState();
      final updated = StreakService.updateStreak(state, 1500, today);
      expect(updated.currentStreak, 1);
      expect(updated.lastSuccessDate, today);
    });

    test('1000歩未満は streak 変わらず', () {
      const state = StreakState();
      final updated = StreakService.updateStreak(state, 500, today);
      expect(updated.currentStreak, 0);
      expect(updated.lastSuccessDate, '');
    });

    test('昨日成功 → 今日1000歩以上で連続 +1', () {
      final state = StreakState(
        currentStreak: 3,
        lastSuccessDate: yesterday,
      );
      final updated = StreakService.updateStreak(state, 2000, today);
      expect(updated.currentStreak, 4);
      expect(updated.lastSuccessDate, today);
    });

    test('2日以上空いたらリセット（streak=1）', () {
      final twoDaysAgo = StreakState.dateStringFrom(
          DateTime.now().subtract(const Duration(days: 2)));
      final state = StreakState(currentStreak: 5, lastSuccessDate: twoDaysAgo);
      final updated = StreakService.updateStreak(state, 1000, today);
      expect(updated.currentStreak, 1);
      expect(updated.bonusClaimed3, isFalse);
      expect(updated.bonusClaimed7, isFalse);
    });

    test('今日すでに記録済みなら変更なし', () {
      final state = StreakState(currentStreak: 3, lastSuccessDate: today);
      final updated = StreakService.updateStreak(state, 5000, today);
      expect(updated.currentStreak, 3);
      expect(identical(updated, state), isTrue);
    });

    test('ちょうど1000歩で成功判定される', () {
      const state = StreakState();
      final updated = StreakService.updateStreak(state, 1000, today);
      expect(updated.currentStreak, 1);
    });
  });

  group('StreakService.checkBonus', () {
    test('3日連続でボーナスあり', () {
      const state = StreakState(currentStreak: 3);
      final result = StreakService.checkBonus(state);
      expect(result.hasBonuses, isTrue);
      expect(result.bonuses, contains(StreakBonus.day3));
    });

    test('7日連続で両方のボーナスあり', () {
      const state = StreakState(currentStreak: 7);
      final result = StreakService.checkBonus(state);
      expect(result.bonuses, contains(StreakBonus.day3));
      expect(result.bonuses, contains(StreakBonus.day7));
    });

    test('受取済みならボーナスなし', () {
      const state = StreakState(
        currentStreak: 7,
        bonusClaimed3: true,
        bonusClaimed7: true,
      );
      final result = StreakService.checkBonus(state);
      expect(result.hasBonuses, isFalse);
    });

    test('2日連続ではボーナスなし', () {
      const state = StreakState(currentStreak: 2);
      final result = StreakService.checkBonus(state);
      expect(result.hasBonuses, isFalse);
    });
  });

  group('StreakService.claimBonus', () {
    test('day3 ボーナスを受取済みにできる', () {
      const state = StreakState(currentStreak: 3);
      final updated = StreakService.claimBonus(state, StreakBonus.day3);
      expect(updated.bonusClaimed3, isTrue);
      expect(updated.bonusClaimed7, isFalse);
    });

    test('day7 ボーナスを受取済みにできる', () {
      const state = StreakState(currentStreak: 7);
      final updated = StreakService.claimBonus(state, StreakBonus.day7);
      expect(updated.bonusClaimed7, isTrue);
    });
  });
}
