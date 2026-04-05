import 'dart:io' show Platform;

import 'package:aun_postman/app/router/app_routes.dart';
import 'package:aun_postman/app/widgets/scaled_cupertino_switch.dart';
import 'package:aun_postman/app/theme/app_theme_provider.dart';
import 'package:aun_postman/app/widgets/cupertino_licenses_page.dart';
import 'package:aun_postman/domain/enums/theme_preference.dart';
import 'package:aun_postman/features/collections/providers/collections_provider.dart';
import 'package:aun_postman/features/environments/providers/environments_provider.dart';
import 'package:aun_postman/features/history/providers/history_provider.dart';
import 'package:aun_postman/features/settings/providers/app_settings_provider.dart';
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

    final bottomInset = MediaQuery.of(context).padding.bottom;

    return CupertinoPageScaffold(
      child: CustomScrollView(
        physics: const NeverScrollableScrollPhysics(),
        slivers: [
          const CupertinoSliverNavigationBar(
            largeTitle: Text('Settings'),
          ),
          SliverFillRemaining(
            hasScrollBody: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                _SectionHeader(title: 'Appearance'),
                _SettingsGroup(
                  children: [
                    GestureDetector(
                      onTap: () => _showThemePicker(context, ref, brightness),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 13),
                        child: Row(
                          children: [
                            Icon(
                              CupertinoIcons.paintbrush,
                              color: CupertinoTheme.of(context).primaryColor,
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
                _SectionHeader(title: 'Requests'),
                _SettingsGroup(
                  children: [
                    GestureDetector(
                      onTap: () => _showTimeoutPicker(context, ref, settings.timeoutSeconds),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 13),
                        child: Row(
                          children: [
                            Icon(CupertinoIcons.timer,
                                color: CupertinoColors.systemOrange
                                    .resolveFrom(context),
                                size: 22),
                            const SizedBox(width: 12),
                            const Expanded(
                                child: Text('Timeout',
                                    style: TextStyle(fontSize: 16))),
                            Text(
                              '${settings.timeoutSeconds}s',
                              style: TextStyle(
                                fontSize: 15,
                                color: CupertinoColors.secondaryLabel
                                    .resolveFrom(context),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(CupertinoIcons.chevron_right,
                                size: 14,
                                color: CupertinoColors.tertiaryLabel
                                    .resolveFrom(context)),
                          ],
                        ),
                      ),
                    ),
                    Container(
                        height: 0.5,
                        margin: const EdgeInsets.only(left: 50),
                        color: CupertinoColors.separator.resolveFrom(context)),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      child: Row(
                        children: [
                          Icon(CupertinoIcons.arrow_right_arrow_left,
                              color: CupertinoColors.systemBlue
                                  .resolveFrom(context),
                              size: 22),
                          const SizedBox(width: 12),
                          const Expanded(
                              child: Text('Follow Redirects',
                                  style: TextStyle(fontSize: 16))),
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
                        color: CupertinoColors.separator.resolveFrom(context)),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Auto-save requests',
                                  style: TextStyle(fontSize: 16),
                                ),
                                Text(
                                  'Unsaved edits are kept locally if the app closes.',
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
                        color: CupertinoColors.separator.resolveFrom(context)),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
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
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                        color: CupertinoColors.separator.resolveFrom(context)),
                    GestureDetector(
                      onTap: () =>
                          context.push(AppRoutes.settingsDefaultHeaders),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 13),
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
                        color: CupertinoColors.separator.resolveFrom(context)),
                    GestureDetector(
                      onTap: () => context.push(AppRoutes.settingsProxy),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 13),
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
                        color: CupertinoColors.separator.resolveFrom(context)),
                    GestureDetector(
                      onTap: () => context.push(AppRoutes.importExport),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 13),
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Import / Export',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Postman files, cURL, full backup',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: CupertinoColors.secondaryLabel
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
                        color: CupertinoColors.separator.resolveFrom(context),
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
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                      color: CupertinoColors.secondaryLabel
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
                _SectionHeader(title: 'Danger Zone'),
                _SettingsGroup(
                  children: [
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 13),
                      onPressed: () => _confirmClearAll(context, ref),
                      child: Row(
                        children: [
                          const Icon(CupertinoIcons.trash,
                              color: CupertinoColors.destructiveRed, size: 22),
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
                          Icon(CupertinoIcons.chevron_right,
                              size: 14,
                              color: CupertinoColors.tertiaryLabel
                                  .resolveFrom(context)),
                        ],
                      ),
                    ),
                  ],
                ),
                _SectionHeader(title: 'About'),
                FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, snapshot) {
                    final info = snapshot.data;
                    return _SettingsGroup(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 13),
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
                                info != null
                                    ? '${info.version} (${info.buildNumber})'
                                    : '—',
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
                          color:
                              CupertinoColors.separator.resolveFrom(context),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 13),
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
                                info?.appName ?? 'Postman',
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
                _SectionHeader(title: 'Legal'),
                _SettingsGroup(
                  children: [
                    GestureDetector(
                      onTap: () => showCupertinoLicensePage(context),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 13),
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

  void _showTimeoutPicker(
      BuildContext context, WidgetRef ref, int current) {
    const options = [10, 30, 60, 120, 300];
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Request Timeout'),
        actions: options.map((s) {
          return CupertinoActionSheetAction(
            onPressed: () {
              ref
                  .read(appSettingsProvider.notifier)
                  .setTimeoutSeconds(s);
              Navigator.pop(ctx);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${s}s'),
                if (s == current) ...[
                  const SizedBox(width: 8),
                  Icon(CupertinoIcons.checkmark,
                      size: 16,
                      color: CupertinoTheme.of(ctx).primaryColor),
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
            'This will permanently delete all collections, environments, and history. This cannot be undone.'),
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
                    fontWeight:
                        isCurrent ? FontWeight.w600 : FontWeight.normal,
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

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemGroupedBackground
            .resolveFrom(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: children,
      ),
    );
  }
}
