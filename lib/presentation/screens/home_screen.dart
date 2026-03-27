import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/pet.dart';
import '../../data/models/food.dart';
import '../../data/models/inventory_item.dart';
import '../../data/models/step_state.dart' as models;
import '../../data/models/streak_state.dart';
import '../../data/models/health_permission_status.dart';
import '../../domain/services/reward_service.dart';
import '../../domain/services/streak_service.dart';
import '../../domain/entities/pet_entity.dart';
import '../../core/pet_stage_config.dart';
import '../../core/pet_dialogue_resolver.dart';
import '../../core/config/debug_config.dart';
import '../../data/models/pet_emotion.dart';
import '../../domain/services/ad_service.dart';
import '../../domain/services/ads_bootstrap_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../providers/providers.dart';
import '../widgets/pet_display.dart';
import '../widgets/food_helpers.dart';
import '../widgets/debug_panel.dart';
import 'inventory_screen.dart';
import 'package:url_launcher/url_launcher.dart';

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
    Future.microtask(() async {
      // 権限は check のみ (request は OnboardingScreen で実施済み)
      await ref.read(healthPermissionProvider.notifier).check();
      final status = ref.read(healthPermissionProvider);
      if (status == HealthPermissionStatus.granted) {
        await ref.read(gameActionsProvider).refreshSteps();
        // streak は歩数確定後に評価
        final bonuses =
            await ref.read(gameActionsProvider).checkAndUpdateStreak();
        if (bonuses.isNotEmpty && mounted) {
          _showStreakBonusDialog(context, bonuses);
        }
      }
      ref.read(emotionProvider.notifier).refresh();
      _showIntroIfNeeded();
      // 広告初期化 (権限導線の後に直列実行)
      await _initAdsAndLoadBanner();
    });
  }

  /// 広告SDK初期化 → バナー読み込み
  Future<void> _initAdsAndLoadBanner() async {
    await AdsBootstrapService.ensureInitialized(context);
    if (!mounted) return;
    _adService.onBannerLoaded = () {
      if (mounted) setState(() {});
    };
    _adService.loadBanner();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _onResumed();
    }
  }

  Future<void> _onResumed() async {
    // 権限状態を先に確認（initState と同じ順序）
    await ref.read(healthPermissionProvider.notifier).check();
    if (!mounted) return;

    ref.read(emotionProvider.notifier).refresh();

    // granted のときだけ歩数 → streak 更新
    final status = ref.read(healthPermissionProvider);
    if (status == HealthPermissionStatus.granted) {
      await ref.read(gameActionsProvider).refreshSteps();
      await ref.read(gameActionsProvider).checkAndUpdateStreak();
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
    final streak = ref.watch(streakProvider);
    final totalSteps = ref.watch(totalStepsProvider);
    final dialogueContext = ref.watch(dialogueContextProvider);



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
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: '設定',
            onPressed: () => _showSettingsDialog(context),
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

            _PetSection(
              pet: pet,
              emotion: emotion,
              dialogueContext: dialogueContext,
            ),
            const SizedBox(height: 20),
            _buildStepSection(permissionStatus, stepAsync, ref, streak, totalSteps),
            const SizedBox(height: 20),
            // 次目標 & 受取可能バナー
            _NextGoalBanner(
              rewardStatuses: rewardStatuses,
              currentSteps: stepAsync.valueOrNull?.steps ?? 0,
              stepLoadFailed: stepAsync.valueOrNull?.loadFailed ?? false,
            ),
            const SizedBox(height: 12),
            _RewardSection(
              rewardStatuses: rewardStatuses,
              currentSteps: stepAsync.valueOrNull?.steps ?? 0,
              stepLoadFailed: stepAsync.valueOrNull?.loadFailed ?? false,
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
            const SizedBox(height: 16),

            // もちもの導線
            _InventoryShortcut(
              inventory: ref.watch(inventoryProvider),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const InventoryScreen()),
                );
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
    StreakState streak,
    int totalSteps,
  ) {
    // 許可済み → 歩数表示
    if (permissionStatus == HealthPermissionStatus.granted) {
      return _StepSection(stepAsync: stepAsync, streak: streak, totalSteps: totalSteps);
    }

    // 確認中
    if (permissionStatus == HealthPermissionStatus.unknown) {
      return const Card(
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 16),
              Text('歩数データを確認しています...'),
            ],
          ),
        ),
      );
    }

    // 未許可 / 拒否 / エラー → 許可要求セクション
    return _PermissionRequestSection(
      status: permissionStatus,
      onRequest: () async {
        final result =
            await ref.read(healthPermissionProvider.notifier).request();
        if (result == HealthPermissionStatus.granted) {
          await ref.read(gameActionsProvider).refreshSteps();
          await ref.read(gameActionsProvider).checkAndUpdateStreak();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✓ 歩数データを許可しました！'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      },
      onSkip: () {
        // 何もしない（カードはそのまま残るが操作は妨げない）
      },
    );
  }

  /// streak ボーナス獲得ダイアログ
  void _showStreakBonusDialog(
      BuildContext context, List<StreakBonus> bonuses) {
    final streak = ref.read(streakProvider);
    final emoji = bonuses.any((b) => b == StreakBonus.day7) ? '🎊' : '🎉';
    final title = bonuses.map((b) {
      switch (b) {
        case StreakBonus.day3:
          return '3日連続達成！';
        case StreakBonus.day7:
          return '7日連続達成！';
      }
    }).join(' & ');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 8),
            Expanded(child: Text(title)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '🔥 ${streak.currentStreak}日連続おさんぽ！',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(foodEmoji('kinomi'),
                      style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 8),
                  Text(
                    'きのみ ×${bonuses.length} ゲット！',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.brown.shade700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'まいにち歩いてくれてありがとう！',
              style: TextStyle(
                  fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('やったー！', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
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

  /// 設定ダイアログ
  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.settings, size: 24),
            SizedBox(width: 8),
            Text('設定'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.delete_forever,
                  color: Colors.red.shade400),
              title: const Text('データを初期化'),
              subtitle: Text(
                'ペット・もちもの・報酬・歩数記録をリセット',
                style: TextStyle(
                    fontSize: 12, color: Colors.grey.shade600),
              ),
              onTap: () {
                Navigator.of(context).pop();
                _showResetConfirmation(context);
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(Icons.privacy_tip_outlined,
                  color: Colors.blue.shade400),
              title: const Text('プライバシーポリシー'),
              onTap: () {
                launchUrl(
                  Uri.parse('https://walkpet.jp/privacy.html'),
                  mode: LaunchMode.externalApplication,
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  /// データ初期化確認ダイアログ
  void _showResetConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: Colors.red.shade400, size: 28),
            const SizedBox(width: 8),
            const Text('本当に初期化しますか？'),
          ],
        ),
        content: const Text(
          'ペット・もちもの・報酬・連続記録・'
          '歩数の累計がすべてリセットされます。\n\n'
          'この操作は取り消せません。',
          style: TextStyle(fontSize: 14, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await ref.read(gameActionsProvider).resetAllData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✓ データを初期化しました'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('初期化する',
                style: TextStyle(fontWeight: FontWeight.bold)),
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
  final DialogueContext dialogueContext;

  const _PetSection({
    required this.pet,
    required this.emotion,
    this.dialogueContext = DialogueContext.normal,
  });

  @override
  Widget build(BuildContext context) {
    final expToNext = PetEntity.expToNextStage(pet);
    final progress = PetEntity.stageProgress(pet);
    final config = PetStageConfig.forStage(pet.stage);
    final isMaxStage = pet.stage == PetStage.stage3;

    final hitokoto = PetDialogueResolver.resolve(
      pet.stage,
      emotion,
      context: dialogueContext,
    );

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

class _StepSection extends ConsumerWidget {
  final AsyncValue<models.StepState> stepAsync;
  final StreakState streak;
  final int totalSteps;

  const _StepSection({
    required this.stepAsync,
    required this.streak,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 2,
      color: const Color(0xFFE8F5E9),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
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
                        data: (stepState) {
                          if (stepState.loadFailed) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '歩数を取得できませんでした',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.orange.shade800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'ヘルスケア連携や設定状況を\nご確認ください',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                OutlinedButton.icon(
                                  onPressed: () {
                                    ref.invalidate(stepProvider);
                                  },
                                  icon: const Icon(Icons.refresh, size: 16),
                                  label: const Text('もう一度確認',
                                      style: TextStyle(fontSize: 13)),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                  ),
                                ),
                              ],
                            );
                          }
                          return Text(
                            '${stepState.steps} 歩',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade900,
                            ),
                          );
                        },
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
            // streak バッジ
            if (streak.currentStreak >= 1) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 4),
                    Text(
                      '連続 ${streak.currentStreak}日',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // これまでの合計
            if (totalSteps > 0) ...[
              const SizedBox(height: 8),
              Text(
                'これまでの合計 $totalSteps 歩',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green.shade600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// =============================================================
// Permission Request Section — 歩数データの許可を促す
// =============================================================

class _PermissionRequestSection extends StatelessWidget {
  final HealthPermissionStatus status;
  final VoidCallback onRequest;
  final VoidCallback onSkip;

  const _PermissionRequestSection({
    required this.status,
    required this.onRequest,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    // unavailable (Health Connect 未導入等)
    if (status == HealthPermissionStatus.unavailable) {
      return Card(
        elevation: 2,
        color: Colors.orange.shade50,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Icon(Icons.phone_android, size: 36, color: Colors.orange),
              const SizedBox(height: 10),
              const Text(
                '健康データを利用できません',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Text(
                '歩数機能が使えない端末の可能性があります。\n歩数なしでもアプリは遊べます。',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    // error
    if (status == HealthPermissionStatus.error) {
      return Card(
        elevation: 2,
        color: Colors.grey.shade50,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(Icons.cloud_off, size: 36, color: Colors.grey.shade400),
              const SizedBox(height: 10),
              const Text(
                '歩数データを取得できませんでした',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Text(
                'しばらくしてからもう一度お試しください。',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onRequest,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('再読み込み'),
              ),
            ],
          ),
        ),
      );
    }

    // denied / unknown以外 → 許可を促す
    return Card(
      elevation: 2,
      color: const Color(0xFFFFF8E1), // あたたかいイエロー
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text('🚶', style: TextStyle(fontSize: 36)),
            const SizedBox(height: 10),
            const Text(
              '歩数データを使うと、\nペットが成長します',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '端末の歩数データを使って、散歩量に\n応じてペットの状態が変化します。',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.brown.shade400,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRequest,
              icon: const Icon(Icons.favorite, size: 18),
              label: const Text('許可する'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onSkip,
              child: Text(
                'あとで',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
            Text(
              'ヘルスケアの権限が有効になると\n歩数が反映されます',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================
// Next Goal Banner — 次目標 & 受取可能ハイライト
// =============================================================

class _NextGoalBanner extends StatelessWidget {
  final List<RewardStatus> rewardStatuses;
  final int currentSteps;
  final bool stepLoadFailed;

  const _NextGoalBanner({
    required this.rewardStatuses,
    required this.currentSteps,
    this.stepLoadFailed = false,
  });

  @override
  Widget build(BuildContext context) {
    // 歩数取得失敗時は案内表示
    if (stepLoadFailed) {
      return _buildBanner(
        color: Colors.grey.shade50,
        borderColor: Colors.grey.shade200,
        emoji: '📊',
        title: '歩数取得後に表示されます',
        titleColor: Colors.grey.shade600,
        subtitle: '歩数データを確認してください',
        subtitleColor: Colors.grey.shade400,
      );
    }
    if (rewardStatuses.isEmpty) return const SizedBox.shrink();

    // 受取可能な報酬を探す
    final available =
        rewardStatuses.where((rs) => rs.status == RewardStatusType.available);
    if (available.isNotEmpty) {
      return _buildBanner(
        gradient: LinearGradient(
          colors: [Colors.amber.shade200, Colors.orange.shade200],
        ),
        emoji: '🎁',
        title: '受け取れる報酬が ${available.length}個 あります！',
        titleColor: Colors.brown.shade800,
        subtitle: '報酬を受け取って、もちものから食べさせよう！',
        subtitleColor: Colors.brown.shade500,
        trailing: const Icon(Icons.arrow_downward, size: 18),
      );
    }

    // 次のロック中報酬を探す
    final nextLocked = rewardStatuses
        .where((rs) => rs.status == RewardStatusType.locked)
        .toList();
    if (nextLocked.isNotEmpty) {
      final next = nextLocked.first;
      final remaining = next.food.requiredSteps - currentSteps;
      return _buildBanner(
        color: Colors.blue.shade50,
        borderColor: Colors.blue.shade100,
        emoji: foodEmoji(next.food.id),
        title: 'あと $remaining歩で ${next.food.name}！',
        titleColor: Colors.blue.shade800,
        subtitle: '歩いて食材をみつけよう 🚶',
        subtitleColor: Colors.blue.shade400,
      );
    }

    // 全て受取済み
    return _buildBanner(
      color: Colors.green.shade50,
      emoji: '✅',
      title: 'きょうの報酬はすべて受取済み！',
      titleColor: Colors.green.shade700,
      subtitle: '今日はひと休み。明日も歩こう！',
      subtitleColor: Colors.green.shade400,
    );
  }

  Widget _buildBanner({
    Gradient? gradient,
    Color? color,
    Color? borderColor,
    required String emoji,
    required String title,
    required Color titleColor,
    required String subtitle,
    required Color subtitleColor,
    Widget? trailing,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: gradient,
        color: gradient == null ? color : null,
        borderRadius: BorderRadius.circular(12),
        border: borderColor != null ? Border.all(color: borderColor) : null,
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: subtitleColor,
                  ),
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

// =============================================================
// Inventory Shortcut — もちもの導線
// =============================================================

class _InventoryShortcut extends StatelessWidget {
  final List<InventoryItem> inventory;
  final VoidCallback onTap;

  const _InventoryShortcut({
    required this.inventory,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // 在庫がなければ非表示
    final totalCount =
        inventory.fold<int>(0, (sum, item) => sum + item.count);
    if (totalCount <= 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: const Text('🍽️', style: TextStyle(fontSize: 18)),
        label: Text(
          'ごはんをあげる（もちもの $totalCount個）',
          style: const TextStyle(fontSize: 14),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide(color: Colors.brown.shade200),
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
  final bool stepLoadFailed;
  final Future<void> Function(String foodId) onClaim;

  const _RewardSection({
    required this.rewardStatuses,
    required this.currentSteps,
    this.stepLoadFailed = false,
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
            // 歩数取得失敗時は報酬判定せず案内
            if (stepLoadFailed)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  '歩数取得後に判定します',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              )
            else ...[
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
