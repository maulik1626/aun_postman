import 'package:aun_reqstudio/app/widgets/app_gradient_button.dart';
import 'package:aun_reqstudio/core/constants/ad_config.dart';
import 'package:aun_reqstudio/core/constants/app_constants.dart';
import 'package:aun_reqstudio/core/widgets/banner_ad_tile.dart';
import 'package:aun_reqstudio/features/environments/providers/environments_provider.dart';
import 'package:aun_reqstudio/features/settings/providers/ad_session_provider.dart';
import 'package:aun_reqstudio/features/settings/providers/app_settings_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

NativeListAdTile _nativeAdTileCupertino(BuildContext context) {
  final chrome = CupertinoDynamicColor.resolve(
    CupertinoColors.secondarySystemBackground,
    context,
  );
  final border = CupertinoDynamicColor.resolve(
    CupertinoColors.separator,
    context,
  );
  final label = CupertinoDynamicColor.resolve(
    CupertinoColors.secondaryLabel,
    context,
  );
  final text = CupertinoDynamicColor.resolve(CupertinoColors.label, context);
  final muted = CupertinoDynamicColor.resolve(
    CupertinoColors.secondaryLabel,
    context,
  );
  final tertiary = CupertinoDynamicColor.resolve(
    CupertinoColors.tertiaryLabel,
    context,
  );
  final cta = CupertinoTheme.of(context).primaryColor;

  return NativeListAdTile(
    appearanceKey: CupertinoTheme.brightnessOf(context),
    chromeColor: chrome,
    borderColor: border,
    labelColor: label,
    height: 380,
    templateStyle: NativeTemplateStyle(
      templateType: TemplateType.medium,
      mainBackgroundColor: chrome,
      cornerRadius: 12,
      primaryTextStyle: NativeTemplateTextStyle(
        textColor: text,
        size: 15,
        style: NativeTemplateFontStyle.bold,
      ),
      secondaryTextStyle: NativeTemplateTextStyle(textColor: muted, size: 13),
      tertiaryTextStyle: NativeTemplateTextStyle(textColor: tertiary, size: 11),
      callToActionTextStyle: NativeTemplateTextStyle(
        textColor: CupertinoColors.white,
        backgroundColor: cta,
        size: 13,
        style: NativeTemplateFontStyle.bold,
      ),
    ),
  );
}

class EnvironmentsScreen extends ConsumerWidget {
  const EnvironmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final envs = ref.watch(environmentsProvider);
    final settings = ref.watch(appSettingsProvider);
    final adSession = ref.watch(adSessionProvider);

    final bottomInset = MediaQuery.of(context).padding.bottom;

    return CupertinoPageScaffold(
      child: CustomScrollView(
        physics: const NeverScrollableScrollPhysics(),
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: const Text('Environments'),
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => _showCreateDialog(context, ref),
              minimumSize: const Size(44, 44),
              child: const Icon(CupertinoIcons.add),
            ),
          ),
          if (envs.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                              color: CupertinoTheme.of(
                                context,
                              ).primaryColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              CupertinoIcons.list_bullet_below_rectangle,
                              size: 40,
                              color: CupertinoTheme.of(context).primaryColor,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'No Environments',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create environments to manage variables',
                            style: TextStyle(
                              fontSize: 15,
                              color: CupertinoColors.secondaryLabel.resolveFrom(
                                context,
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                          AppGradientButton(
                            onPressed: () => _showCreateDialog(context, ref),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(CupertinoIcons.add, size: 18),
                                SizedBox(width: 6),
                                Text('New Environment'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: bottomInset),
                  if (AppConstants.enableAds &&
                      !adSession.browseAdsDisabledByReward &&
                      AdConfig.emptyStateBottomBanners.environments)
                    const BottomBannerAdSection(),
                ],
              ),
            )
          else
            SliverFillRemaining(
              hasScrollBody: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: envs.length,
                      separatorBuilder: (_, __) => Container(
                        height: 0.5,
                        color: CupertinoColors.separator.resolveFrom(context),
                      ),
                      itemBuilder: (context, index) {
                        final env = envs[index];
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Slidable(
                              key: ValueKey(env.uid),
                              endActionPane: ActionPane(
                                motion: const DrawerMotion(),
                                extentRatio: 0.32,
                                children: [
                                  SlidableAction(
                                    onPressed: (_) => ref
                                        .read(environmentsProvider.notifier)
                                        .delete(env.uid),
                                    backgroundColor:
                                        CupertinoColors.destructiveRed,
                                    foregroundColor: CupertinoColors.white,
                                    icon: CupertinoIcons.trash,
                                    spacing: 2,
                                    label: 'Delete',
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 2,
                                      vertical: 4,
                                    ),
                                  ),
                                ],
                              ),
                              child: GestureDetector(
                                onTap: () =>
                                    context.push('/environments/${env.uid}'),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        env.isActive
                                            ? CupertinoIcons
                                                  .checkmark_circle_fill
                                            : CupertinoIcons.circle,
                                        color: env.isActive
                                            ? CupertinoTheme.of(
                                                context,
                                              ).primaryColor
                                            : CupertinoColors.secondaryLabel
                                                  .resolveFrom(context),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
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
                                              style: const TextStyle(
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (!env.isActive)
                                        CupertinoButton(
                                          padding: EdgeInsets.zero,
                                          onPressed: () => ref
                                              .read(
                                                environmentsProvider.notifier,
                                              )
                                              .setActive(env.uid),
                                          minimumSize: const Size(30, 30),
                                          child: const Text(
                                            'Activate',
                                            style: TextStyle(fontSize: 14),
                                          ),
                                        ),
                                      const Icon(
                                        CupertinoIcons.chevron_right,
                                        size: 16,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            if (AppConstants.enableAds &&
                                !adSession.browseAdsDisabledByReward &&
                                AdConfig.environments.shouldInsertAfterOrdinal(
                                  index + 1,
                                  overrideEvery:
                                      settings.environmentsAdInterval,
                                ))
                              _nativeAdTileCupertino(context),
                          ],
                        );
                      },
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

  Future<void> _showCreateDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final name = await showCupertinoDialog<String>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('New Environment'),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: CupertinoTextField(
            controller: controller,
            placeholder: 'Environment name',
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: CupertinoColors.tertiarySystemBackground.resolveFrom(
                dialogContext,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            autofocus: true,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
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
