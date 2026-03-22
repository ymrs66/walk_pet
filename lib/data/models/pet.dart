/// ペットの成長段階
enum PetStage {
  stage1, // EXP 0-4
  stage2, // EXP 5-11
  stage3, // EXP 12+
}

/// ペットモデル
class Pet {
  final String id;
  final String name;
  final int exp;
  final PetStage stage;

  const Pet({
    required this.id,
    required this.name,
    this.exp = 0,
    this.stage = PetStage.stage1,
  });

  /// EXPからStageを自動判定して新しいPetを生成
  Pet copyWith({String? id, String? name, int? exp}) {
    final newExp = exp ?? this.exp;
    return Pet(
      id: id ?? this.id,
      name: name ?? this.name,
      exp: newExp,
      stage: stageFromExp(newExp),
    );
  }

  /// EXP値からStageを判定
  static PetStage stageFromExp(int exp) {
    if (exp >= 12) return PetStage.stage3;
    if (exp >= 5) return PetStage.stage2;
    return PetStage.stage1;
  }

  /// Stage表示用の絵文字
  String get stageEmoji {
    switch (stage) {
      case PetStage.stage1:
        return '🥚';
      case PetStage.stage2:
        return '🐣';
      case PetStage.stage3:
        return '🐓';
    }
  }

  /// Stage表示用のラベル
  String get stageLabel {
    switch (stage) {
      case PetStage.stage1:
        return 'たまご';
      case PetStage.stage2:
        return 'ひよこ';
      case PetStage.stage3:
        return 'げんきどり';
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'exp': exp,
        'stage': stage.index,
      };

  factory Pet.fromJson(Map<String, dynamic> json) => Pet(
        id: json['id'] as String,
        name: json['name'] as String,
        exp: json['exp'] as int,
        stage: PetStage.values[json['stage'] as int],
      );

  /// デフォルトのペット
  static const Pet defaultPet = Pet(
    id: 'pet_001',
    name: 'ぴよすけ',
  );
}
