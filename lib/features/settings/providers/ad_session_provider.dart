import 'dart:async';

import 'package:aun_reqstudio/core/constants/ad_config.dart';
import 'package:aun_reqstudio/core/constants/app_constants.dart';
import 'package:aun_reqstudio/core/notifications/user_notification.dart';
import 'package:aun_reqstudio/core/services/ad_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum RewardBrowseAdsResult { earned, unavailable, dismissed }

class AdSessionState {
  const AdSessionState({
    this.browseAdsDisabledByReward = false,
    this.isLoadingRewardedAd = false,
    this.browseAdsPausedUntil,
  });

  final bool browseAdsDisabledByReward;
  final bool isLoadingRewardedAd;
  final DateTime? browseAdsPausedUntil;

  AdSessionState copyWith({
    bool? browseAdsDisabledByReward,
    bool? isLoadingRewardedAd,
    DateTime? browseAdsPausedUntil,
    bool clearBrowseAdsPausedUntil = false,
  }) {
    return AdSessionState(
      browseAdsDisabledByReward:
          browseAdsDisabledByReward ?? this.browseAdsDisabledByReward,
      isLoadingRewardedAd: isLoadingRewardedAd ?? this.isLoadingRewardedAd,
      browseAdsPausedUntil: clearBrowseAdsPausedUntil
          ? null
          : (browseAdsPausedUntil ?? this.browseAdsPausedUntil),
    );
  }
}

class AdSessionNotifier extends StateNotifier<AdSessionState> {
  AdSessionNotifier() : super(const AdSessionState()) {
    _load();
  }

  static const _storage = FlutterSecureStorage();
  Timer? _pauseExpiryTimer;

  Future<void> _load() async {
    final raw = await _storage.read(key: StorageKeys.browseAdsPausedUntil);
    final pausedUntil = raw != null ? DateTime.tryParse(raw) : null;
    if (pausedUntil == null) return;

    if (!pausedUntil.isAfter(DateTime.now())) {
      await _clearPersistedPause();
      return;
    }
    _setPausedUntil(pausedUntil);
  }

  void _setPausedUntil(DateTime pausedUntil) {
    _scheduleExpiry(pausedUntil);
    unawaited(
      UserNotification.scheduleBrowseAdsExpiryReminder(
        pausedUntil: pausedUntil,
        extensionMinutes: AdConfig.rewardedBrowseAdsPauseMinutes,
      ),
    );
    state = state.copyWith(
      browseAdsDisabledByReward: true,
      browseAdsPausedUntil: pausedUntil,
    );
  }

  void _scheduleExpiry(DateTime pausedUntil) {
    _pauseExpiryTimer?.cancel();
    final duration = pausedUntil.difference(DateTime.now());
    if (duration <= Duration.zero) {
      unawaited(disableBrowseAdRewardMode());
      return;
    }
    _pauseExpiryTimer = Timer(duration, () {
      unawaited(disableBrowseAdRewardMode());
    });
  }

  Future<void> _clearPersistedPause() async {
    _pauseExpiryTimer?.cancel();
    await UserNotification.cancelBrowseAdsExpiryReminder();
    await _storage.delete(key: StorageKeys.browseAdsPausedUntil);
    state = state.copyWith(
      browseAdsDisabledByReward: false,
      isLoadingRewardedAd: false,
      clearBrowseAdsPausedUntil: true,
    );
  }

  Future<RewardBrowseAdsResult> enableBrowseAdRewardMode() async {
    if (state.isLoadingRewardedAd) {
      return RewardBrowseAdsResult.dismissed;
    }

    state = state.copyWith(isLoadingRewardedAd: true);
    final result = await AdService.instance.showRewardedAdForBrowseAdPause();

    if (result == RewardedAdShowResult.earned) {
      final pausedUntil = DateTime.now().add(
        const Duration(minutes: AdConfig.rewardedBrowseAdsPauseMinutes),
      );
      await _storage.write(
        key: StorageKeys.browseAdsPausedUntil,
        value: pausedUntil.toIso8601String(),
      );
      _setPausedUntil(pausedUntil);
      state = state.copyWith(isLoadingRewardedAd: false);
      return RewardBrowseAdsResult.earned;
    }

    state = state.copyWith(isLoadingRewardedAd: false);
    if (result == RewardedAdShowResult.unavailable) {
      return RewardBrowseAdsResult.unavailable;
    }
    return RewardBrowseAdsResult.dismissed;
  }

  Future<RewardBrowseAdsResult> extendBrowseAdRewardMode() async {
    if (!state.browseAdsDisabledByReward || state.isLoadingRewardedAd) {
      return RewardBrowseAdsResult.dismissed;
    }

    state = state.copyWith(isLoadingRewardedAd: true);
    final result = await AdService.instance.showRewardedAdForBrowseAdPause();

    if (result == RewardedAdShowResult.earned) {
      final base = state.browseAdsPausedUntil?.isAfter(DateTime.now()) == true
          ? state.browseAdsPausedUntil!
          : DateTime.now();
      final pausedUntil = base.add(
        const Duration(minutes: AdConfig.rewardedBrowseAdsPauseMinutes),
      );
      await _storage.write(
        key: StorageKeys.browseAdsPausedUntil,
        value: pausedUntil.toIso8601String(),
      );
      _setPausedUntil(pausedUntil);
      state = state.copyWith(isLoadingRewardedAd: false);
      return RewardBrowseAdsResult.earned;
    }

    state = state.copyWith(isLoadingRewardedAd: false);
    if (result == RewardedAdShowResult.unavailable) {
      return RewardBrowseAdsResult.unavailable;
    }
    return RewardBrowseAdsResult.dismissed;
  }

  Future<void> disableBrowseAdRewardMode() async {
    await _clearPersistedPause();
  }

  @override
  void dispose() {
    _pauseExpiryTimer?.cancel();
    super.dispose();
  }
}

final adSessionProvider =
    StateNotifierProvider<AdSessionNotifier, AdSessionState>(
      (_) => AdSessionNotifier(),
    );

final adSessionNowProvider = StreamProvider.autoDispose<DateTime>((ref) {
  return Stream<DateTime>.periodic(
    const Duration(seconds: 1),
    (_) => DateTime.now(),
  );
});
