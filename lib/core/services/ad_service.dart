import 'dart:async';

import 'package:aun_reqstudio/core/constants/ad_config.dart';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

enum AdInterstitialPlacement { postRequest, postImportExport }

enum RewardedAdShowResult { earned, unavailable, dismissed }

/// Centralized AdMob integration for banners and guarded interstitials.
class AdService {
  AdService._();

  static final AdService instance = AdService._();

  // TODO: Replace Google test IDs with production IDs before release.
  static const String _androidAppId = 'ca-app-pub-3940256099942544~3347511713';
  static const String _iosAppId = 'ca-app-pub-3940256099942544~1458002511';
  static const String _androidBannerId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _iosBannerId = 'ca-app-pub-3940256099942544/2934735716';
  static const String _androidInterstitialId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _iosInterstitialId =
      'ca-app-pub-3940256099942544/4411468910';
  static const String _androidNativeId =
      'ca-app-pub-3940256099942544/2247696110';
  static const String _iosNativeId = 'ca-app-pub-3940256099942544/3986624511';
  static const String _androidRewardedId =
      'ca-app-pub-3940256099942544/5224354917';
  static const String _iosRewardedId = 'ca-app-pub-3940256099942544/1712485313';

  static String get appId => Platform.isAndroid ? _androidAppId : _iosAppId;

  static String get _bannerId =>
      Platform.isAndroid ? _androidBannerId : _iosBannerId;

  static String get _interstitialId =>
      Platform.isAndroid ? _androidInterstitialId : _iosInterstitialId;

  static String get _nativeId =>
      Platform.isAndroid ? _androidNativeId : _iosNativeId;

  static String get _rewardedId =>
      Platform.isAndroid ? _androidRewardedId : _iosRewardedId;

  bool _initialized = false;
  bool _loadingInterstitial = false;
  bool _showingInterstitial = false;
  bool _loadingRewarded = false;
  bool _showingRewarded = false;
  final Map<AdInterstitialPlacement, int> _eligibleActionCounts = {
    AdInterstitialPlacement.postRequest: 0,
    AdInterstitialPlacement.postImportExport: 0,
  };
  final Map<AdInterstitialPlacement, DateTime?> _lastInterstitialAts = {
    AdInterstitialPlacement.postRequest: null,
    AdInterstitialPlacement.postImportExport: null,
  };
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;

