import 'dart:io' show Platform;

import 'package:aun_reqstudio/app/router/app_routes.dart';
import 'package:aun_reqstudio/app/theme/app_theme_provider.dart';
import 'package:aun_reqstudio/core/constants/legal_urls.dart';
import 'package:aun_reqstudio/core/notifications/user_notification.dart';
import 'package:aun_reqstudio/domain/enums/theme_preference.dart';
import 'package:aun_reqstudio/features/auth/providers/auth_provider.dart';
import 'package:aun_reqstudio/features/collections/providers/collections_provider.dart';
import 'package:aun_reqstudio/features/environments/providers/environments_provider.dart';
import 'package:aun_reqstudio/features/history/providers/history_provider.dart';
import 'package:aun_reqstudio/features/settings/providers/app_settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Value + chevron for [ListTile.trailing] — constrains width so rows don't
/// RenderFlex-overflow (yellow/black stripes) on narrow screens.
Widget _settingsTrailingChevron(
  BuildContext context,
  String value,
  Color secondary,
  Color tertiary,
) {
  final maxLabel = (MediaQuery.sizeOf(context).width * 0.32).clamp(72.0, 160.0);
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxLabel),
        child: Text(
          value,
          style: TextStyle(fontSize: 15, color: secondary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.end,
        ),
      ),
      const SizedBox(width: 4),
      Icon(Icons.chevron_right, size: 16, color: tertiary),
    ],
  );
}

Widget _settingsDivider(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  return Divider(
    height: 1,
    thickness: 1,
    indent: 56,
    color: scheme.outlineVariant.withValues(alpha: 0.42),
  );
}

/// Material settings row with a compact switch (native-like density).
class _ScaledSwitchTile extends StatelessWidget {
  const _ScaledSwitchTile({
    required this.value,
    required this.onChanged,
    required this.leading,
    required this.title,
    this.subtitle,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final Widget leading;
  final String title;
  final Widget? subtitle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: leading,
      title: Text(title),
      subtitle: subtitle,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      trailing: Transform.scale(
        scale: 0.65,
        alignment: Alignment.centerRight,
        child: Switch(value: value, onChanged: onChanged),
      ),
      onTap: () => onChanged(!value),
    );
  }
}

class SettingsScreenMaterial extends ConsumerWidget {
  const SettingsScreenMaterial({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = ref.watch(appThemeNotifierProvider);
    final settings = ref.watch(appSettingsProvider);
    final auth = ref.watch(authControllerProvider);
    final primary = Theme.of(context).colorScheme.primary;
    final secondary = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.55);
    final tertiary = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.38);
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final scheme = Theme.of(context).colorScheme;
    final onVar = scheme.onSurfaceVariant;
    final sectionColor = scheme.primary;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: scaffoldBg,
        surfaceTintColor: scheme.surfaceTint,
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          // ── Appearance ────────────────────────────────────────────
          _SectionHeaderMaterial(title: 'Appearance', color: sectionColor),
          _SettingsGroupMaterial(
            children: [
              ListTile(
                leading: Icon(Icons.palette_outlined, color: primary),
                title: const Text('Theme'),
                trailing: _settingsTrailingChevron(
                  context,
                  _currentPreference(brightness).label,
                  secondary,
                  tertiary,
                ),
                onTap: () => _showThemePicker(context, ref, brightness),
              ),
            ],
          ),

          _SectionHeaderMaterial(title: 'Account', color: sectionColor),
          _SettingsGroupMaterial(
            children: [
              ListTile(
                leading: const Icon(
                  Icons.verified_user_outlined,
                  color: Colors.green,
                ),
                title: const Text('Signed In As'),
                subtitle: Text(auth.user?.email ?? 'Unknown account'),
              ),
            ],
          ),

