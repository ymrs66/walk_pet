import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/health_permission_status.dart';
import '../providers/providers.dart';

/// オンボーディング画面
/// 健康データ使用の説明 → 権限要求 → Home遷移
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  bool _requesting = false;
  HealthPermissionStatus? _lastResult;

  Future<void> _handleStart() async {
    setState(() {
      _requesting = true;
      _lastResult = null;
    });

    // 権限リクエスト
    final status =
        await ref.read(healthPermissionProvider.notifier).request();

    if (!mounted) return;

    setState(() {
      _requesting = false;
      _lastResult = status;
    });

    // どの結果でも onboarding は完了 → Home へ
    // (granted 以外は Home 画面で案内を表示)
    await ref.read(onboardingCompletedProvider.notifier).complete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🐾', style: TextStyle(fontSize: 80)),
              const SizedBox(height: 24),
              const Text(
                'あるくペット',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'あるいて食材を集めて\nペットを育てよう！',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.directions_walk, size: 40, color: Colors.blue),
                    SizedBox(height: 12),
                    Text(
                      'このアプリは歩数データを使用します',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '歩いた分だけ食材がもらえます。\n食材をペットにあげると\nペットが成長します。\n\n次の画面で健康データへの\nアクセスを許可してください。',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),

              // 権限拒否時の案内
              if (_lastResult == HealthPermissionStatus.denied) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '権限が拒否されました。\n歩数機能なしでも遊べますが、\n設定アプリから後で許可できます。',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // エラー / 利用不可時の案内
              if (_lastResult == HealthPermissionStatus.unavailable ||
                  _lastResult == HealthPermissionStatus.error) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _lastResult == HealthPermissionStatus.unavailable
                              ? '健康データが利用できません。\n端末がHealth Connectに\n対応していない可能性があります。'
                              : '健康データへのアクセス中に\nエラーが発生しました。',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // メインボタン
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _requesting ? null : _handleStart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _requesting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          _lastResult == null ? 'はじめる' : 'このまま進む',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
