import 'package:aun_postman/app/theme/app_colors.dart';
import 'package:aun_postman/app/widgets/app_gradient_button.dart';
import 'package:aun_postman/domain/enums/http_method.dart';
import 'package:aun_postman/domain/models/folder.dart';
import 'package:aun_postman/domain/models/http_request.dart';
import 'package:aun_postman/features/collections/providers/collections_provider.dart';
import 'package:aun_postman/features/environments/providers/active_environment_provider.dart';
import 'package:aun_postman/features/environments/providers/environments_provider.dart';
import 'package:aun_postman/features/request_builder/providers/request_builder_provider.dart';
import 'package:aun_postman/features/request_builder/providers/request_execution_provider.dart';
import 'package:aun_postman/features/request_builder/tabs/auth_tab.dart';
import 'package:aun_postman/features/request_builder/tabs/body_tab.dart';
import 'package:aun_postman/features/request_builder/tabs/headers_tab.dart';
import 'package:aun_postman/features/request_builder/tabs/params_tab.dart';
import 'package:aun_postman/features/request_builder/tabs/tests_tab.dart';
import 'package:aun_postman/features/response_viewer/response_viewer_sheet.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RequestBuilderScreen extends ConsumerStatefulWidget {
  const RequestBuilderScreen({
    super.key,
    required this.collectionUid,
    this.requestUid,
    this.folderUid,
  });

  final String collectionUid;
  final String? requestUid;
  /// When creating a new request from a folder context, this pre-sets the
  /// folder so the request is saved into the correct folder.
  final String? folderUid;

  @override
  ConsumerState<RequestBuilderScreen> createState() =>
      _RequestBuilderScreenState();
}

