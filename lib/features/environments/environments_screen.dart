import 'package:aun_postman/app/widgets/app_gradient_button.dart';
import 'package:aun_postman/features/environments/providers/environments_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';

class EnvironmentsScreen extends ConsumerWidget {
  const EnvironmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final envs = ref.watch(environmentsProvider);

    return CupertinoPageScaffold(
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: const Text('Environments'),
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              minSize: 44,
              onPressed: () => _showCreateDialog(context, ref),
              child: const Icon(CupertinoIcons.add),
            ),
          ),
          if (envs.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.list_bullet_below_rectangle,
                      size: 56,
                      color: CupertinoTheme.of(context)
                          .primaryColor
                          .withOpacity(0.4),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No Environments',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create environments to manage variables',
                      style: TextStyle(
                        color: CupertinoColors.secondaryLabel
                            .resolveFrom(context),
                      ),
                    ),
                    const SizedBox(height: 24),
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
            )
          else ...[
            SliverList.separated(
              itemCount: envs.length,
              separatorBuilder: (_, __) => Container(
                height: 0.5,
                color: CupertinoColors.separator.resolveFrom(context),
              ),
              itemBuilder: (context, index) {
                final env = envs[index];
                return Slidable(
                  key: ValueKey(env.uid),
                  endActionPane: ActionPane(
                    motion: const DrawerMotion(),
                    children: [
                      SlidableAction(
                        onPressed: (_) => ref
                            .read(environmentsProvider.notifier)
                            .delete(env.uid),
                        backgroundColor: CupertinoColors.destructiveRed,
                        foregroundColor: CupertinoColors.white,
                        icon: CupertinoIcons.trash,
                        label: 'Delete',
                      ),
                    ],
                  ),
                  child: GestureDetector(
                    onTap: () => context.push('/environments/${env.uid}'),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Icon(
                            env.isActive
                                ? CupertinoIcons.checkmark_circle_fill
                                : CupertinoIcons.circle,
                            color: env.isActive
                                ? CupertinoTheme.of(context).primaryColor
                                : CupertinoColors.secondaryLabel
                                    .resolveFrom(context),
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
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              minSize: 30,
                              onPressed: () => ref
                                  .read(environmentsProvider.notifier)
                                  .setActive(env.uid),
                              child: const Text(
                                'Activate',
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                          const Icon(CupertinoIcons.chevron_right, size: 16),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            SliverToBoxAdapter(
              child: SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
            ),
          ],
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
              color: CupertinoColors.tertiarySystemBackground
                  .resolveFrom(dialogContext),
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
