import 'package:flutter/material.dart';
import '../../core/pet_stage_config.dart';
import '../../data/models/pet.dart';
import 'home_screen.dart';

/// タイトル画面
class TitleScreen extends StatelessWidget {
  const TitleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final config = PetStageConfig.forStage(PetStage.stage1);

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE8F5E9),
              Color(0xFFFAFFF5),
              Color(0xFFFFF8E1),
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // 上部余白
                          const SizedBox(height: 80),

                          // ペット絵文字
                          Text(config.emoji,
                              style: const TextStyle(fontSize: 80)),
                          const SizedBox(height: 16),

                          // タイトル
                          Text(
                            'あるくペット',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade800,
                              letterSpacing: 4,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'おさんぽで育てよう',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.green.shade600,
                              fontStyle: FontStyle.italic,
                            ),
                          ),

                          // 中間余白
                          const SizedBox(height: 80),

                          // STARTボタン
                          SizedBox(
                            width: 200,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                      builder: (_) => const HomeScreen()),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade600,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(26),
                                ),
                                elevation: 4,
                              ),
                              child: const Text(
                                'START',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 6,
                                ),
                              ),
                            ),
                          ),

                          // 下部余白
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
