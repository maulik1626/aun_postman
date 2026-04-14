import 'dart:io';

import 'package:aun_reqstudio/app/widgets/app_gradient_button.dart';
import 'package:aun_reqstudio/core/notifications/user_notification.dart';
import 'package:aun_reqstudio/core/utils/collection_v2_exporter.dart';
import 'package:aun_reqstudio/domain/models/environment.dart';
import 'package:aun_reqstudio/domain/models/environment_variable.dart';
import 'package:aun_reqstudio/features/environments/providers/environments_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

class EnvironmentDetailScreenMaterial extends ConsumerWidget {
  const EnvironmentDetailScreenMaterial({super.key, required this.uid});

  final String uid;

  static const _uuid = Uuid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final envs = ref.watch(environmentsProvider);
    final env = envs.where((e) => e.uid == uid).firstOrNull;
    final primary = Theme.of(context).colorScheme.primary;
    final secondary = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.55);
    final tertiary = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.38);

    if (env == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) Navigator.of(context).maybePop();
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(env.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, size: 22),
            tooltip: 'Export',
            onPressed: () => _shareEnvironmentExport(context, env),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Variable',
            onPressed: () => _addVariable(context, ref, env),
          ),
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: env.variables.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.list_alt_outlined,
                      size: 52,
                      color: primary.withValues(alpha: 0.3),
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
                      style: TextStyle(color: secondary),
                    ),
                    const SizedBox(height: 24),
                    AppGradientButton.material(
                      onPressed: () => _addVariable(context, ref, env),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, size: 18),
                          SizedBox(width: 6),
                          Text('Add Variable'),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            : ListView.separated(
                itemCount: env.variables.length,
                separatorBuilder: (_, __) => Divider(
                  height: 0.5,
                  indent: 56,
                  color: Theme.of(context).dividerColor,
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
                          Checkbox(
                            value: variable.isEnabled,
                            activeColor: primary,
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            onChanged: (v) {
                              final updated = env.copyWith(
                                variables: env.variables.map((vv) {
                                  if (vv.uid == variable.uid) {
                                    return vv.copyWith(isEnabled: v ?? true);
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
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                        ? tertiary
                                        : secondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.edit_outlined,
                              size: 18,
                              color: primary,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 36,
                            ),
                            onPressed: () =>
                                _editVariable(context, ref, env, variable),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 36,
                            ),
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
                          ),
                        ],
                      ),
                    ),
                  );
                },
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
    final result = await _showVariableSheet(context);
    if (result == null) return;
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
    final result = await _showVariableSheet(
      context,
      initialKey: variable.key,
      initialValue: variable.value,
      initialSecret: variable.isSecret,
    );
    if (result == null) return;
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

  Future<(String, String, bool)?> _showVariableSheet(
    BuildContext context, {
    String initialKey = '',
    String initialValue = '',
    bool initialSecret = false,
  }) async {
    final keyController = TextEditingController(text: initialKey);
    final valueController = TextEditingController(text: initialValue);
    // Same pattern as iOS [EnvironmentDetailScreen._showVariableDialog]: keep
    // mutable sheet state in this scope so [StatefulBuilder] rebuilds don't reset it.
    var isSecret = initialSecret;

    final result = await showModalBottomSheet<(String, String, bool)>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          final primary = Theme.of(ctx).colorScheme.primary;
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: SafeArea(
              top: false,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => FocusScope.of(ctx).unfocus(),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          margin: const EdgeInsets.only(top: 8, bottom: 4),
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Theme.of(ctx).dividerColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                        child: Text(
                          initialKey.isEmpty ? 'New Variable' : 'Edit Variable',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            TextField(
                              controller: keyController,
                              decoration: const InputDecoration(
                                hintText: 'Key',
                                labelText: 'Key',
                              ),
                              style: const TextStyle(
                                fontFamily: 'JetBrainsMono',
                                fontSize: 14,
                              ),
                              autofocus: initialKey.isEmpty,
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: valueController,
                              decoration: const InputDecoration(
                                hintText: 'Value',
                                labelText: 'Value',
                              ),
                              style: const TextStyle(
                                fontFamily: 'JetBrainsMono',
                                fontSize: 14,
                              ),
                              obscureText: isSecret,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Secret toggle row
                      InkWell(
                        onTap: () => setS(() => isSecret = !isSecret),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSecret
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                size: 20,
                                color: primary,
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Secret value',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                              Transform.scale(
                                scale: 0.75,
                                alignment: Alignment.centerRight,
                                child: Switch(
                                  value: isSecret,
                                  activeThumbColor: primary,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  onChanged: (v) => setS(() => isSecret = v),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AppGradientButton.material(
                              fullWidth: true,
                              onPressed: () => Navigator.pop(ctx, (
                                keyController.text.trim(),
                                valueController.text,
                                isSecret,
                              )),
                              child: const Text('Save'),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Cancel'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );

    // Bottom sheet future can complete before the route finishes animating out;
    // disposing immediately can race a final rebuild (see iOS using modal popup timing).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      keyController.dispose();
      valueController.dispose();
    });
    return result;
  }
}
