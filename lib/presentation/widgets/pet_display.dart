import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/models/pet.dart';
import '../../data/models/pet_emotion.dart';
import '../../core/pet_stage_config.dart';
import '../../core/pet_asset_resolver.dart';

/// ペットの表示を担当するウィジェット
///
/// stage × emotion で画像を切り替える。
/// フォールバック: emotion画像 → normal画像 → 絵文字
class PetDisplay extends StatelessWidget {
  final Pet pet;
  final PetEmotion emotion;
  final double size;

  const PetDisplay({
    super.key,
    required this.pet,
    this.emotion = PetEmotion.normal,
    this.size = 80,
  });

  @override
  Widget build(BuildContext context) {
    // 1. emotion 用画像を試す
    final emotionPath = PetAssetResolver.assetPath(pet.stage, emotion);
    // 2. フォールバック: normal 画像
    final normalPath = PetAssetResolver.normalAssetPath(pet.stage);

    return _AssetWithFallback(
      primaryPath: emotionPath,
      fallbackPath: emotionPath != normalPath ? normalPath : null,
      fallbackEmoji: PetStageConfig.forStage(pet.stage).emoji,
      size: size,
    );
  }
}

/// アセット画像をフォールバック付きで表示
class _AssetWithFallback extends StatefulWidget {
  final String primaryPath;
  final String? fallbackPath;
  final String fallbackEmoji;
  final double size;

  const _AssetWithFallback({
    required this.primaryPath,
    this.fallbackPath,
    required this.fallbackEmoji,
    required this.size,
  });

  @override
  State<_AssetWithFallback> createState() => _AssetWithFallbackState();
}

class _AssetWithFallbackState extends State<_AssetWithFallback> {
  bool _primaryFailed = false;
  bool _fallbackFailed = false;
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    _checkAsset();
  }

  @override
  void didUpdateWidget(_AssetWithFallback oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.primaryPath != widget.primaryPath) {
      _primaryFailed = false;
      _fallbackFailed = false;
      _checked = false;
      _checkAsset();
    }
  }

  Future<void> _checkAsset() async {
    try {
      await rootBundle.load(widget.primaryPath);
      if (mounted) setState(() => _checked = true);
    } catch (_) {
      _primaryFailed = true;
      if (widget.fallbackPath != null) {
        try {
          await rootBundle.load(widget.fallbackPath!);
          if (mounted) setState(() => _checked = true);
        } catch (_) {
          _fallbackFailed = true;
          if (mounted) setState(() => _checked = true);
        }
      } else {
        _fallbackFailed = true;
        if (mounted) setState(() => _checked = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_checked) {
      // チェック中は絵文字をそのまま表示
      return Text(widget.fallbackEmoji,
          style: TextStyle(fontSize: widget.size));
    }

    if (!_primaryFailed) {
      return Image.asset(
        widget.primaryPath,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.contain,
      );
    }

    if (!_fallbackFailed && widget.fallbackPath != null) {
      return Image.asset(
        widget.fallbackPath!,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.contain,
      );
    }

    // 最終フォールバック: 絵文字
    return Text(widget.fallbackEmoji,
        style: TextStyle(fontSize: widget.size));
  }
}
