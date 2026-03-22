import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/config/ad_config.dart';

/// 広告サービス
///
/// バナー広告とリワード広告の読み込み・表示を管理する。
/// AdConfig.adsEnabled == false のときは何もしない。
class AdService {
  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;
  RewardedAd? _rewardedAd;

  /// バナー広告が読み込み済みか
  bool get isBannerLoaded => _isBannerLoaded;

  /// バナー広告インスタンス
  BannerAd? get bannerAd => _bannerAd;

  /// バナー広告を読み込む
  void loadBanner() {
    if (!AdConfig.adsEnabled) return;

    _bannerAd = BannerAd(
      adUnitId: AdConfig.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          _isBannerLoaded = true;
          _onBannerLoadedCallback?.call();
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Banner ad failed to load: $error');
          ad.dispose();
          _isBannerLoaded = false;
        },
      ),
    )..load();
  }

  /// バナー読み込み完了コールバック (UI更新用)
  VoidCallback? _onBannerLoadedCallback;
  set onBannerLoaded(VoidCallback? callback) {
    _onBannerLoadedCallback = callback;
  }

  /// リワード広告を読み込む
  void loadRewarded() {
    if (!AdConfig.adsEnabled) return;

    RewardedAd.load(
      adUnitId: AdConfig.rewardAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
        },
        onAdFailedToLoad: (error) {
          debugPrint('Rewarded ad failed to load: $error');
          _rewardedAd = null;
        },
      ),
    );
  }

  /// リワード広告を表示
  /// 報酬を受け取った場合 onReward を呼ぶ
  void showRewarded({required VoidCallback onReward}) {
    if (_rewardedAd == null) {
      debugPrint('Rewarded ad not loaded yet');
      return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        loadRewarded(); // 次の広告を事前読み込み
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('Rewarded ad failed to show: $error');
        ad.dispose();
        _rewardedAd = null;
        loadRewarded();
      },
    );

    _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        onReward();
      },
    );
  }

  /// リワード広告が表示可能か
  bool get isRewardedReady => _rewardedAd != null;

  /// リソース解放
  void dispose() {
    _bannerAd?.dispose();
    _rewardedAd?.dispose();
  }
}