  bool get isInitialized => _initialized;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
      await preloadInterstitial();
      await preloadRewardedAd();
      debugPrint('AdService: Mobile Ads initialized');
    } catch (e) {
      debugPrint('AdService: initialization failed - $e');
    }
  }

  NativeAd createInlineNativeAd({
    required NativeTemplateStyle templateStyle,
    void Function(Ad)? onAdLoaded,
    void Function(Ad, LoadAdError)? onAdFailedToLoad,
  }) {
    return NativeAd(
      adUnitId: _nativeId,
      request: const AdRequest(),
      nativeTemplateStyle: templateStyle,
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          debugPrint('AdService: native ad loaded');
          onAdLoaded?.call(ad);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('AdService: native ad failed to load - $error');
          ad.dispose();
          onAdFailedToLoad?.call(ad, error);
        },
      ),
    );
  }

  BannerAd createBottomBannerAd({
    void Function(Ad)? onAdLoaded,
    void Function(Ad, LoadAdError)? onAdFailedToLoad,
  }) {
    return _createBannerAd(
      onAdLoaded: onAdLoaded,
      onAdFailedToLoad: onAdFailedToLoad,
    );
  }

  BannerAd _createBannerAd({
    required void Function(Ad)? onAdLoaded,
    required void Function(Ad, LoadAdError)? onAdFailedToLoad,
  }) {
    return BannerAd(
      adUnitId: _bannerId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('AdService: banner loaded');
          onAdLoaded?.call(ad);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('AdService: banner failed to load - $error');
          ad.dispose();
          onAdFailedToLoad?.call(ad, error);
        },
      ),
    );
  }

  Future<void> preloadInterstitial() async {
    if (!_initialized || _loadingInterstitial || _interstitialAd != null) {
      return;
    }
    _loadingInterstitial = true;
    await InterstitialAd.load(
      adUnitId: _interstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('AdService: interstitial loaded');
          _loadingInterstitial = false;
          _interstitialAd = ad;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (_) {
              _showingInterstitial = true;
            },
            onAdDismissedFullScreenContent: (ad) {
              debugPrint('AdService: interstitial dismissed');
              _showingInterstitial = false;
              ad.dispose();
              _interstitialAd = null;
              preloadInterstitial();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('AdService: interstitial failed to show - $error');
              _showingInterstitial = false;
              ad.dispose();
              _interstitialAd = null;
              preloadInterstitial();
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('AdService: interstitial failed to load - $error');
          _loadingInterstitial = false;
          _interstitialAd = null;
        },
      ),
    );
  }

  Future<void> preloadRewardedAd() async {
    if (!_initialized || _loadingRewarded || _rewardedAd != null) {
      return;
    }
    _loadingRewarded = true;
    await RewardedAd.load(
      adUnitId: _rewardedId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('AdService: rewarded ad loaded');
          _loadingRewarded = false;
          _rewardedAd = ad;
        },
        onAdFailedToLoad: (error) {
          debugPrint('AdService: rewarded ad failed to load - $error');
          _loadingRewarded = false;
          _rewardedAd = null;
        },
      ),
    );
  }

  Future<RewardedAdShowResult> showRewardedAdForBrowseAdPause() async {
    if (!_initialized || _showingInterstitial || _showingRewarded) {
      return RewardedAdShowResult.unavailable;
    }

    var ad = _rewardedAd;
    if (ad == null) {
      await preloadRewardedAd();
      ad = _rewardedAd;
    }
    if (ad == null) {
      debugPrint('AdService: rewarded ad skipped, no rewarded ad ready');
      return RewardedAdShowResult.unavailable;
    }

    _rewardedAd = null;
    var earned = false;
    final completer = Completer<RewardedAdShowResult>();

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) {
        _showingRewarded = true;
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('AdService: rewarded ad dismissed');
        _showingRewarded = false;
        ad.dispose();
        preloadRewardedAd();
        if (!completer.isCompleted) {
          completer.complete(
            earned
                ? RewardedAdShowResult.earned
                : RewardedAdShowResult.dismissed,
          );
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('AdService: rewarded ad failed to show - $error');
        _showingRewarded = false;
        ad.dispose();
        preloadRewardedAd();
        if (!completer.isCompleted) {
          completer.complete(RewardedAdShowResult.unavailable);
        }
      },
    );

    await ad.show(
      onUserEarnedReward: (_, reward) {
        earned = true;
        debugPrint(
          'AdService: rewarded ad earned - ${reward.amount} ${reward.type}',
        );
      },
    );
    return completer.future;
  }

  Future<bool> maybeShowPostRequestInterstitial() async {
    return _maybeShowInterstitial(AdInterstitialPlacement.postRequest);
  }

  Future<bool> maybeShowPostImportExportInterstitial() async {
    return _maybeShowInterstitial(AdInterstitialPlacement.postImportExport);
  }

  Future<bool> _maybeShowInterstitial(AdInterstitialPlacement placement) async {
    if (!_initialized || _showingInterstitial || _showingRewarded) {
      return false;
    }

    final config = switch (placement) {
      AdInterstitialPlacement.postRequest => AdConfig.postRequestInterstitial,
      AdInterstitialPlacement.postImportExport =>
        AdConfig.postImportExportInterstitial,
    };
    if (!config.enabled) return false;

    final nextCount = (_eligibleActionCounts[placement] ?? 0) + 1;
    _eligibleActionCounts[placement] = nextCount;

    if (nextCount < config.eligibleActionsPerInterstitial) {
      debugPrint(
        'AdService: $placement skipped, count $nextCount/${config.eligibleActionsPerInterstitial}',
      );
      preloadInterstitial();
      return false;
    }

    final now = DateTime.now();
    final lastShown = _lastInterstitialAts[placement];
    final cooldown = Duration(minutes: config.cooldownMinutes);
    if (lastShown != null && now.difference(lastShown) < cooldown) {
      debugPrint('AdService: $placement skipped, cooldown active');
      preloadInterstitial();
      return false;
    }

    final ad = _interstitialAd;
    if (ad == null) {
      debugPrint('AdService: $placement skipped, no interstitial ready');
      preloadInterstitial();
      return false;
    }

    _eligibleActionCounts[placement] = 0;
    _lastInterstitialAts[placement] = now;
    _interstitialAd = null;
    await ad.show();
    return true;
  }

  void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _rewardedAd?.dispose();
    _rewardedAd = null;
  }

  @visibleForTesting
  void resetSessionState() {
    _eligibleActionCounts.updateAll((_, __) => 0);
    _lastInterstitialAts.updateAll((_, __) => null);
    _showingInterstitial = false;
    _showingRewarded = false;
  }
}
