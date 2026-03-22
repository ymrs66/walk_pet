import 'package:flutter_test/flutter_test.dart';
import 'package:walk_pet/data/models/pet.dart';
import 'package:walk_pet/data/models/pet_emotion.dart';
import 'package:walk_pet/core/pet_dialogue_resolver.dart';

void main() {
  group('PetDialogueResolver', () {
    test('context=normal で既存セリフが返る', () {
      final result = PetDialogueResolver.resolve(
        PetStage.stage1,
        PetEmotion.normal,
      );
      expect(result, isNotEmpty);
      expect(result, isNot('…'));
    });

    test('context=normal (明示) でも既存セリフ', () {
      final result = PetDialogueResolver.resolve(
        PetStage.stage2,
        PetEmotion.happy,
        context: DialogueContext.normal,
      );
      expect(result, isNotEmpty);
      expect(result, isNot('…'));
    });

    test('context=rewardAvailable で報酬系セリフが返る', () {
      final result = PetDialogueResolver.resolve(
        PetStage.stage1,
        PetEmotion.normal,
        context: DialogueContext.rewardAvailable,
      );
      // rewardAvailable 専用セリフのどれかが返る
      expect(
        ['おみやげがあるみたい！', '何かみつけたよ！受け取って！', 'プレゼントがとどいてるよ♪'],
        contains(result),
      );
    });

    test('context=onStreak で連続達成セリフが返る', () {
      final result = PetDialogueResolver.resolve(
        PetStage.stage2,
        PetEmotion.hungry,
        context: DialogueContext.onStreak,
      );
      expect(
        ['れんぞくおさんぽ、すごい！', 'まいにちたのしいね！', 'きょうもいっしょにあるけた♪'],
        contains(result),
      );
    });

    test('全ステージ × 全感情で結果が返る', () {
      for (final stage in PetStage.values) {
        for (final emotion in PetEmotion.values) {
          final result = PetDialogueResolver.resolve(stage, emotion);
          expect(result, isNotEmpty, reason: '$stage × $emotion');
        }
      }
    });
  });
}
