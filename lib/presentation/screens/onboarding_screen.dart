import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';

/// オンボーディング画面
/// アプリ説明 → 権限リクエスト → Home遷移（fail-open）
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  bool _requesting = false;

  Future<void> _handleStart() async {
    setState(() {
      _requesting = true;
    });

    try {
      // 権限リクエスト（15秒でタイムアウト）
      await ref
          .read(healthPermissionProvider.notifier)
          .request()
          .timeout(const Duration(seconds: 15));
    } on TimeoutException {
      debugPrint('[Onboarding] request() timed out after 15s');
    } catch (e) {
      debugPrint('[Onboarding] request() failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _requesting = false;
        });
      }
    }

    if (!mounted) return;

    // どの結果でも onboarding は完了 → Home へ
    // (granted 以外は Home 画面で案内を表示)
    await ref.read(onboardingCompletedProvider.notifier).complete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(32.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 64, // padding 分を差し引く
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🐾', style: TextStyle(fontSize: 80)),
                        const SizedBox(height: 24),
                        const Text(
                          'あるくペット',
                          style: TextStyle(
                              fontSize: 28, fontWeight: FontWeight.bold),
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
                              Icon(Icons.directions_walk,
                                  size: 40, color: Colors.blue),
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
                                '歩いた分だけ食材がもらえます。\n食材をペットにあげると\nペットが成長します。\n\nこのあと健康データへの\nアクセス許可をお願いする\n場合があります。',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // メインボタン — 常に「はじめる」
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
                                : const Text(
                                    'はじめる',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),

                        // 下部余白（ボタンが画面端に密着しない）
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