class _RequestBuilderScreenState extends ConsumerState<RequestBuilderScreen> {
  int _selectedTab = 0;
  late TextEditingController _urlController;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadRequest());
  }

  void _loadRequest() {
    final uid = widget.requestUid;

    if (uid == null) {
      // New request: reset to blank with correct collection + folder context.
      // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
      ref.read(requestBuilderProvider.notifier).state = RequestBuilderState(
        collectionUid: widget.collectionUid,
        folderUid: widget.folderUid,
      );
      return;
    }

    // Existing request: search the entire folder tree (any depth).
    final collections = ref.read(collectionsProvider);
    final col = collections.where((c) => c.uid == widget.collectionUid).firstOrNull;
    if (col == null) return;

    final req = col.requests.where((r) => r.uid == uid).firstOrNull
        ?? _findInFolders(col.folders, uid);
    if (req == null) return;

    ref.read(requestBuilderProvider.notifier).loadFromRequest(req);
    _urlController.text = req.url;
  }

  /// Recursively searches [folders] and all their [subFolders] for a request
  /// matching [uid]. Returns null if not found.
  HttpRequest? _findInFolders(List<Folder> folders, String uid) {
    for (final f in folders) {
      final found = f.requests.where((r) => r.uid == uid).firstOrNull;
      if (found != null) return found;
      final nested = _findInFolders(f.subFolders, uid);
      if (nested != null) return nested;
    }
    return null;
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(requestBuilderProvider);
    final executionState = ref.watch(requestExecutionProvider);
    final isLoading = executionState.isLoading;
    final activeEnv = ref.watch(activeEnvironmentProvider);
    final envs = ref.watch(environmentsProvider);

    // Detect undefined {{variables}} in the current URL
    final undefinedVars = _findUndefinedVars(state.url, activeEnv?.variables
        .where((v) => v.isEnabled)
        .map((v) => v.key)
        .toSet() ?? {});

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: GestureDetector(
          onTap: _showRenameDialog,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                state.name,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 4),
              Icon(
                CupertinoIcons.pencil,
                size: 14,
                color: CupertinoColors.secondaryLabel,
              ),
            ],
          ),
        ),
        trailing: state.isDirty && state.collectionUid != null
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                minSize: 44,
                onPressed: () => ref
                    .read(requestBuilderProvider.notifier)
                    .saveToCollection(state.collectionUid!),
                child: Text(
                  'Save',
                  style: TextStyle(
                    color: CupertinoTheme.of(context).primaryColor,
                  ),
                ),
              )
            : null,
      ),
      child: Column(
        children: [
          // URL Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Row(
              children: [
                _MethodSelector(
                  method: state.method,
                  onChanged: (m) =>
                      ref.read(requestBuilderProvider.notifier).setMethod(m),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CupertinoTextField(
                    controller: _urlController,
                    style: const TextStyle(
                      fontFamily: 'JetBrainsMono',
                      fontSize: 13,
                    ),
                    placeholder: 'https://api.example.com/endpoint',
                    placeholderStyle: const TextStyle(
                      fontFamily: 'JetBrainsMono',
                      fontSize: 13,
                    ),
                    decoration: BoxDecoration(
                      color: CupertinoColors.tertiarySystemBackground
                          .resolveFrom(context),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    suffix: _urlController.text.isNotEmpty
                        ? CupertinoButton(
                            padding: EdgeInsets.zero,
                            minSize: 24,
                            onPressed: () {
                              _urlController.clear();
                              ref
                                  .read(requestBuilderProvider.notifier)
                                  .setUrl('');
                            },
                            child: const Icon(
                                CupertinoIcons.clear_circled, size: 16),
                          )
                        : null,
                    onChanged: (v) {
                      ref.read(requestBuilderProvider.notifier).setUrl(v);
                      setState(() {});
                    },
                    keyboardType: TextInputType.url,
                    autocorrect: false,
                  ),
                ),
              ],
            ),
          ),

          // Environment pill + undefined var warning
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                // Environment picker pill
                GestureDetector(
                  onTap: () => _showEnvPicker(context, ref, envs, activeEnv?.uid),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: activeEnv != null
                          ? CupertinoTheme.of(context)
                              .primaryColor
                              .withValues(alpha: 0.1)
                          : CupertinoColors.tertiarySystemFill
                              .resolveFrom(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: activeEnv != null
                            ? CupertinoTheme.of(context)
                                .primaryColor
                                .withValues(alpha: 0.3)
                            : CupertinoColors.separator.resolveFrom(context),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          activeEnv != null
                              ? CupertinoIcons.checkmark_circle_fill
                              : CupertinoIcons.circle,
                          size: 12,
                          color: activeEnv != null
                              ? CupertinoTheme.of(context).primaryColor
                              : CupertinoColors.secondaryLabel
                                  .resolveFrom(context),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          activeEnv?.name ?? 'No Environment',
                          style: TextStyle(
                            fontSize: 12,
                            color: activeEnv != null
                                ? CupertinoTheme.of(context).primaryColor
                                : CupertinoColors.secondaryLabel
                                    .resolveFrom(context),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(CupertinoIcons.chevron_down,
                            size: 10,
                            color: activeEnv != null
                                ? CupertinoTheme.of(context).primaryColor
                                : CupertinoColors.secondaryLabel
                                    .resolveFrom(context)),
                      ],
                    ),
                  ),
                ),

                // Undefined variable warning
                if (undefinedVars.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemOrange
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                              CupertinoIcons.exclamationmark_triangle,
                              size: 12,
                              color: CupertinoColors.systemOrange),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Undefined: ${undefinedVars.join(', ')}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: CupertinoColors.systemOrange,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Send / Cancel button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SizedBox(
              width: double.infinity,
              child: isLoading
                  ? CupertinoButton(
                      onPressed: () => ref
                          .read(requestExecutionProvider.notifier)
                          .cancel(),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(CupertinoIcons.stop_circle, size: 16),
                          SizedBox(width: 6),
                          Text('Cancel'),
                        ],
                      ),
                    )
                  : AppGradientButton(
                      onPressed: _sendRequest,
                      child: const Text('Send'),
                    ),
            ),
          ),

          // Tab bar (segmented control)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: CupertinoSlidingSegmentedControl<int>(
              groupValue: _selectedTab,
              onValueChanged: (v) => setState(() => _selectedTab = v ?? 0),
              children: {
                0: const Text('Params'),
                1: const Text('Headers'),
                2: const Text('Body'),
                3: const Text('Auth'),
                4: Text(state.assertions.isEmpty
                    ? 'Tests'
                    : 'Tests (${state.assertions.length})'),
              },
            ),
          ),

          // Tab content
          Expanded(
            child: IndexedStack(
              index: _selectedTab,
              children: const [
                ParamsTab(),
                HeadersTab(),
                BodyTab(),
                AuthTab(),
                TestsTab(),
              ],
            ),
          ),

          // Response panel trigger
          if (executionState.hasValue && executionState.value != null)
            _ResponseSummaryBar(
              onTap: _showResponseSheet,
              statusCode: executionState.value!.statusCode,
              durationMs: executionState.value!.durationMs,
              sizeBytes: executionState.value!.sizeBytes,
            ),

          if (executionState.hasError)
            _ErrorBar(message: executionState.error.toString()),
        ],
      ),
    );
  }

  List<String> _findUndefinedVars(String url, Set<String> defined) {
    final pattern = RegExp(r'\{\{([^}]+)\}\}');
    final matches = pattern.allMatches(url);
    return matches
        .map((m) => m.group(1)!.trim())
        // Skip dynamic built-ins (start with $)
        .where((v) => !v.startsWith(r'$') && !defined.contains(v))
        .toSet()
        .toList();
  }

  void _showEnvPicker(BuildContext context, WidgetRef ref,
      List envs, String? activeUid) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Active Environment'),
        message: const Text(
            'Variables in {{braces}} are replaced with active environment values'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () async {
              // Deactivate: set no active env by clearing active
              await ref.read(activeEnvironmentProvider.notifier).clearActive();
              Navigator.pop(ctx);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('No Environment'),
                if (activeUid == null) ...[
                  const SizedBox(width: 8),
                  Icon(CupertinoIcons.checkmark,
                      size: 16,
                      color: CupertinoTheme.of(ctx).primaryColor),
                ],
              ],
            ),
          ),
          ...envs.map((e) => CupertinoActionSheetAction(
                onPressed: () {
                  ref
                      .read(environmentsProvider.notifier)
                      .setActive(e.uid);
                  Navigator.pop(ctx);
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(e.name),
                    if (e.uid == activeUid) ...[
                      const SizedBox(width: 8),
                      Icon(CupertinoIcons.checkmark,
                          size: 16,
                          color: CupertinoTheme.of(ctx).primaryColor),
                    ],
                  ],
                ),
              )),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _sendRequest() {
    FocusScope.of(context).unfocus();
    ref.read(requestExecutionProvider.notifier).execute();
    ref.listenManual(requestExecutionProvider, (prev, next) {
      if (next.hasValue && next.value != null && !next.isLoading) {
        _showResponseSheet();
      }
    });
  }

  void _showResponseSheet() {
    final response = ref.read(requestExecutionProvider).value;
    if (response == null) return;
    showCupertinoModalPopup(
      context: context,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 1.0,
        expand: false,
        builder: (ctx, scrollController) => Container(
          decoration: BoxDecoration(
            color: CupertinoColors.systemGroupedBackground.resolveFrom(ctx),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ResponseViewerSheet(
            response: response,
            scrollController: scrollController,
          ),
        ),
      ),
    );
  }

  Future<void> _showRenameDialog() async {
    final controller = TextEditingController(
      text: ref.read(requestBuilderProvider).name,
    );
    final result = await showCupertinoDialog<String>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Rename Request'),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: CupertinoTextField(
            controller: controller,
            autofocus: true,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: CupertinoColors.tertiarySystemBackground
                  .resolveFrom(context),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Rename'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result != null && result.isNotEmpty) {
      ref.read(requestBuilderProvider.notifier).setName(result);
    }
  }
}

