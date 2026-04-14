import 'dart:io';

import 'package:aun_reqstudio/app/theme/app_colors.dart';
import 'package:aun_reqstudio/app/widgets/app_gradient_button.dart';
import 'package:aun_reqstudio/app/widgets/scaled_cupertino_switch.dart';
import 'package:aun_reqstudio/core/notifications/user_notification.dart';
import 'package:aun_reqstudio/core/utils/collection_v2_exporter.dart';
import 'package:aun_reqstudio/domain/models/environment.dart';
import 'package:aun_reqstudio/domain/models/environment_variable.dart';
import 'package:aun_reqstudio/features/environments/providers/environments_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

class EnvironmentDetailScreen extends ConsumerWidget {
  const EnvironmentDetailScreen({super.key, required this.uid});

  final String uid;

  static const _uuid = Uuid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final envs = ref.watch(environmentsProvider);
    final env = envs.where((e) => e.uid == uid).firstOrNull;

    if (env == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) Navigator.of(context).maybePop();
      });
      return const CupertinoPageScaffold(
        child: Center(child: CupertinoActivityIndicator()),
      );
    }

    final bottomInset = MediaQuery.of(context).padding.bottom;

    return CupertinoPageScaffold(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: CustomScrollView(
          physics: const NeverScrollableScrollPhysics(),
          slivers: [
            CupertinoSliverNavigationBar(
              largeTitle: Text(env.name),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minSize: 44,
                    onPressed: () => _shareEnvironmentExport(context, env),
                    child: const Icon(CupertinoIcons.share, size: 22),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minSize: 44,
                    onPressed: () => _addVariable(context, ref, env),
                    child: const Icon(CupertinoIcons.add),
                  ),
                ],
              ),
            ),
            if (env.variables.isEmpty)
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
                            Icon(
                              CupertinoIcons.square_list,
                              size: 52,
                              color: CupertinoTheme.of(
                                context,
                              ).primaryColor.withOpacity(0.3),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'No Variables',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add variables to use in your requests',
                              style: TextStyle(
                                color: CupertinoColors.secondaryLabel
                                    .resolveFrom(context),
                              ),
                            ),
                            const SizedBox(height: 24),
                            AppGradientButton(
                              onPressed: () => _addVariable(context, ref, env),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(CupertinoIcons.add, size: 18),
                                  SizedBox(width: 6),
                                  Text('Add Variable'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: bottomInset + 8),
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
                        itemCount: env.variables.length,
                        separatorBuilder: (_, __) => Container(
                          height: 0.5,
                          margin: const EdgeInsets.only(left: 56),
                          color: CupertinoColors.separator.resolveFrom(context),
                        ),
                        itemBuilder: (context, index) {
                          final variable = env.variables[index];
                          return Opacity(
                            opacity: variable.isEnabled ? 1.0 : 0.5,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              child: Row(
                                children: [
                                  CupertinoCheckbox(
                                    value: variable.isEnabled,
                                    activeColor: CupertinoTheme.of(
                                      context,
                                    ).primaryColor,
                                    onChanged: (v) {
                                      final updated = env.copyWith(
                                        variables: env.variables.map((vv) {
                                          if (vv.uid == variable.uid) {
                                            return vv.copyWith(
                                              isEnabled: v ?? true,
                                            );
                                          }
                                          return vv;
                                        }).toList(),
                                      );
                                      ref
                                          .read(environmentsProvider.notifier)
                                          .update(updated);
                                    },
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          variable.key,
                                          style: const TextStyle(
                                            fontFamily: 'JetBrainsMono',
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          variable.isSecret
                                              ? '••••••••'
                                              : variable.value.isEmpty
                                              ? 'empty'
                                              : variable.value,
                                          style: TextStyle(
                                            fontFamily: 'JetBrainsMono',
                                            fontSize: 12,
                                            color: variable.value.isEmpty
                                                ? CupertinoColors.tertiaryLabel
                                                      .resolveFrom(context)
                                                : CupertinoColors.secondaryLabel
                                                      .resolveFrom(context),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  CupertinoButton(
                                    padding: EdgeInsets.zero,
                                    minSize: 36,
                                    onPressed: () => _editVariable(
                                      context,
                                      ref,
                                      env,
                                      variable,
                                    ),
                                    child: Icon(
                                      CupertinoIcons.pencil,
                                      size: 18,
                                      color: CupertinoTheme.of(
                                        context,
                                      ).primaryColor,
                                    ),
                                  ),
                                  CupertinoButton(
                                    padding: EdgeInsets.zero,
                                    minSize: 36,
                                    onPressed: () {
                                      final updated = env.copyWith(
                                        variables: env.variables
                                            .where((v) => v.uid != variable.uid)
                                            .toList(),
                                      );
                                      ref
                                          .read(environmentsProvider.notifier)
                                          .update(updated);
                                    },
                                    child: const Icon(
                                      CupertinoIcons.trash,
                                      size: 18,
                                      color: CupertinoColors.destructiveRed,
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
      ),
    );
  }

  Future<void> _shareEnvironmentExport(
    BuildContext context,
    Environment env,
  ) async {
    try {
      final json = CollectionV21Exporter.exportEnvironment(env);
      final dir = await getTemporaryDirectory();
      final safe = env.name.replaceAll(RegExp(r'[^\w\-]+'), '_').toLowerCase();
      final file = File(
        '${dir.path}/${safe.isEmpty ? 'environment' : safe}.reqstudio_environment.json',
      );
      await file.writeAsString(json);
      if (!context.mounted) return;
      final size = MediaQuery.sizeOf(context);
      final origin = Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: 1,
        height: 1,
      );
      await Share.shareXFiles(
        [
          XFile(
            file.path,
            mimeType: 'application/json',
            name: '${env.name}.reqstudio_environment.json',
          ),
        ],
        subject: env.name,
        sharePositionOrigin: origin,
      );
    } catch (e) {
      if (context.mounted) {
        await UserNotification.show(
          context: context,
          title: 'Export failed',
          body: e.toString(),
        );
      }
    }
  }

  Future<void> _addVariable(
    BuildContext context,
    WidgetRef ref,
    dynamic env,
  ) async {
    final result = await _showVariableDialog(context);
    if (result == null) return;
    // Re-read fresh env after async gap — dialog may have taken time
    final freshEnv = ref
        .read(environmentsProvider)
        .where((e) => e.uid == uid)
        .firstOrNull;
    if (freshEnv == null) return;
    final newVar = EnvironmentVariable(
      uid: _uuid.v4(),
      key: result.$1,
      value: result.$2,
      isSecret: result.$3,
    );
    final updated = freshEnv.copyWith(
      variables: [...freshEnv.variables, newVar],
    );
    ref.read(environmentsProvider.notifier).update(updated);
  }

  Future<void> _editVariable(
    BuildContext context,
    WidgetRef ref,
    dynamic env,
    EnvironmentVariable variable,
  ) async {
    final result = await _showVariableDialog(
      context,
      initialKey: variable.key,
      initialValue: variable.value,
      initialSecret: variable.isSecret,
    );
    if (result == null) return;
    // Re-read fresh env after async gap
    final freshEnv = ref
        .read(environmentsProvider)
        .where((e) => e.uid == uid)
        .firstOrNull;
    if (freshEnv == null) return;
    final updated = freshEnv.copyWith(
      variables: freshEnv.variables.map((v) {
        if (v.uid == variable.uid) {
          return v.copyWith(
            key: result.$1,
            value: result.$2,
            isSecret: result.$3,
          );
        }
        return v;
      }).toList(),
    );
    ref.read(environmentsProvider.notifier).update(updated);
  }

  Future<(String, String, bool)?> _showVariableDialog(
    BuildContext context, {
    String initialKey = '',
    String initialValue = '',
    bool initialSecret = false,
  }) async {
    final keyController = TextEditingController(text: initialKey);
    final valueController = TextEditingController(text: initialValue);
    bool isSecret = initialSecret;

    final result = await showCupertinoModalPopup<(String, String, bool)>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Container(
          // Merging keyboard inset into the Container's own padding keeps
          // the entire sheet opaque — a transparent Padding would let taps
          // fall through to the barrier and silently dismiss the modal.
          decoration: BoxDecoration(
            color: CupertinoColors.systemGroupedBackground.resolveFrom(ctx),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            top: 20,
            bottom:
                MediaQuery.of(ctx).viewInsets.bottom +
                MediaQuery.of(ctx).padding.bottom +
                16,
          ),
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusScope.of(ctx).unfocus(),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: CupertinoColors.separator.resolveFrom(ctx),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      initialKey.isEmpty ? 'New Variable' : 'Edit Variable',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Fields
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        CupertinoTextField(
                          controller: keyController,
                          placeholder: 'Key',
                          style: const TextStyle(
                            fontFamily: 'JetBrainsMono',
                            fontSize: 14,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 13,
                          ),
                          decoration: BoxDecoration(
                            color: CupertinoColors.tertiarySystemBackground
                                .resolveFrom(ctx),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                          ),
                          autofocus: true,
                        ),
                        Container(
                          height: 0.5,
                          color: CupertinoColors.separator.resolveFrom(ctx),
                        ),
                        CupertinoTextField(
                          controller: valueController,
                          placeholder: 'Value',
                          style: const TextStyle(
                            fontFamily: 'JetBrainsMono',
                            fontSize: 14,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 13,
                          ),
                          decoration: BoxDecoration(
                            color: CupertinoColors.tertiarySystemBackground
                                .resolveFrom(ctx),
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(12),
                            ),
                          ),
                          obscureText: isSecret,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Secret toggle
                  GestureDetector(
                    onTap: () => setState(() => isSecret = !isSecret),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: CupertinoColors.secondarySystemGroupedBackground
                            .resolveFrom(ctx),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSecret
                                ? CupertinoIcons.eye_slash
                                : CupertinoIcons.eye,
                            size: 20,
                            color: CupertinoTheme.of(ctx).primaryColor,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Secret value',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                          ScaledCupertinoSwitch(
                            value: isSecret,
                            activeTrackColor: CupertinoTheme.of(
                              ctx,
                            ).primaryColor,
                            onChanged: (v) => setState(() => isSecret = v),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Full-width Save — built without CupertinoButton to
                        // avoid its internal Align shrink-wrapping the gradient.
                        GestureDetector(
                          onTap: () => Navigator.pop(ctx, (
                            keyController.text.trim(),
                            valueController.text,
                            isSecret,
                          )),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              gradient: AppColors.ctaGradient,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              'Save',
                              style: TextStyle(
                                color: CupertinoColors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: CupertinoColors.secondaryLabel.resolveFrom(
                                ctx,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    keyController.dispose();
    valueController.dispose();
    return result;
  }
}
