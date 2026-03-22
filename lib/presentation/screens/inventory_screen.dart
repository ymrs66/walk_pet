import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/pet.dart';
import '../../core/pet_stage_config.dart';
import '../../core/config/ad_config.dart';
import '../../domain/services/ad_service.dart';
import '../providers/providers.dart';
import '../widgets/pet_display.dart';
import '../widgets/food_helpers.dart';
import '../../data/models/food.dart';

/// インベントリ画面
class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final AdService _adService = AdService();

  @override
  void initState() {
    super.initState();
    _adService.loadRewarded();
  }

  @override
  void dispose() {
    _adService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inventory = ref.watch(inventoryProvider);
    final pet = ref.watch(petProvider);
    final gameActions = ref.read(gameActionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('もちもの'),
      ),
      body: Column(
        children: [
          // リワード広告ボタン
          if (AdConfig.adsEnabled)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (_adService.isRewardedReady) {
                      _adService.showRewarded(
                        onReward: () async {
                          // ランダム食材+1
                          final foods = ['kinomi', 'ninjin', 'osakana'];
                          final randomFood = foods[
                              DateTime.now().millisecondsSinceEpoch %
                                  foods.length];
                          await ref
                              .read(gameRepositoryProvider)
                              .addFood(randomFood);
                          ref.read(inventoryProvider.notifier).refresh();

                          if (context.mounted) {
                            final food = findFoodById(randomFood);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${foodEmoji(randomFood)} ${food?.name ?? randomFood} をゲット！',
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('動画の準備中です…もう少しお待ちください'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.play_circle_outline),
                  label: const Text('🎬 動画で特別フードをもらう'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade400,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),

          // 在庫リスト
          Expanded(
            child: inventory.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('📦', style: TextStyle(fontSize: 60)),
                        const SizedBox(height: 16),
                        const Text(
                          'まだ食材がありません',
                          style: TextStyle(fontSize: 18),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'おさんぽして食材をみつけよう！',
                          style: TextStyle(
                              fontSize: 14, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: inventory.length,
                    itemBuilder: (context, index) {
                      final item = inventory[index];
                      final food = findFoodById(item.foodId);
                      if (food == null) return const SizedBox.shrink();

                      return _FoodItemTile(
                        food: food,
                        count: item.count,
                        petName: pet.name,
                        onFeed: () async {
                          final previousStage = ref.read(petProvider).stage;
                          final success =
                              await gameActions.feedPet(item.foodId);
                          if (!context.mounted) return;

                          if (success) {
                            final reaction = getFeedingReaction(item.foodId);
                            final newPet = ref.read(petProvider);

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    Text(foodEmoji(item.foodId),
                                        style: const TextStyle(fontSize: 20)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '$reaction  EXP +${food.expValue}',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  ],
                                ),
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 2),
                              ),
                            );

                            if (previousStage != newPet.stage) {
                              _showStageUpDialog(context, newPet);
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('食べさせられません'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showStageUpDialog(BuildContext context, Pet pet) {
    final config = PetStageConfig.forStage(pet.stage);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
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
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('やったー！'),
          ),
        ],
      ),
    );
  }
}

/// 食材アイテムタイル
class _FoodItemTile extends StatelessWidget {
  final Food food;
  final int count;
  final String petName;
  final VoidCallback onFeed;

  const _FoodItemTile({
    required this.food,
    required this.count,
    required this.petName,
    required this.onFeed,
  });

  @override
  Widget build(BuildContext context) {
    final emoji = foodEmoji(food.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 36)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    food.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (food.description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      food.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.brown.shade300,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'EXP +${food.expValue}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '×$count',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: count > 0 ? onFeed : null,
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              child: Text('$petNameに\nあげる',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }
}
