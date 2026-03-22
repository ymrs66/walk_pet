import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walk_pet/data/datasources/local_datasource.dart';
import 'package:walk_pet/data/repositories/game_repository.dart';
import 'package:walk_pet/data/models/pet.dart';
import 'package:walk_pet/data/models/inventory_item.dart';

void main() {
  late SharedPreferences prefs;
  late LocalDatasource datasource;
  late GameRepository repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    datasource = LocalDatasource(prefs);
    repo = GameRepository(datasource);
  });

  group('GameRepository.claimReward', () {
    test('歩数条件を満たしていれば報酬受取成功', () async {
      // kinomi は 1000歩で受取可能
      final result = await repo.claimReward('kinomi', 1500);
      expect(result.success, isTrue);
      expect(result.rewardState.hasClaimed('kinomi'), isTrue);
      // 在庫に追加されている
      final kinomi = result.inventory.firstWhere((i) => i.foodId == 'kinomi');
      expect(kinomi.count, 1);
    });

    test('歩数不足だと受取失敗', () async {
      final result = await repo.claimReward('kinomi', 500);
      expect(result.success, isFalse);
      expect(result.rewardState.hasClaimed('kinomi'), isFalse);
    });

    test('二重受取は失敗', () async {
      await repo.claimReward('kinomi', 1500);
      final result2 = await repo.claimReward('kinomi', 1500);
      expect(result2.success, isFalse);
      // 在庫は1つのまま
      final kinomi = result2.inventory.firstWhere((i) => i.foodId == 'kinomi');
      expect(kinomi.count, 1);
    });

    test('存在しない食材IDは失敗', () async {
      final result = await repo.claimReward('unknown_food', 9999);
      expect(result.success, isFalse);
    });
  });

  group('GameRepository.feedPet', () {
    test('在庫があれば餌やり成功 — 在庫減少・EXP加算', () async {
      // 先に食材を追加
      await repo.addFood('kinomi');
      final inv = repo.loadInventory();
      expect(inv.first.count, 1);

      // 餌やり実行
      final result = await repo.feedPet('kinomi');
      expect(result.success, isTrue);

      // EXP が増えている (kinomi = EXP +1)
      expect(result.pet.exp, 1);

      // 在庫が減っている（0個なのでリストから消える）
      expect(result.inventory.where((i) => i.foodId == 'kinomi'), isEmpty);
    });

    test('在庫ゼロだと餌やり失敗', () async {
      final result = await repo.feedPet('kinomi');
      expect(result.success, isFalse);
      expect(result.pet.exp, 0);
    });

    test('複数回の餌やりでEXPが累積する', () async {
      await repo.addFood('ninjin'); // EXP +3
      await repo.addFood('ninjin');

      final r1 = await repo.feedPet('ninjin');
      expect(r1.success, isTrue);
      expect(r1.pet.exp, 3);

      final r2 = await repo.feedPet('ninjin');
      expect(r2.success, isTrue);
      expect(r2.pet.exp, 6);
    });

    test('EXP蓄積でStageが上がる', () async {
      // stage2 は EXP >= 5
      for (var i = 0; i < 5; i++) {
        await repo.addFood('kinomi'); // EXP +1 × 5 = 5
      }
      late var result;
      for (var i = 0; i < 5; i++) {
        result = await repo.feedPet('kinomi');
      }
      expect(result.success, isTrue);
      expect(result.pet.exp, 5);
      expect(result.pet.stage, PetStage.stage2);
    });
  });
}
