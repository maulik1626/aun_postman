import 'package:aun_reqstudio/app/widgets/app_gradient_button.dart';
import 'package:aun_reqstudio/core/constants/ad_config.dart';
import 'package:aun_reqstudio/core/widgets/banner_ad_tile.dart';
import 'package:aun_reqstudio/features/environments/providers/environments_provider.dart';
import 'package:aun_reqstudio/features/settings/providers/ad_session_provider.dart';
import 'package:aun_reqstudio/features/settings/providers/app_settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

NativeListAdTile _nativeAdTileMaterial(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  final chrome = scheme.surfaceContainerLow;
  final border = scheme.outlineVariant;
  final label = scheme.onSurface.withValues(alpha: 0.62);

  return NativeListAdTile(
    appearanceKey: scheme.brightness,
    chromeColor: chrome,
    borderColor: border,
    labelColor: label,
    height: 340,
    templateStyle: NativeTemplateStyle(
      templateType: TemplateType.medium,
      mainBackgroundColor: chrome,
      cornerRadius: 12,
      primaryTextStyle: NativeTemplateTextStyle(
        textColor: scheme.onSurface,
        size: 15,
        style: NativeTemplateFontStyle.bold,
      ),
      secondaryTextStyle: NativeTemplateTextStyle(
        textColor: scheme.onSurface.withValues(alpha: 0.72),
        size: 13,
      ),
      tertiaryTextStyle: NativeTemplateTextStyle(
        textColor: scheme.onSurface.withValues(alpha: 0.56),
        size: 11,
      ),
      callToActionTextStyle: NativeTemplateTextStyle(
        textColor: scheme.onPrimary,
        backgroundColor: scheme.primary,
        size: 13,
        style: NativeTemplateFontStyle.bold,
      ),
    ),
  );
}

class EnvironmentsScreenMaterial extends ConsumerWidget {
  const EnvironmentsScreenMaterial({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final envs = ref.watch(environmentsProvider);
    final settings = ref.watch(appSettingsProvider);
    final adSession = ref.watch(adSessionProvider);
    final primary = Theme.of(context).colorScheme.primary;
    final secondary = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.55);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Environments'),
        automaticallyImplyLeading: false,
      ),
      floatingActionButton: envs.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showCreateDialog(context, ref),
              icon: const Icon(Icons.add),
              label: const Text(
                'New Environment',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
      body: envs.isEmpty
          ? Column(
              children: [
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            Icons.tune_outlined,
                            size: 40,
                            color: primary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'No Environments',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create environments to manage variables',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 15, color: secondary),
                        ),
                        const SizedBox(height: 28),
                        AppGradientButton.material(
                          onPressed: () => _showCreateDialog(context, ref),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add, size: 18),
                              SizedBox(width: 6),
                              Text('New Environment'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (!adSession.browseAdsDisabledByReward &&
                    AdConfig.emptyStateBottomBanners.environments)
                  const BottomBannerAdSection(),
              ],
            )
          : ListView.separated(
              itemCount: envs.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 0.5, color: Theme.of(context).dividerColor),
              itemBuilder: (context, index) {
                final env = envs[index];
                return Slidable(
                  key: ValueKey(env.uid),
                  endActionPane: ActionPane(
                    motion: const DrawerMotion(),
                    extentRatio: 0.32,
                    children: [
                      SlidableAction(
                        onPressed: (_) => ref
                            .read(environmentsProvider.notifier)
                            .delete(env.uid),
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        icon: Icons.delete_outline,
                        spacing: 2,
                        label: 'Delete',
                        padding: const EdgeInsets.symmetric(
                          horizontal: 2,
                          vertical: 4,
                        ),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () => context.push('/environments/${env.uid}'),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                env.isActive
                                    ? Icons.check_circle
                                    : Icons.circle_outlined,
                                color: env.isActive ? primary : secondary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      env.name,
                                      style: TextStyle(
                                        fontWeight: env.isActive
                                            ? FontWeight.w700
                                            : FontWeight.normal,
                                      ),
                                    ),
                                    Text(
                                      '${env.variables.length} variable${env.variables.length == 1 ? '' : 's'}',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                              if (!env.isActive)
                                TextButton(
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(30, 30),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  onPressed: () => ref
                                      .read(environmentsProvider.notifier)
                                      .setActive(env.uid),
                                  child: const Text(
                                    'Activate',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ),
                              Icon(
                                Icons.chevron_right,
                                size: 16,
                                color: secondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (!adSession.browseAdsDisabledByReward &&
                          AdConfig.environments.shouldInsertAfterOrdinal(
                            index + 1,
                            overrideEvery: settings.environmentsAdInterval,
                          ))
                        _nativeAdTileMaterial(context),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Future<void> _showCreateDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('New Environment'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Environment name'),
          autofocus: true,
          onSubmitted: (v) => Navigator.pop(dialogContext, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name != null && name.isNotEmpty) {
      await ref.read(environmentsProvider.notifier).create(name);
    }
  }
}