          // ── Requests ─────────────────────────────────────────────
          _SectionHeaderMaterial(title: 'Requests', color: sectionColor),
          _SettingsGroupMaterial(
            children: [
              ListTile(
                leading: Icon(
                  Icons.timer_outlined,
                  color: Colors.orange.shade600,
                ),
                title: const Text('Timeout'),
                trailing: _settingsTrailingChevron(
                  context,
                  '${settings.timeoutSeconds}s',
                  secondary,
                  tertiary,
                ),
                onTap: () =>
                    _showTimeoutPicker(context, ref, settings.timeoutSeconds),
              ),
              _settingsDivider(context),
              _ScaledSwitchTile(
                leading: Icon(Icons.swap_horiz_outlined, color: Colors.blue),
                title: 'Follow Redirects',
                value: settings.followRedirects,
                onChanged: (v) => ref
                    .read(appSettingsProvider.notifier)
                    .setFollowRedirects(v),
              ),
              _settingsDivider(context),
              _ScaledSwitchTile(
                leading: Icon(
                  Icons.content_copy_outlined,
                  color: Colors.purple.shade400,
                ),
                title: 'Auto-save requests',
                subtitle: Text(
                  'Unsaved edits are kept locally if the app closes.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: onVar),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                value: settings.requestAutoSave,
                onChanged: (v) => ref
                    .read(appSettingsProvider.notifier)
                    .setRequestAutoSave(v),
              ),
              _settingsDivider(context),
              _ScaledSwitchTile(
                leading: Icon(
                  Icons.verified_user_outlined,
                  color: Colors.green,
                ),
                title: 'Verify SSL',
                subtitle: Text(
                  'Turn off only for trusted dev servers (not on web).',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: onVar),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                value: settings.verifySsl,
                onChanged: (v) =>
                    ref.read(appSettingsProvider.notifier).setVerifySsl(v),
              ),
              _settingsDivider(context),
              ListTile(
                leading: Icon(Icons.list_alt_outlined, color: Colors.teal),
                title: const Text('Default Headers'),
                trailing: _settingsTrailingChevron(
                  context,
                  '${settings.defaultHeaders.where((h) => h.isEnabled && h.key.trim().isNotEmpty).length}',
                  secondary,
                  tertiary,
                ),
                onTap: () => context.push(AppRoutes.settingsDefaultHeaders),
              ),
              _settingsDivider(context),
              ListTile(
                leading: Icon(Icons.mediation_outlined, color: Colors.indigo),
                title: const Text('HTTP Proxy'),
                trailing: _settingsTrailingChevron(
                  context,
                  settings.httpProxy.isEmpty ? 'Off' : 'On',
                  secondary,
                  tertiary,
                ),
                onTap: () => context.push(AppRoutes.settingsProxy),
              ),
              _settingsDivider(context),
              ListTile(
                leading: Icon(
                  Icons.import_export_outlined,
                  color: Colors.orange.shade700,
                ),
                title: const Text('Import / Export'),
                subtitle: Text(
                  'Collection files, cURL, full backup',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: onVar),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Icon(Icons.chevron_right, size: 16, color: tertiary),
                onTap: () => context.push(AppRoutes.importExport),
              ),
              if (Platform.isIOS) ...[
                _settingsDivider(context),
                _ScaledSwitchTile(
                  leading: const Icon(Icons.cloud_outlined, color: Colors.blue),
                  title: 'iCloud auto-backup',
                  subtitle: Text(
                    'After you leave the app, saves a full backup to iCloud.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: onVar),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  value: settings.icloudAutoBackup,
                  onChanged: (v) => ref
                      .read(appSettingsProvider.notifier)
                      .setIcloudAutoBackup(v),
                ),
              ],
            ],
          ),

          // ── Danger Zone ───────────────────────────────────────────
          _SectionHeaderMaterial(title: 'Danger zone', color: sectionColor),
          _SettingsGroupMaterial(
            children: [
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text(
                  'Clear All Data',
                  style: TextStyle(color: Colors.red),
                ),
                trailing: Icon(Icons.chevron_right, size: 16, color: tertiary),
                onTap: () => _confirmClearAll(context, ref),
              ),
            ],
          ),

          // ── About ─────────────────────────────────────────────────
          _SectionHeaderMaterial(title: 'About', color: sectionColor),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              final info = snapshot.data;
              return _SettingsGroupMaterial(
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.info_outline_rounded,
                      color: Colors.blue,
                    ),
                    title: const Text('Version'),
                    trailing: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.sizeOf(context).width * 0.42,
                      ),
                      child: Text(
                        info != null
                            ? '${info.version} (${info.buildNumber})'
                            : '—',
                        style: TextStyle(
                          fontSize: 14,
                          color: secondary,
                          fontFamily: 'JetBrainsMono',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ),
                  _settingsDivider(context),
                  ListTile(
                    leading: Icon(Icons.apps_outlined, color: Colors.indigo),
                    title: const Text('App Name'),
                    trailing: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.sizeOf(context).width * 0.45,
                      ),
                      child: Text(
                        info?.appName ?? 'AUN - ReqStudio',
                        style: TextStyle(fontSize: 15, color: secondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // ── Legal ─────────────────────────────────────────────────
          _SectionHeaderMaterial(title: 'Legal', color: sectionColor),
          _SettingsGroupMaterial(
            children: [
              ListTile(
                leading: Icon(Icons.help_outline_rounded, color: Colors.blue),
                title: const Text('Support'),
                trailing: Icon(Icons.chevron_right, size: 16, color: tertiary),
                onTap: () =>
                    _launchLegalUrl(context, LegalUrls.support, 'Support'),
              ),
              _settingsDivider(context),
              ListTile(
                leading: Icon(Icons.privacy_tip_outlined, color: Colors.teal),
                title: const Text('Privacy Policy'),
                trailing: Icon(Icons.chevron_right, size: 16, color: tertiary),
                onTap: () => _launchLegalUrl(
                  context,
                  LegalUrls.privacyPolicy,
                  'Privacy Policy',
                ),
              ),
              _settingsDivider(context),
              ListTile(
                leading: Icon(Icons.description_outlined, color: Colors.indigo),
                title: const Text('Terms of Service'),
                trailing: Icon(Icons.chevron_right, size: 16, color: tertiary),
                onTap: () => _launchLegalUrl(
                  context,
                  LegalUrls.termsOfService,
                  'Terms of Service',
                ),
              ),
              _settingsDivider(context),
              ListTile(
                leading: Icon(Icons.shield_outlined, color: Colors.green),
                title: const Text('Open Source Licenses'),
                trailing: Icon(Icons.chevron_right, size: 16, color: tertiary),
                onTap: () => showLicensePage(context: context),
              ),
            ],
          ),

          _SectionHeaderMaterial(title: 'Session', color: sectionColor),
          _SettingsGroupMaterial(
            children: [
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Sign Out'),
                trailing: Icon(Icons.chevron_right, size: 16, color: tertiary),
                onTap: auth.isBusy
                    ? null
                    : () => ref.read(authControllerProvider.notifier).signOut(),
              ),
            ],
          ),

          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              24,
              16,
              20 + MediaQuery.viewPaddingOf(context).bottom,
            ),
            child: Text(
              'An AUN Creations product',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: secondary,
                letterSpacing: 0.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  void _showTimeoutPicker(BuildContext context, WidgetRef ref, int current) {
    const options = [10, 30, 60, 120, 300];
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Request Timeout',
              style: Theme.of(ctx).textTheme.titleMedium,
            ),
          ),
          ...options.map(
            (s) => ListTile(
              title: Text('${s}s'),
              trailing: s == current
                  ? Icon(Icons.check, color: Theme.of(ctx).colorScheme.primary)
                  : null,
              onTap: () {
                ref.read(appSettingsProvider.notifier).setTimeoutSeconds(s);
                Navigator.pop(ctx);
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _confirmClearAll(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This will permanently delete all collections, environments, and history. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete Everything'),
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
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              'Appearance',
              style: Theme.of(ctx).textTheme.titleMedium,
            ),
          ),
          Text(
            'Choose how the app looks',
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(
                ctx,
              ).colorScheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 8),
          ...ThemePreference.values.map((pref) {
            final isCurrent = _currentPreference(current) == pref;
            return ListTile(
              title: Text(
                pref.label,
                style: TextStyle(
                  fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              trailing: isCurrent
                  ? Icon(Icons.check, color: Theme.of(ctx).colorScheme.primary)
                  : null,
              onTap: () {
                ref.read(appThemeNotifierProvider.notifier).setTheme(pref);
                Navigator.pop(ctx);
              },
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _launchLegalUrl(
    BuildContext context,
    String url,
    String label,
  ) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) {
        await Clipboard.setData(ClipboardData(text: url));
        if (!context.mounted) return;
        UserNotification.show(
          context: context,
          title: label,
          body: 'Could not open browser. The URL was copied.',
        );
      }
    } on PlatformException catch (e) {
      await Clipboard.setData(ClipboardData(text: url));
      if (!context.mounted) return;
      final isChannel = e.code == 'channel-error';
      UserNotification.show(
        context: context,
        title: label,
        body: isChannel
            ? 'URL copied. Fully stop the app, then run flutter run once — hot restart does not load new plugins.'
            : 'URL copied. Paste it in a browser.',
      );
    }
  }
}

class _SectionHeaderMaterial extends StatelessWidget {
  const _SectionHeaderMaterial({required this.title, required this.color});
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title,
        style:
            t.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ) ??
            TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

class _SettingsGroupMaterial extends StatelessWidget {
  const _SettingsGroupMaterial({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: scheme.surfaceContainerHighest,
        elevation: 0,
        surfaceTintColor: scheme.surfaceTint,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}
