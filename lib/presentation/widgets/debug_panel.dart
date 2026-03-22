import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/debug_config.dart';
import '../../data/models/pet_emotion.dart';
import '../providers/providers.dart';

/// デバッグ専用パネル
///
/// DebugConfig.debugMode == true のときのみ表示。
class DebugPanel extends ConsumerWidget {
  const DebugPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!DebugConfig.debugMode) return const SizedBox.shrink();

    final gameActions = ref.read(gameActionsProvider);

    return Card(
      color: Colors.amber.shade50,
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bug_report, size: 16, color: Colors.orange),
                const SizedBox(width: 6),
                Text(
                  'デバッグ操作',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // 報酬リセット
            _DebugButton(
              label: '🔄 報酬リセット',
              onPressed: () async {
                await gameActions.debugResetRewards();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('報酬状態をリセットしました'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 6),

            // EXP追加
            Row(
              children: [
                _DebugButton(
                  label: 'EXP +1',
                  onPressed: () => _addExp(context, gameActions, 1),
                ),
                const SizedBox(width: 6),
                _DebugButton(
                  label: 'EXP +5',
                  onPressed: () => _addExp(context, gameActions, 5),
                ),
                const SizedBox(width: 6),
                _DebugButton(
                  label: 'EXP +20',
                  onPressed: () => _addExp(context, gameActions, 20),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // 全食材追加
            _DebugButton(
              label: '🍽️ 全食材 +1',
              onPressed: () async {
                await gameActions.debugAddAllFoods();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('全食材を追加しました'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 6),

            // 感情切替
            Row(
              children: [
                const Text('😊 感情: ', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 4),
                _DebugButton(
                  label: 'normal',
                  onPressed: () {
                    gameActions.debugSetEmotion(PetEmotion.normal);
                    _snack(context, 'emotion → normal');
                  },
                ),
                const SizedBox(width: 4),
                _DebugButton(
                  label: 'happy',
                  onPressed: () {
                    gameActions.debugSetEmotion(PetEmotion.happy);
                    _snack(context, 'emotion → happy');
                  },
                ),
                const SizedBox(width: 4),
                _DebugButton(
                  label: 'hungry',
                  onPressed: () {
                    gameActions.debugSetEmotion(PetEmotion.hungry);
                    _snack(context, 'emotion → hungry');
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _addExp(
      BuildContext context, GameActions actions, int amount) async {
    await actions.debugAddExp(amount);
    if (context.mounted) {
      _snack(context, 'EXP を $amount 加算しました');
    }
  }

  void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 1)),
    );
  }
}

class _DebugButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _DebugButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          side: BorderSide(color: Colors.amber.shade300),
          textStyle: const TextStyle(fontSize: 12),
        ),
        child: Text(label),
      ),
    );
  }
}
