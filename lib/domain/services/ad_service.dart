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
  bool _isLoadingRewarded = false;

  /// バナー広告が読み込み済みか
  bool get isBannerLoaded => _isBannerLoaded;

  /// バナー広告インスタンス
  BannerAd? get bannerAd => _bannerAd;

  // ─── Banner ───

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
          _onBannerStateChanged?.call();
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Banner ad failed to load: $error');
          ad.dispose();
          _bannerAd = null;
          _isBannerLoaded = false;
          _onBannerStateChanged?.call();
        },
      ),
    )..load();
  }

  /// バナー読み込み結果コールバック (成功/失敗両方で呼ばれる)
  VoidCallback? _onBannerStateChanged;
  set onBannerStateChanged(VoidCallback? callback) {
    _onBannerStateChanged = callback;
  }

  /// 後方互換: 旧 setter 名
  set onBannerLoaded(VoidCallback? callback) {
    _onBannerStateChanged = callback;
  }

  // ─── Rewarded ───

  /// リワード広告の最大再試行回数
  static const _maxRetry = 1;

  /// リワード広告を読み込む
  ///
  /// 失敗時は 3 秒後に1回だけ自動再試行する。
  void loadRewarded({int retryCount = 0}) {
    if (!AdConfig.adsEnabled) return;
    if (_isLoadingRewarded) return; // 多重呼び出し防止
    _isLoadingRewarded = true;

    RewardedAd.load(
      adUnitId: AdConfig.rewardAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isLoadingRewarded = false;
          debugPrint('[AdService] Rewarded ad loaded');
        },
        onAdFailedToLoad: (error) {
          debugPrint('Rewarded ad failed to load: $error');
          _rewardedAd = null;
          _isLoadingRewarded = false;

          // 自動再試行 (1回のみ、3秒後)
          if (retryCount < _maxRetry) {
            debugPrint('[AdService] Rewarded ad retry in 3s '
                '(attempt ${retryCount + 1}/$_maxRetry)');
            Future.delayed(const Duration(seconds: 3), () {
              loadRewarded(retryCount: retryCount + 1);
            });
          }
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

  /// リワード広告を読み込み中か
  bool get isRewardedLoading => _isLoadingRewarded;

  /// リソース解放
  void dispose() {
    _bannerAd?.dispose();
    _rewardedAd?.dispose();
  }
}
