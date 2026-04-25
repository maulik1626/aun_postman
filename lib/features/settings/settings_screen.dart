import 'dart:io' show Platform;

import 'package:aun_reqstudio/app/router/app_routes.dart';
import 'package:aun_reqstudio/app/screenshot_feedback/app_feedback_flow.dart';
import 'package:aun_reqstudio/app/widgets/scaled_cupertino_switch.dart';
import 'package:aun_reqstudio/app/theme/app_theme_provider.dart';
import 'package:aun_reqstudio/app/widgets/cupertino_licenses_page.dart';
import 'package:aun_reqstudio/core/constants/ad_config.dart';
import 'package:aun_reqstudio/core/constants/app_constants.dart';
import 'package:aun_reqstudio/core/constants/legal_urls.dart';
import 'package:aun_reqstudio/core/notifications/user_notification.dart';
import 'package:aun_reqstudio/core/services/crashlytics_service.dart';
import 'package:aun_reqstudio/domain/enums/theme_preference.dart';
import 'package:aun_reqstudio/features/auth/providers/auth_provider.dart';
import 'package:aun_reqstudio/features/collections/providers/collections_provider.dart';
import 'package:aun_reqstudio/features/environments/providers/environments_provider.dart';
import 'package:aun_reqstudio/features/history/providers/history_provider.dart';
import 'package:aun_reqstudio/features/settings/providers/ad_session_provider.dart';
import 'package:aun_reqstudio/features/settings/providers/app_settings_provider.dart';
import 'package:aun_reqstudio/features/settings/widgets/legal_document_sheet.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = ref.watch(appThemeNotifierProvider);
    final settings = ref.watch(appSettingsProvider);
    final adSession = ref.watch(adSessionProvider);
    final adSessionNow =
        ref.watch(adSessionNowProvider).value ?? DateTime.now();
    final auth = ref.watch(authControllerProvider);

    final bottomInset = MediaQuery.of(context).padding.bottom;

    return CupertinoPageScaffold(
      child: CustomScrollView(
        physics: const NeverScrollableScrollPhysics(),
        slivers: [
          const CupertinoSliverNavigationBar(largeTitle: Text('Settings')),
          SliverFillRemaining(
            hasScrollBody: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      const _SectionHeader(title: 'Appearance'),
                      _SettingsGroup(
                        children: [
                          GestureDetector(
                            onTap: () =>
                                _showThemePicker(context, ref, brightness),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 13,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    CupertinoIcons.paintbrush,
                                    color: CupertinoTheme.of(
                                      context,
                                    ).primaryColor,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text(
                                      'Theme',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ),
                                  Text(
                                    _currentPreference(brightness).label,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: CupertinoColors.secondaryLabel
                                          .resolveFrom(context),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(
                                    CupertinoIcons.chevron_right,
                                    size: 14,
                                    color: CupertinoColors.tertiaryLabel
                                        .resolveFrom(context),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const _SectionHeader(title: 'Account'),
                      _SettingsGroup(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 13,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  CupertinoIcons
                                      .person_crop_circle_badge_checkmark,
                                  color: CupertinoColors.systemGreen
                                      .resolveFrom(context),
                                  size: 22,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Signed In As',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                      Text(
                                        auth.user?.email ?? 'Unknown account',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: CupertinoColors.secondaryLabel
                                              .resolveFrom(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const _SectionHeader(title: 'Requests'),
                      _SettingsGroup(
                        children: [
                          GestureDetector(
                            onTap: () => _showTimeoutPicker(
                              context,
                              ref,
                              settings.timeoutSeconds,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 13,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    CupertinoIcons.timer,
                                    color: CupertinoColors.systemOrange
                                        .resolveFrom(context),
                                    size: 22,
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text(
                                      'Timeout',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ),
                                  Text(
                                    '${settings.timeoutSeconds}s',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: CupertinoColors.secondaryLabel
                                          .resolveFrom(context),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(
                                    CupertinoIcons.chevron_right,
                                    size: 14,
                                    color: CupertinoColors.tertiaryLabel
                                        .resolveFrom(context),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Container(
                            height: 0.5,
                            margin: const EdgeInsets.only(left: 50),
                            color: CupertinoColors.separator.resolveFrom(
                              context,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  CupertinoIcons.arrow_right_arrow_left,
                                  color: CupertinoColors.systemBlue.resolveFrom(
                                    context,
                                  ),
                                  size: 22,
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'Follow Redirects',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ),
                                ScaledCupertinoSwitch(
                                  value: settings.followRedirects,
                                  onChanged: (v) => ref
                                      .read(appSettingsProvider.notifier)
                                      .setFollowRedirects(v),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            height: 0.5,
                            margin: const EdgeInsets.only(left: 50),
                            color: CupertinoColors.separator.resolveFrom(
                              context,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(
                                  CupertinoIcons.doc_on_doc,
                                  color: CupertinoColors.systemPurple
                                      .resolveFrom(context),
                                  size: 22,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Auto-save requests',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                      Text(
                                        'When a URL is present, edits sync into the open collection. Drafts still cover quick app restarts.',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: CupertinoColors.secondaryLabel
                                              .resolveFrom(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ScaledCupertinoSwitch(
                                  value: settings.requestAutoSave,
                                  onChanged: (v) => ref
                                      .read(appSettingsProvider.notifier)
                                      .setRequestAutoSave(v),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            height: 0.5,
                            margin: const EdgeInsets.only(left: 50),
                            color: CupertinoColors.separator.resolveFrom(
                              context,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(
                                  CupertinoIcons.lock_shield,
                                  color: CupertinoColors.systemGreen
                                      .resolveFrom(context),
                                  size: 22,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Verify SSL',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                      Text(
                                        'Turn off only for trusted dev servers (not on web).',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: CupertinoColors.secondaryLabel
                                              .resolveFrom(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ScaledCupertinoSwitch(
                                  value: settings.verifySsl,
                                  onChanged: (v) => ref
                                      .read(appSettingsProvider.notifier)
                                      .setVerifySsl(v),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            height: 0.5,
                            margin: const EdgeInsets.only(left: 50),
                            color: CupertinoColors.separator.resolveFrom(
                              context,
                            ),
                          ),
                          GestureDetector(
                            onTap: () =>
                                context.push(AppRoutes.settingsDefaultHeaders),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 13,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    CupertinoIcons.list_bullet,
                                    color: CupertinoColors.systemTeal
                                        .resolveFrom(context),
                                    size: 22,
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text(
                                      'Default Headers',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ),
                                  Text(
                                    '${settings.defaultHeaders.where((h) => h.isEnabled && h.key.trim().isNotEmpty).length}',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: CupertinoColors.secondaryLabel
                                          .resolveFrom(context),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(
                                    CupertinoIcons.chevron_right,
                                    size: 14,
                                    color: CupertinoColors.tertiaryLabel
                                        .resolveFrom(context),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Container(
                            height: 0.5,
                            margin: const EdgeInsets.only(left: 50),
                            color: CupertinoColors.separator.resolveFrom(
                              context,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => context.push(AppRoutes.settingsProxy),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 13,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    CupertinoIcons.arrow_right_square,
                                    color: CupertinoColors.systemIndigo
                                        .resolveFrom(context),
                                    size: 22,
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text(
                                      'HTTP Proxy',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ),
                                  Text(
                                    settings.httpProxy.isEmpty ? 'Off' : 'On',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: CupertinoColors.secondaryLabel
                                          .resolveFrom(context),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(
                                    CupertinoIcons.chevron_right,
                                    size: 14,
                                    color: CupertinoColors.tertiaryLabel
                                        .resolveFrom(context),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Container(
                            height: 0.5,
                            margin: const EdgeInsets.only(left: 50),
                            color: CupertinoColors.separator.resolveFrom(
                              context,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => context.push(AppRoutes.importExport),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 13,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    CupertinoIcons.arrow_up_arrow_down_circle,
                                    color: CupertinoColors.systemOrange
                                        .resolveFrom(context),
                                    size: 22,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Import / Export',
                                          style: TextStyle(fontSize: 16),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Collection files, cURL, full backup',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: CupertinoColors
                                                .secondaryLabel
                                                .resolveFrom(context),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    CupertinoIcons.chevron_right,
                                    size: 14,
                                    color: CupertinoColors.tertiaryLabel
                                        .resolveFrom(context),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (Platform.isIOS) ...[
                            Container(
                              height: 0.5,
                              margin: const EdgeInsets.only(left: 50),
                              color: CupertinoColors.separator.resolveFrom(
                                context,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(
                                    CupertinoIcons.cloud_fill,
                                    color: CupertinoColors.systemBlue
                                        .resolveFrom(context),
                                    size: 22,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'iCloud auto-backup',
                                          style: TextStyle(fontSize: 16),
                                        ),
                                        Text(
                                          'After you leave the app, saves a full backup '
                                          'to iCloud (same data as Import/Export).',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: CupertinoColors
                                                .secondaryLabel
                                                .resolveFrom(context),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  ScaledCupertinoSwitch(
                                    value: settings.icloudAutoBackup,
                                    onChanged: (v) => ref
                                        .read(appSettingsProvider.notifier)
                                        .setIcloudAutoBackup(v),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (AppConstants.enableAds) ...[
                        const _SectionHeader(title: 'Ads'),
                        _SettingsGroup(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 13,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(
                                    CupertinoIcons.heart,
                                    color: CupertinoColors.systemPink
                                        .resolveFrom(context),
                                    size: 22,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Why ads matter',
                                          style: TextStyle(fontSize: 16),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          AdConfig.supportMessage,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: CupertinoColors
                                                .secondaryLabel
                                                .resolveFrom(context),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              height: 0.5,
                              margin: const EdgeInsets.only(left: 50),
                              color: CupertinoColors.separator.resolveFrom(
                                context,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(
                                    CupertinoIcons.play_rectangle,
                                    color: CupertinoColors.systemYellow
                                        .resolveFrom(context),
                                    size: 22,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Pause Browse Ads',
                                          style: TextStyle(fontSize: 16),
                                        ),
                                        Text(
                                          adSession.browseAdsDisabledByReward
                                              ? 'Browse ads are paused until ${_formatPauseExpiry(adSession.browseAdsPausedUntil)}. Auto resets in ${_formatCountdown(adSession.browseAdsPausedUntil, adSessionNow)}.'
                                              : 'Watch a rewarded ad to pause Collections, History, and Environments ads for ${AdConfig.rewardedBrowseAdsPauseMinutes} minutes.',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: CupertinoColors
                                                .secondaryLabel
                                                .resolveFrom(context),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  ScaledCupertinoSwitch(
                                    value: adSession.browseAdsDisabledByReward,
                                    onChanged: adSession.isLoadingRewardedAd
                                        ? null
                                        : (enabled) =>
                                              _handleRewardedBrowseAdsToggle(
                                                context,
                                                ref,
                                                enabled,
                                              ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              height: 0.5,
                              margin: const EdgeInsets.only(left: 50),
                              color: CupertinoColors.separator.resolveFrom(
                                context,
                              ),
                            ),
                            _CupertinoSettingsActionRow(
                              icon: CupertinoIcons.folder,
                              iconColor: CupertinoColors.systemBlue.resolveFrom(
                                context,
                              ),
                              title: 'Collections ad interval',
                              value: '${settings.collectionsAdInterval}',
                              subtitle: _adIntervalHelperText(
                                defaultValue:
                                    AdConfig.defaultCollectionsInlineAdInterval,
                                pausedByReward:
                                    adSession.browseAdsDisabledByReward,
                              ),
                              enabled: !adSession.browseAdsDisabledByReward,
                              onTap: adSession.browseAdsDisabledByReward
                                  ? null
                                  : () => _showAdIntervalEditor(
                                      context,
                                      ref,
                                      title: 'Collections Ad Interval',
                                      current: settings.collectionsAdInterval,
                                      onSave: (value) => ref
                                          .read(appSettingsProvider.notifier)
                                          .setCollectionsAdInterval(value),
                                    ),
                            ),
                            Container(
                              height: 0.5,
                              margin: const EdgeInsets.only(left: 50),
                              color: CupertinoColors.separator.resolveFrom(
                                context,
                              ),
                            ),
                            _CupertinoSettingsActionRow(
                              icon: CupertinoIcons.time,
                              iconColor: CupertinoColors.systemOrange
                                  .resolveFrom(context),
                              title: 'History ad interval',
                              value: '${settings.historyAdInterval}',
                              subtitle: _adIntervalHelperText(
                                defaultValue:
                                    AdConfig.defaultHistoryInlineAdInterval,
                                pausedByReward:
                                    adSession.browseAdsDisabledByReward,
                              ),
                              enabled: !adSession.browseAdsDisabledByReward,
                              onTap: adSession.browseAdsDisabledByReward
                                  ? null
                                  : () => _showAdIntervalEditor(
                                      context,
                                      ref,
                                      title: 'History Ad Interval',
                                      current: settings.historyAdInterval,
                                      onSave: (value) => ref
                                          .read(appSettingsProvider.notifier)
                                          .setHistoryAdInterval(value),
                                    ),
                            ),
                            Container(
                              height: 0.5,
                              margin: const EdgeInsets.only(left: 50),
                              color: CupertinoColors.separator.resolveFrom(
                                context,
                              ),
                            ),
                            _CupertinoSettingsActionRow(
                              icon: CupertinoIcons.slider_horizontal_3,
                              iconColor: CupertinoColors.systemTeal.resolveFrom(
                                context,
                              ),
                              title: 'Environments ad interval',
                              value: '${settings.environmentsAdInterval}',
                              subtitle: _adIntervalHelperText(
                                defaultValue: AdConfig
                                    .defaultEnvironmentsInlineAdInterval,
                                pausedByReward:
                                    adSession.browseAdsDisabledByReward,
                              ),
                              enabled: !adSession.browseAdsDisabledByReward,
                              onTap: adSession.browseAdsDisabledByReward
                                  ? null
                                  : () => _showAdIntervalEditor(
                                      context,
                                      ref,
                                      title: 'Environments Ad Interval',
                                      current: settings.environmentsAdInterval,
                                      onSave: (value) => ref
                                          .read(appSettingsProvider.notifier)
                                          .setEnvironmentsAdInterval(value),
                                    ),
                            ),
                          ],
                        ),
                      ],
                      const _SectionHeader(title: 'Feedback'),
                      _SettingsGroup(
                        children: [
                          _CupertinoSettingsActionRow(
                            icon: CupertinoIcons.chat_bubble_2,
                            iconColor: CupertinoColors.systemBlue,
                            title: 'Send App Feedback / Report Bug',
                            value: 'Compose',
                            subtitle:
                                'Add a message, an image, or both before sending.',
                            enabled: true,
                            onTap: () => AppFeedbackFlow.showComposer(
                              context: context,
                              ref: ref,
                              useMaterial: false,
                            ),
                          ),
                        ],
                      ),
                      const _SectionHeader(title: 'About'),
                      FutureBuilder<PackageInfo>(
                        future: PackageInfo.fromPlatform(),
                        builder: (context, snapshot) {
                          final info = snapshot.data;
                          final versionLabel = info != null
                              ? '${info.version} (${info.buildNumber})'
                              : '—';
                          return _SettingsGroup(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 13,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      CupertinoIcons.info_circle,
                                      color: CupertinoColors.systemBlue
                                          .resolveFrom(context),
                                      size: 22,
                                    ),
                                    const SizedBox(width: 12),
                                    const Expanded(
                                      child: Text(
                                        'Version',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    ),
                                    Text(
                                      versionLabel,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: CupertinoColors.secondaryLabel
                                            .resolveFrom(context),
                                        fontFamily: 'JetBrainsMono',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                height: 0.5,
                                margin: const EdgeInsets.only(left: 50),
                                color: CupertinoColors.separator.resolveFrom(
                                  context,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 13,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      CupertinoIcons.app_badge,
                                      color: CupertinoColors.systemIndigo
                                          .resolveFrom(context),
                                      size: 22,
                                    ),
                                    const SizedBox(width: 12),
                                    const Expanded(
                                      child: Text(
                                        'App Name',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    ),
                                    Text(
                                      info?.appName ?? 'AUN - ReqStudio',
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: CupertinoColors.secondaryLabel
                                            .resolveFrom(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      if (CrashlyticsService.showsInternalTools) ...[
                        const _SectionHeader(title: 'Internal QA'),
                        _SettingsGroup(
                          children: [
                            _CupertinoSettingsActionRow(
                              icon: CupertinoIcons.ant,
                              iconColor: CupertinoColors.systemOrange,
                              title: 'Send test non-fatal',
                              value: 'Send',
                              subtitle:
                                  'Records a verification event without crashing the app.',
                              enabled: true,
                              onTap: () => _recordCrashlyticsNonFatal(context),
                            ),
                            Container(
                              height: 0.5,
                              margin: const EdgeInsets.only(left: 50),
                              color: CupertinoColors.separator.resolveFrom(
                                context,
                              ),
                            ),
                            _CupertinoSettingsActionRow(
                              icon: CupertinoIcons.exclamationmark_triangle,
                              iconColor: CupertinoColors.systemRed,
                              title: 'Force test crash',
                              value: 'Crash',
                              subtitle:
                                  'Terminates the app so Firebase can verify fatal reporting.',
                              enabled: true,
                              onTap: () => _confirmForceCrash(context),
                            ),
                          ],
                        ),
                      ],
                      const _SectionHeader(title: 'Legal'),
                      _SettingsGroup(
                        children: [
                          GestureDetector(
                            onTap: () => showLegalDocumentSheetCupertino(
                              context,
                              url: LegalUrls.support,
                              title: 'Support',
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 13,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    CupertinoIcons.question_circle,
                                    color: CupertinoColors.systemBlue
                                        .resolveFrom(context),
                                    size: 22,
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text(
                                      'Support',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ),
                                  Icon(
                                    CupertinoIcons.chevron_right,
                                    size: 14,
                                    color: CupertinoColors.tertiaryLabel
                                        .resolveFrom(context),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Container(
                            height: 0.5,
                            margin: const EdgeInsets.only(left: 50),
                            color: CupertinoColors.separator.resolveFrom(
                              context,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => showLegalDocumentSheetCupertino(
                              context,
                              url: LegalUrls.privacyPolicy,
                              title: 'Privacy Policy',
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 13,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    CupertinoIcons.lock_shield,
                                    color: CupertinoColors.systemTeal
                                        .resolveFrom(context),
                                    size: 22,
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text(
                                      'Privacy Policy',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ),
                                  Icon(
                                    CupertinoIcons.chevron_right,
                                    size: 14,
                                    color: CupertinoColors.tertiaryLabel
                                        .resolveFrom(context),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Container(
                            height: 0.5,
                            margin: const EdgeInsets.only(left: 50),
                            color: CupertinoColors.separator.resolveFrom(
                              context,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => showLegalDocumentSheetCupertino(
                              context,
                              url: LegalUrls.termsOfService,
                              title: 'Terms of Service',
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 13,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    CupertinoIcons.doc_text,
                                    color: CupertinoColors.systemIndigo
                                        .resolveFrom(context),
                                    size: 22,
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text(
                                      'Terms of Service',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ),
                                  Icon(
                                    CupertinoIcons.chevron_right,
                                    size: 14,
                                    color: CupertinoColors.tertiaryLabel
                                        .resolveFrom(context),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Container(
                            height: 0.5,
                            margin: const EdgeInsets.only(left: 50),
                            color: CupertinoColors.separator.resolveFrom(
                              context,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => showCupertinoLicensePage(context),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 13,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    CupertinoIcons.shield,
                                    color: CupertinoColors.systemGreen
                                        .resolveFrom(context),
                                    size: 22,
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text(
                                      'Open Source Licenses',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ),
                                  Icon(
                                    CupertinoIcons.chevron_right,
                                    size: 14,
                                    color: CupertinoColors.tertiaryLabel
                                        .resolveFrom(context),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const _SectionHeader(title: 'Danger Zone'),
                      _SettingsGroup(
                        children: [
                          CupertinoButton(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 13,
                            ),
                            onPressed: () => _confirmClearAll(context, ref),
                            child: Row(
                              children: [
                                const Icon(
                                  CupertinoIcons.trash,
                                  color: CupertinoColors.destructiveRed,
                                  size: 22,
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'Clear All Data',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: CupertinoColors.destructiveRed,
                                    ),
                                  ),
                                ),
                                Icon(
                                  CupertinoIcons.chevron_right,
                                  size: 14,
                                  color: CupertinoColors.tertiaryLabel
                                      .resolveFrom(context),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const _SectionHeader(title: 'Session'),
                      _SettingsGroup(
                        children: [
                          CupertinoButton(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 13,
                            ),
                            onPressed: auth.isBusy
                                ? null
                                : () => ref
                                      .read(authControllerProvider.notifier)
                                      .signOut(),
                            child: Row(
                              children: [
                                const Icon(
                                  CupertinoIcons.square_arrow_right,
                                  color: CupertinoColors.systemRed,
                                  size: 22,
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'Sign Out',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: CupertinoColors.systemRed,
                                    ),
                                  ),
                                ),
                                Icon(
                                  CupertinoIcons.chevron_right,
                                  size: 14,
                                  color: CupertinoColors.tertiaryLabel
                                      .resolveFrom(context),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          24,
                          16,
                          bottomInset + 12,
                        ),
                        child: Text(
                          'An AUN Creations product',
                          style: TextStyle(
                            fontSize: 12,
                            letterSpacing: 0.4,
                            color: CupertinoColors.secondaryLabel.resolveFrom(
                              context,
                            ),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: bottomInset + 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _recordCrashlyticsNonFatal(BuildContext context) async {
    await CrashlyticsService.recordTestNonFatal();
    if (!context.mounted) {
      return;
    }
    await showCupertinoDialog<void>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('Crashlytics event sent'),
        content: const Text(
          'A test non-fatal event was recorded for Firebase verification.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmForceCrash(BuildContext context) async {
    final shouldCrash =
        await showCupertinoDialog<bool>(
          context: context,
          builder: (dialogContext) => CupertinoAlertDialog(
            title: const Text('Force Crashlytics test crash?'),
            content: const Text(
              'The app will close immediately so Firebase can receive a fatal crash report.',
            ),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Crash app'),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldCrash) {
      return;
    }

    await CrashlyticsService.log(
      'Internal QA requested a Crashlytics test crash.',
    );
    CrashlyticsService.forceCrash();
  }

  void _showTimeoutPicker(BuildContext context, WidgetRef ref, int current) {
    const options = [10, 30, 60, 120, 300];
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Request Timeout'),
        actions: options.map((s) {
          return CupertinoActionSheetAction(
            onPressed: () {
              ref.read(appSettingsProvider.notifier).setTimeoutSeconds(s);
              Navigator.pop(ctx);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${s}s'),
                if (s == current) ...[
                  const SizedBox(width: 8),
                  Icon(
                    CupertinoIcons.checkmark,
                    size: 16,
                    color: CupertinoTheme.of(ctx).primaryColor,
                  ),
                ],
              ],
            ),
          );
        }).toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  Future<void> _confirmClearAll(BuildContext context, WidgetRef ref) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This will permanently delete all collections, environments, and history. This cannot be undone.',
        ),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete Everything'),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(collectionsProvider.notifier).clearAll();
    await ref.read(environmentsProvider.notifier).clearAll();
    await ref.read(historyProvider.notifier).clearAll();
  }

  ThemePreference _currentPreference(Brightness? brightness) {
    if (brightness == null) return ThemePreference.system;
    if (brightness == Brightness.light) return ThemePreference.light;
    return ThemePreference.dark;
  }

  String _adIntervalHelperText({
    required int defaultValue,
    required bool pausedByReward,
  }) {
    if (pausedByReward) {
      return 'Temporarily disabled while rewarded ad pause is active. Auto re-enables when the countdown ends.';
    }
    return 'Show an ad after every X tiles. Example: if you enter 3, an ad appears after every 3 tiles. Default: $defaultValue until you change it.';
  }

  Future<void> _showAdIntervalEditor(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required int current,
    required Future<void> Function(int value) onSave,
  }) async {
    final controller = TextEditingController(text: current.toString());
    await showCupertinoDialog<void>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: Text(title),
        content: Column(
          children: [
            const SizedBox(height: 8),
            const Text(AdConfig.supportMessage),
            const SizedBox(height: 12),
            CupertinoTextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              placeholder: 'Show an ad after every X tiles',
            ),
            const SizedBox(height: 8),
            Text(
              'Example: enter 3 to show an ad after every 3 tiles. Allowed range: ${AdConfig.minInlineAdInterval}-${AdConfig.maxInlineAdInterval}.',
              style: TextStyle(
                fontSize: 12,
                color: CupertinoColors.secondaryLabel.resolveFrom(
                  dialogContext,
                ),
              ),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () async {
              final parsed = int.tryParse(controller.text.trim());
              if (parsed == null ||
                  parsed < AdConfig.minInlineAdInterval ||
                  parsed > AdConfig.maxInlineAdInterval) {
                UserNotification.show(
                  context: dialogContext,
                  title: 'Invalid value',
                  body:
                      'Enter a number from ${AdConfig.minInlineAdInterval} to ${AdConfig.maxInlineAdInterval}.',
                );
                return;
              }
              await onSave(parsed);
              if (!dialogContext.mounted) return;
              Navigator.of(dialogContext).pop();
              if (!context.mounted) return;
              UserNotification.show(
                context: context,
                title: 'Ad settings updated',
                body:
                    'Your ad interval preference will stay active until sign out.',
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleRewardedBrowseAdsToggle(
    BuildContext context,
    WidgetRef ref,
    bool enabled,
  ) async {
    final notifier = ref.read(adSessionProvider.notifier);
    if (!enabled) {
      await notifier.disableBrowseAdRewardMode();
      if (!context.mounted) return;
      UserNotification.show(
        context: context,
        title: 'Browse ads restored',
        body: 'Collections, History, and Environments ads are enabled again.',
      );
      return;
    }

    final result = await notifier.enableBrowseAdRewardMode();
    if (!context.mounted) return;
    switch (result) {
      case RewardBrowseAdsResult.earned:
        UserNotification.show(
          context: context,
          title: 'Browse ads paused',
          body:
              'Collections, History, and Environments ads are turned off for ${AdConfig.rewardedBrowseAdsPauseMinutes} minutes.',
        );
      case RewardBrowseAdsResult.unavailable:
        UserNotification.show(
          context: context,
          title: 'Rewarded ad unavailable',
          body: 'Please try again in a moment.',
        );
      case RewardBrowseAdsResult.dismissed:
        UserNotification.show(
          context: context,
          title: 'Reward not completed',
          body: 'Browse ads stay on unless the rewarded ad is completed.',
        );
    }
  }

  String _formatPauseExpiry(DateTime? value) {
    if (value == null) return 'soon';
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final suffix = value.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }

  String _formatCountdown(DateTime? value, DateTime now) {
    if (value == null) return '0m 0s';
    final remaining = value.difference(now);
    if (remaining <= Duration.zero) return '0m 0s';
    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;
    return '${minutes}m ${seconds}s';
  }

  void _showThemePicker(
    BuildContext context,
    WidgetRef ref,
    Brightness? current,
  ) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Appearance'),
        message: const Text('Choose how the app looks'),
        actions: ThemePreference.values.map((pref) {
          final isCurrent = _currentPreference(current) == pref;
          return CupertinoActionSheetAction(
            onPressed: () {
              ref.read(appThemeNotifierProvider.notifier).setTheme(pref);
              Navigator.pop(ctx);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  pref.label,
                  style: TextStyle(
                    fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                if (isCurrent) ...[
                  const SizedBox(width: 8),
                  Icon(
                    CupertinoIcons.checkmark,
                    size: 16,
                    color: CupertinoTheme.of(ctx).primaryColor,
                  ),
                ],
              ],
            ),
          );
        }).toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 6),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
          color: CupertinoColors.secondaryLabel.resolveFrom(context),
        ),
      ),
    );
  }
}

class _CupertinoSettingsActionRow extends StatelessWidget {
  const _CupertinoSettingsActionRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final String subtitle;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: CupertinoColors.secondaryLabel
                          .resolveFrom(context)
                          .withValues(alpha: enabled ? 1 : 0.7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                color: CupertinoColors.secondaryLabel
                    .resolveFrom(context)
                    .withValues(alpha: enabled ? 1 : 0.7),
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              CupertinoIcons.chevron_right,
              size: 14,
              color: CupertinoColors.tertiaryLabel
                  .resolveFrom(context)
                  .withValues(alpha: enabled ? 1 : 0.7),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
          context,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: children),
    );
  }
}
