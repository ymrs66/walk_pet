/// 歩数状態モデル
class StepState {
  final String date; // yyyy-MM-dd
  final int steps;

  const StepState({
    required this.date,
    this.steps = 0,
  });

  StepState copyWith({int? steps}) => StepState(
        date: date,
        steps: steps ?? this.steps,
      );

  Map<String, dynamic> toJson() => {
        'date': date,
        'steps': steps,
      };

  factory StepState.fromJson(Map<String, dynamic> json) => StepState(
        date: json['date'] as String,
        steps: json['steps'] as int,
      );
}
