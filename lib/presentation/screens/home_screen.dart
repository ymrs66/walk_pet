import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/pet.dart';
import '../../data/models/food.dart';
import '../../data/models/step_state.dart' as models;
import '../../data/models/health_permission_status.dart';
import '../../domain/services/reward_service.dart';
import '../../domain/entities/pet_entity.dart';
import '../../core/pet_stage_config.dart';
import '../../core/pet_dialogue_resolver.dart';
import '../../core/config/debug_config.dart';
import '../../data/models/pet_emotion.dart';
import '../../domain/services/ad_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../providers/providers.dart';
import '../widgets/pet_display.dart';
import '../widgets/food_helpers.dart';
import '../widgets/debug_panel.dart';
import 'inventory_screen.dart';

/// ホーム画面
///
/// v0.1 TestFlight 確認観点:
/// - 今日何をすると良いか分かる（歩数 → 報酬 → 餌やり）
/// - 「歩いた → 報酬受取 → 餌やり」の流れが迷わずできる
/// - 余計な未実装感が出ない
/// - 含む機能: オンボーディング / 歩数 / 報酬 / 在庫 / 餌やり / 成長 / 感情
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  PetStage? _previousStage;
  final AdService _adService = AdService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(() {
      ref.read(healthPermissionProvider.notifier).check();
      ref.read(gameActionsProvider).refreshSteps();
      ref.read(emotionProvider.notifier).refresh();
      _showIntroIfNeeded();
    });
    // バナー広告読み込み
    _adService.onBannerLoaded = () {
      if (mounted) setState(() {});
    };
    _adService.loadBanner();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(healthPermissionProvider.notifier).check();
      ref.read(gameActionsProvider).refreshSteps();
      ref.read(emotionProvider.notifier).refresh();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _adService.dispose();
    super.dispose();
  }

  /// 初回導入ダイアログ (1回のみ)
  void _showIntroIfNeeded() {
    final introShown = ref.read(introShownProvider);
    if (introShown) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Text('🥚', style: TextStyle(fontSize: 28)),
              SizedBox(width: 8),
              Text('はじめまして！'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'この子は「おさんぽエネルギー」で\n育つふしぎな生き物です。',
                style: TextStyle(fontSize: 15, height: 1.6),
              ),
              SizedBox(height: 12),
              Text(
                '🚶 歩くと食材がみつかります\n🍽️ 食材をあげると成長します\n🐣 たくさん歩いて育てよう！',
                style: TextStyle(fontSize: 14, height: 1.6),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                ref.read(introShownProvider.notifier).markShown();
                Navigator.of(context).pop();
              },
              child: const Text('わかった！',
                  style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final pet = ref.watch(petProvider);
    final stepAsync = ref.watch(stepProvider);
    final rewardStatuses = ref.watch(rewardStatusListProvider);
    final permissionStatus = ref.watch(healthPermissionProvider);
    final gameActions = ref.read(gameActionsProvider);
    final emotion = ref.watch(emotionProvider);



    // 成長段階が変わったら演出
    if (_previousStage != null && _previousStage != pet.stage) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showStageUpDialog(context, pet);
      });
    }
    _previousStage = pet.stage;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          DebugConfig.debugMode ? 'あるくペット (v0.1)' : 'あるくペット',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.inventory_2),
            tooltip: 'もちもの',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const InventoryScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // デバッグバナー
            if (DebugConfig.showDebugBanner)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Text(
                  '🛠 DEBUG  ・  steps=${DebugConfig.dummySteps}  ・  emotion=${emotion.name}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.amber.shade900,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            _PetSection(pet: pet, emotion: emotion),
            const SizedBox(height: 20),
            _buildStepSection(permissionStatus, stepAsync, ref),
            const SizedBox(height: 20),
            _RewardSection(
              rewardStatuses: rewardStatuses,
              currentSteps: stepAsync.valueOrNull?.steps ?? 0,
              onClaim: (foodId) async {
                final success = await gameActions.claimReward(foodId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? '報酬を受け取りました！' : '受け取れません'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 20),

            // デバッグパネル (debugMode時のみ)
            const DebugPanel(),
            const SizedBox(height: 12),

            // バナー広告
            if (_adService.isBannerLoaded && _adService.bannerAd != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: SizedBox(
                  width: _adService.bannerAd!.size.width.toDouble(),
                  height: _adService.bannerAd!.size.height.toDouble(),
                  child: AdWidget(ad: _adService.bannerAd!),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepSection(
    HealthPermissionStatus permissionStatus,
    AsyncValue<models.StepState> stepAsync,
    WidgetRef ref,
  ) {
    if (permissionStatus == HealthPermissionStatus.unknown) {
      return const Card(
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(Icons.directions_walk, size: 36, color: Colors.grey),
              SizedBox(width: 16),
              Text('権限を確認中...'),
            ],
          ),
        ),
      );
    }

    if (permissionStatus == HealthPermissionStatus.granted) {
      return _StepSection(stepAsync: stepAsync);
    }

    return _PermissionDeniedSection(
      status: permissionStatus,
      onRetry: () async {
        final result =
            await ref.read(healthPermissionProvider.notifier).request();
        if (result == HealthPermissionStatus.granted) {
          ref.read(gameActionsProvider).refreshSteps();
        }
      },
    );
  }

  void _showStageUpDialog(BuildContext context, Pet pet) {
    final config = PetStageConfig.forStage(pet.stage);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('🎉 成長しました！'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PetDisplay(pet: pet, size: 64),
            const SizedBox(height: 12),
            Text(
              '${pet.name}が ${config.label} になりました！',
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              config.description,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('やったー！'),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// Pet Section — 進捗バー + ひとこと
// =============================================================

class _PetSection extends StatelessWidget {
  final Pet pet;
  final PetEmotion emotion;

  const _PetSection({required this.pet, required this.emotion});

  @override
  Widget build(BuildContext context) {
    final expToNext = PetEntity.expToNextStage(pet);
    final progress = PetEntity.stageProgress(pet);
    final config = PetStageConfig.forStage(pet.stage);
    final isMaxStage = pet.stage == PetStage.stage3;

    final hitokoto = PetDialogueResolver.resolve(pet.stage, emotion);

    return Card(
      elevation: 2,
      color: _cardColorForStage(pet.stage),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            PetDisplay(pet: pet, emotion: emotion, size: 80),
            const SizedBox(height: 8),
            Text(
              pet.name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              config.label,
              style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
            ),

            // ひとこと
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(180),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '「$hitokoto」',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.brown.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 進捗バー
            if (!isMaxStage) ...[
              Row(
                children: [
                  Text(config.label, style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        minHeight: 10,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    PetEntity.nextStageLabel(pet) ?? '',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'EXP ${pet.exp}  ・ 次のステージまで あと $expToNext',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ] else ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('⭐', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text(
                      '最大成長！  EXP ${pet.exp}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.amber.shade800,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Stage別のカード背景色
  Color _cardColorForStage(PetStage stage) {
    switch (stage) {
      case PetStage.stage1:
        return const Color(0xFFFFF8E8); // あたたかい卵色
      case PetStage.stage2:
        return const Color(0xFFFFFDE7); // ひよこイエロー
      case PetStage.stage3:
        return const Color(0xFFF1F8E9); // おとなのグリーン
    }
  }
}

// =============================================================
// Step Section
// =============================================================

class _StepSection extends StatelessWidget {
  final AsyncValue<models.StepState> stepAsync;

  const _StepSection({required this.stepAsync});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: const Color(0xFFE8F5E9),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Color(0xFFC8E6C9),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.directions_walk,
                  size: 28, color: Colors.green.shade700),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'きょうのおさんぽ',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.green.shade700,
                    ),
                  ),
                  stepAsync.when(
                    data: (stepState) => Text(
                      '${stepState.steps} 歩',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade900,
                      ),
                    ),
                    loading: () => const Text('読み込み中...'),
                    error: (e, _) => const Text(
                      '歩数を取得できませんでした',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================
// Permission Denied Section
// =============================================================

class _PermissionDeniedSection extends StatelessWidget {
  final HealthPermissionStatus status;
  final VoidCallback onRetry;

  const _PermissionDeniedSection({
    required this.status,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final (icon, color, message, hint) = switch (status) {
      HealthPermissionStatus.denied => (
          Icons.lock_outline,
          Colors.orange,
          '歩数データの利用が許可されていません',
          '設定アプリから後で許可できます。\n歩数なしでもアプリは遊べます。',
        ),
      HealthPermissionStatus.unavailable => (
          Icons.phone_android,
          Colors.orange,
          '健康データを利用できません',
          'Health Connect がインストールされて\nいない可能性があります。',
        ),
      _ => (
          Icons.cloud_off,
          Colors.grey,
          '歩数データの取得でエラーが起きました',
          'しばらくしてからもう一度お試しください。',
        ),
    };

    return Card(
      elevation: 2,
      color: color.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(icon, size: 36, color: color),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              hint,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('もう一度試す'),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================
// Reward Section
// =============================================================

class _RewardSection extends StatelessWidget {
  final List<RewardStatus> rewardStatuses;
  final int currentSteps;
  final Future<void> Function(String foodId) onClaim;

  const _RewardSection({
    required this.rewardStatuses,
    required this.currentSteps,
    required this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🎁 きょうの報酬',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...rewardStatuses.map((rs) => _RewardTile(
                  rewardStatus: rs,
                  currentSteps: currentSteps,
                  onClaim: () => onClaim(rs.food.id),
                )),
            if (rewardStatuses.isEmpty)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('歩数を読み込み中...'),
              ),
          ],
        ),
      ),
    );
  }
}

class _RewardTile extends StatelessWidget {
  final RewardStatus rewardStatus;
  final int currentSteps;
  final VoidCallback onClaim;

  const _RewardTile({
    required this.rewardStatus,
    required this.currentSteps,
    required this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    final food = rewardStatus.food;
    final status = rewardStatus.status;
    final emoji = foodEmoji(food.id);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  food.name,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 1),
                // 食材の世界観サブ文言
                Text(
                  food.description,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.brown.shade300,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _subtitleText(food, status),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          _buildTrailing(status),
        ],
      ),
    );
  }

  String _subtitleText(Food food, RewardStatusType status) {
    switch (status) {
      case RewardStatusType.claimed:
        return '${food.requiredSteps}歩  ・  EXP +${food.expValue}';
      case RewardStatusType.available:
        return '${food.requiredSteps}歩 達成！  ・  EXP +${food.expValue}';
      case RewardStatusType.locked:
        final remaining = food.requiredSteps - currentSteps;
        return 'あと $remaining歩  ・  EXP +${food.expValue}';
    }
  }

  Widget _buildTrailing(RewardStatusType status) {
    switch (status) {
      case RewardStatusType.claimed:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text('✓ 受取済み',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
        );
      case RewardStatusType.available:
        return ElevatedButton(
          onPressed: onClaim,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          ),
          child: const Text('受け取る', style: TextStyle(fontSize: 13)),
        );
      case RewardStatusType.locked:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text('🔒 未到達',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        );
    }
  }
}
