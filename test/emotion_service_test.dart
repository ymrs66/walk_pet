import 'package:flutter_test/flutter_test.dart';
import 'package:walk_pet/domain/services/emotion_service.dart';
import 'package:walk_pet/data/models/pet_emotion.dart';

void main() {
  group('EmotionService.resolve', () {
    test('lastFedAt が null → hungry', () {
      expect(EmotionService.resolve(null), PetEmotion.hungry);
    });

    test('餌やり直後（30分前） → happy', () {
      final lastFed = DateTime.now().subtract(const Duration(minutes: 30));
      expect(EmotionService.resolve(lastFed), PetEmotion.happy);
    });

    test('1時間以内（59分前） → happy', () {
      final lastFed = DateTime.now().subtract(const Duration(minutes: 59));
      expect(EmotionService.resolve(lastFed), PetEmotion.happy);
    });

    test('1時間1分前 → normal', () {
      final lastFed = DateTime.now().subtract(const Duration(hours: 1, minutes: 1));
      expect(EmotionService.resolve(lastFed), PetEmotion.normal);
    });

    test('3時間前 → normal', () {
      final lastFed = DateTime.now().subtract(const Duration(hours: 3));
      expect(EmotionService.resolve(lastFed), PetEmotion.normal);
    });

    test('ちょうど6時間前 → normal（境界値）', () {
      final lastFed = DateTime.now().subtract(const Duration(hours: 6));
      expect(EmotionService.resolve(lastFed), PetEmotion.normal);
    });

    test('6時間1分前 → hungry', () {
      final lastFed = DateTime.now().subtract(const Duration(hours: 6, minutes: 1));
      expect(EmotionService.resolve(lastFed), PetEmotion.hungry);
    });

    test('24時間前 → hungry', () {
      final lastFed = DateTime.now().subtract(const Duration(hours: 24));
      expect(EmotionService.resolve(lastFed), PetEmotion.hungry);
    });
  });
}
