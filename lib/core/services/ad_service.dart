import 'package:aun_reqstudio/core/constants/ad_config.dart';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

enum AdInterstitialPlacement { postRequest, postImportExport }

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

  static String get appId => Platform.isAndroid ? _androidAppId : _iosAppId;

  static String get _bannerId =>
      Platform.isAndroid ? _androidBannerId : _iosBannerId;

  static String get _interstitialId =>
      Platform.isAndroid ? _androidInterstitialId : _iosInterstitialId;

  static String get _nativeId =>
      Platform.isAndroid ? _androidNativeId : _iosNativeId;

  bool _initialized = false;
  bool _loadingInterstitial = false;
  bool _showingInterstitial = false;
  final Map<AdInterstitialPlacement, int> _eligibleActionCounts = {
    AdInterstitialPlacement.postRequest: 0,
    AdInterstitialPlacement.postImportExport: 0,
  };
  final Map<AdInterstitialPlacement, DateTime?> _lastInterstitialAts = {
    AdInterstitialPlacement.postRequest: null,
    AdInterstitialPlacement.postImportExport: null,
  };
  InterstitialAd? _interstitialAd;

  bool get isInitialized => _initialized;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
      await preloadInterstitial();
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

  Future<bool> maybeShowPostRequestInterstitial() async {
    return _maybeShowInterstitial(AdInterstitialPlacement.postRequest);
  }

  Future<bool> maybeShowPostImportExportInterstitial() async {
    return _maybeShowInterstitial(AdInterstitialPlacement.postImportExport);
  }

  Future<bool> _maybeShowInterstitial(AdInterstitialPlacement placement) async {
    if (!_initialized || _showingInterstitial) return false;

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
  }

  @visibleForTesting
  void resetSessionState() {
    _eligibleActionCounts.updateAll((_, __) => 0);
    _lastInterstitialAts.updateAll((_, __) => null);
    _showingInterstitial = false;
  }
}
