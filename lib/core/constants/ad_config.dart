/// Centralized ad behavior configuration for the app.
///
/// Keep all placement pacing and enable/disable switches here so ad behavior
/// can be tuned without editing feature screens or ad service logic.
abstract final class AdConfig {
  /// Default Collections insertion interval used before any user override.
  static const int defaultCollectionsInlineAdInterval = 5;

  /// Default History insertion interval used before any user override.
  static const int defaultHistoryInlineAdInterval = 5;

  /// Default Environments insertion interval used before any user override.
  static const int defaultEnvironmentsInlineAdInterval = 5;

  /// Master switch for inline native ads rendered inside list-based screens.
  static const bool nativeAdsEnabled = true;

  /// Small helper copy shown in settings near ad controls.
  static const String supportMessage =
      'Ads support the app. Keeping them enabled helps us improve and maintain ReqStudio.';

  /// Minimum inline ad interval a user can configure from Settings.
  static const int minInlineAdInterval = 1;

  /// Maximum inline ad interval a user can configure from Settings.
  static const int maxInlineAdInterval = 8;

  /// Module-level inline ad configuration for the Collections screen.
  static const AdInlineModuleConfig collections = AdInlineModuleConfig(
    enabled: true,
    insertEvery: defaultCollectionsInlineAdInterval,
  );

  /// Module-level inline ad configuration for the History screen.
  static const AdInlineModuleConfig history = AdInlineModuleConfig(
    enabled: true,
    insertEvery: defaultHistoryInlineAdInterval,
  );

  /// Module-level inline ad configuration for the Environments screen.
  static const AdInlineModuleConfig environments = AdInlineModuleConfig(
    enabled: true,
    insertEvery: defaultEnvironmentsInlineAdInterval,
  );

  /// Per-surface bottom banner behavior for empty-state layouts.
  static const AdEmptyStateBannerConfig emptyStateBottomBanners =
      AdEmptyStateBannerConfig(
        collections: false,
        history: true,
        environments: true,
      );

  /// Controls the post-response interstitial shown after successful requests.
  static const AdInterstitialConfig postRequestInterstitial =
      AdInterstitialConfig(
        enabled: true,
        eligibleActionsPerInterstitial: 3,
        cooldownMinutes: 2,
      );

  /// Controls the post-success interstitial shown in import/export flows.
  static const AdInterstitialConfig postImportExportInterstitial =
      AdInterstitialConfig(
        enabled: true,
        eligibleActionsPerInterstitial: 3,
        cooldownMinutes: 2,
      );
}

/// Configuration for inline ad insertion within a specific module/list screen.
class AdInlineModuleConfig {
  const AdInlineModuleConfig({
    required this.enabled,
    required this.insertEvery,
  });

  /// Whether inline ads are enabled for this module.
  final bool enabled;

  /// Insert one ad after every N real content rows.
  ///
  /// Example:
  /// `2` means insert after rows 2, 4, 6...
  /// `5` means insert after rows 5, 10, 15...
  final int insertEvery;

  /// Returns true when an ad should be inserted after the given row ordinal.
  bool shouldInsertAfterOrdinal(int ordinal, {int? overrideEvery}) {
    if (!enabled) return false;
    final every = overrideEvery ?? insertEvery;
    if (every <= 0) return false;
    if (ordinal <= 0) return false;
    return ordinal % every == 0;
  }
}

/// Configuration for completion-based interstitial pacing.
class AdInterstitialConfig {
  const AdInterstitialConfig({
    required this.enabled,
    required this.eligibleActionsPerInterstitial,
    required this.cooldownMinutes,
  });

  /// Whether this interstitial placement is enabled.
  final bool enabled;

  /// Minimum number of eligible completed actions before showing an ad.
  ///
  /// Example:
  /// `3` means show on every third eligible success, subject to cooldown.
  final int eligibleActionsPerInterstitial;

  /// Minimum time gap, in minutes, between shows for this placement.
  final int cooldownMinutes;
}

/// Per-screen control for bottom banners shown in empty states.
class AdEmptyStateBannerConfig {
  const AdEmptyStateBannerConfig({
    required this.collections,
    required this.history,
    required this.environments,
  });

  /// Whether Collections should show a bottom banner in its empty state.
  final bool collections;

  /// Whether History should show a bottom banner in its empty state.
  final bool history;

  /// Whether Environments should show a bottom banner in its empty state.
  final bool environments;
}
