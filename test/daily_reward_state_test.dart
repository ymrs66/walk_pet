import 'package:flutter_test/flutter_test.dart';
import 'package:walk_pet/data/models/daily_reward_state.dart';

void main() {
  group('DailyRewardState', () {
    test('today() はきょうの日付で生成される', () {
      final state = DailyRewardState.today();
      final now = DateTime.now();
      final expected =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      expect(state.date, expected);
      expect(state.claimedRewardIds, isEmpty);
      expect(state.isToday, isTrue);
    });

    test('昨日の日付は isToday = false', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final dateStr =
          '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
      final state = DailyRewardState(date: dateStr, claimedRewardIds: ['kinomi']);
      expect(state.isToday, isFalse);
    });

    test('claim() で受取IDが追加される', () {
      final state = DailyRewardState.today();
      expect(state.hasClaimed('kinomi'), isFalse);

      final claimed = state.claim('kinomi');
      expect(claimed.hasClaimed('kinomi'), isTrue);
      expect(claimed.claimedRewardIds, ['kinomi']);
    });

    test('claim() は元の state を変更しない（イミュータブル）', () {
      final state = DailyRewardState.today();
      state.claim('kinomi');
      expect(state.hasClaimed('kinomi'), isFalse);
    });

    test('toJson / fromJson で往復できる', () {
      final state = DailyRewardState.today().claim('kinomi').claim('ninjin');
      final json = state.toJson();
      final restored = DailyRewardState.fromJson(json);
      expect(restored.date, state.date);
      expect(restored.claimedRewardIds, state.claimedRewardIds);
    });
  });
}
