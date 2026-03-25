/// 歩数状態モデル
class StepState {
  final String date; // yyyy-MM-dd
  final int steps;
  final bool loadFailed; // 歩数取得失敗フラグ

  const StepState({
    required this.date,
    this.steps = 0,
    this.loadFailed = false,
  });

  StepState copyWith({int? steps, bool? loadFailed}) => StepState(
        date: date,
        steps: steps ?? this.steps,
        loadFailed: loadFailed ?? this.loadFailed,
      );

  Map<String, dynamic> toJson() => {
        'date': date,
        'steps': steps,
        'loadFailed': loadFailed,
      };

  factory StepState.fromJson(Map<String, dynamic> json) => StepState(
        date: json['date'] as String,
        steps: json['steps'] as int,
        loadFailed: json['loadFailed'] as bool? ?? false,
      );
}
