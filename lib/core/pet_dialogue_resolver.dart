import '../../data/models/pet.dart';
import '../../data/models/pet_emotion.dart';

/// stage × emotion からひとこと文言を解決する
///
/// 将来: JSON化やランダム化が容易な構造
class PetDialogueResolver {
  /// stage × emotion → ひとこと文言リスト
  static const Map<PetStage, Map<PetEmotion, List<String>>> _dialogues = {
    PetStage.stage1: {
      PetEmotion.normal: [
        'ぽかぽかしてる…',
        'なにかが動いた…？',
        'あったかいね…',
      ],
      PetEmotion.happy: [
        'おいしかった！',
        'しあわせ…',
        'もっとほしいな♪',
      ],
      PetEmotion.hungry: [
        'おなかすいた…',
        'なにかたべたい…',
        'ぐぅ…',
      ],
    },
    PetStage.stage2: {
      PetEmotion.normal: [
        'おさんぽしたいな！',
        'きょうもげんき！',
        'ぴよぴよ♪',
      ],
      PetEmotion.happy: [
        'おいしかった！！',
        'ごきげん～♪',
        'もぐもぐ大満足！',
      ],
      PetEmotion.hungry: [
        'おなかぺこぺこ…',
        'ごはんまだかなぁ…',
        'ちからがでない…',
      ],
    },
    PetStage.stage3: {
      PetEmotion.normal: [
        'おさんぽってたのしいね！',
        'いっしょに歩こう！',
        'きょうもいい天気！',
      ],
      PetEmotion.happy: [
        'さいこう！！',
        'ありがとう！大好き！',
        'おなかいっぱい♪',
      ],
      PetEmotion.hungry: [
        'おなかすいたよ～',
        'なにかたべたいなぁ',
        'ちょっとつかれた…',
      ],
    },
  };

  /// stage × emotion からひとこと文言を取得
  /// 時刻ベースでセミランダム選択 (将来 Random に変更可能)
  static String resolve(PetStage stage, PetEmotion emotion) {
    final emotionMap = _dialogues[stage];
    if (emotionMap == null) return '…';

    final list = emotionMap[emotion] ?? emotionMap[PetEmotion.normal] ?? ['…'];
    return list[DateTime.now().millisecondsSinceEpoch % list.length];
  }
}
