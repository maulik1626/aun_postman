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

  // Android + iOS AdMob IDs (production).
  static const String _androidAppId = 'ca-app-pub-7715109286748953~3701420942';
  static const String _iosAppId = 'ca-app-pub-7715109286748953~9608353748';
  static const String _androidBannerId =
      'ca-app-pub-7715109286748953/3740327276';
  static const String _iosBannerId = 'ca-app-pub-7715109286748953/9539448862';
  static const String _androidInterstitialId =
      'ca-app-pub-7715109286748953/8862248284';
  static const String _iosInterstitialId =
      'ca-app-pub-7715109286748953/4287122182';
  static const String _androidNativeId =
      'ca-app-pub-7715109286748953/2520201216';
  static const String _iosNativeId = 'ca-app-pub-7715109286748953/2974040512';
  static const String _androidRewardedId =
      'ca-app-pub-7715109286748953/7549166613';
  static const String _iosRewardedId = 'ca-app-pub-7715109286748953/9020574112';

  /// Google-provided sample ad units (always fill). Use only in debug.
  /// https://developers.google.com/admob/flutter/test-ads
  static const String _testAndroidBannerId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _testIosBannerId =
      'ca-app-pub-3940256099942544/2934735716';
  static const String _testAndroidInterstitialId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _testIosInterstitialId =
      'ca-app-pub-3940256099942544/4411468910';
  static const String _testAndroidNativeId =
      'ca-app-pub-3940256099942544/2247696110';
  static const String _testIosNativeId =
      'ca-app-pub-3940256099942544/3986624511';
  static const String _testAndroidRewardedId =
      'ca-app-pub-3940256099942544/5224354917';
  static const String _testIosRewardedId =
      'ca-app-pub-3940256099942544/1712485313';

  static String get appId => Platform.isAndroid ? _androidAppId : _iosAppId;

  static String get _bannerId => kDebugMode
      ? (Platform.isAndroid ? _testAndroidBannerId : _testIosBannerId)
      : (Platform.isAndroid ? _androidBannerId : _iosBannerId);

  static String get _interstitialId => kDebugMode
      ? (Platform.isAndroid
          ? _testAndroidInterstitialId
          : _testIosInterstitialId)
      : (Platform.isAndroid ? _androidInterstitialId : _iosInterstitialId);

  static String get _nativeId => kDebugMode
      ? (Platform.isAndroid ? _testAndroidNativeId : _testIosNativeId)
      : (Platform.isAndroid ? _androidNativeId : _iosNativeId);

  static String get _rewardedId => kDebugMode
      ? (Platform.isAndroid ? _testAndroidRewardedId : _testIosRewardedId)
      : (Platform.isAndroid ? _androidRewardedId : _iosRewardedId);

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
    if (!AdConfig.ENABLE_ADS) return;
    if (_initialized) return;
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
      if (kDebugMode) {
        debugPrint('AdService: using Google test ad units (debug build)');
      }
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
    if (!AdConfig.ENABLE_ADS) {
      throw StateError('Ads are disabled by AdConfig.ENABLE_ADS.');
    }
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
    if (!AdConfig.ENABLE_ADS) {
      throw StateError('Ads are disabled by AdConfig.ENABLE_ADS.');
    }
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
    if (!AdConfig.ENABLE_ADS) return;
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
    if (!AdConfig.ENABLE_ADS) return;
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
    if (!AdConfig.ENABLE_ADS) return RewardedAdShowResult.unavailable;
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
    if (!AdConfig.ENABLE_ADS) return false;
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