class _MethodSelector extends StatelessWidget {
  const _MethodSelector({required this.method, required this.onChanged});
  final HttpMethod method;
  final void Function(HttpMethod) onChanged;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.methodColor(method.value);
    return GestureDetector(
      onTap: () async {
        final selected = await showCupertinoModalPopup<HttpMethod>(
          context: context,
          builder: (ctx) => CupertinoActionSheet(
            title: const Text('Select Method'),
            actions: HttpMethod.values
                .map(
                  (m) => CupertinoActionSheetAction(
                    onPressed: () => Navigator.pop(ctx, m),
                    child: Text(
                      m.value,
                      style: TextStyle(
                        color: AppColors.methodColor(m.value),
                        fontFamily: 'JetBrainsMono',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
                .toList(),
            cancelButton: CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
          ),
        );
        if (selected != null) onChanged(selected);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Text(
          method.value,
          style: TextStyle(
            color: color,
            fontFamily: 'JetBrainsMono',
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ResponseSummaryBar extends StatelessWidget {
  const _ResponseSummaryBar({
    required this.onTap,
    required this.statusCode,
    required this.durationMs,
    required this.sizeBytes,
  });
  final VoidCallback onTap;
  final int statusCode;
  final int durationMs;
  final int sizeBytes;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.statusColor(statusCode);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: color.withOpacity(0.08),
        child: Row(
          children: [
            _Chip(label: '$statusCode', color: color),
            const SizedBox(width: 8),
            _Chip(
              label: durationMs < 1000
                  ? '${durationMs}ms'
                  : '${(durationMs / 1000).toStringAsFixed(2)}s',
              color: CupertinoTheme.of(context).primaryColor,
            ),
            const SizedBox(width: 8),
            _Chip(
              label: _formatSize(sizeBytes),
              color: CupertinoColors.systemIndigo,
            ),
            const Spacer(),
            Text(
              'View Response',
              style: TextStyle(
                fontSize: 12,
                color: CupertinoTheme.of(context).primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Icon(CupertinoIcons.chevron_up, size: 14),
          ],
        ),
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          fontFamily: 'JetBrainsMono',
        ),
      ),
    );
  }
}

class _ErrorBar extends StatelessWidget {
  const _ErrorBar({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: CupertinoColors.destructiveRed.withOpacity(0.12),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.exclamationmark_circle,
            color: CupertinoColors.destructiveRed,
            size: 14,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: CupertinoColors.destructiveRed,
                fontSize: 13,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
