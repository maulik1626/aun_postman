import 'dart:async';

import 'package:aun_reqstudio/app/theme/app_colors.dart';
import 'package:aun_reqstudio/core/notifications/user_notification.dart';
import 'package:aun_reqstudio/core/utils/app_haptics.dart';
import 'package:aun_reqstudio/core/utils/curl_exporter.dart';
import 'package:aun_reqstudio/core/utils/curl_parser.dart';
import 'package:aun_reqstudio/core/utils/request_name_from_url.dart';
import 'package:aun_reqstudio/core/utils/url_query_sync.dart';
import 'package:aun_reqstudio/core/utils/variable_interpolator.dart';
import 'package:aun_reqstudio/data/local/hive_service.dart';
import 'package:aun_reqstudio/data/local/request_builder_draft_storage.dart';
import 'package:aun_reqstudio/app/widgets/app_gradient_button.dart';
import 'package:aun_reqstudio/domain/enums/http_method.dart';
import 'package:aun_reqstudio/domain/models/collection.dart';
import 'package:aun_reqstudio/domain/models/environment.dart';
import 'package:aun_reqstudio/domain/models/folder.dart';
import 'package:aun_reqstudio/domain/models/history_entry.dart';
import 'package:aun_reqstudio/domain/models/http_request.dart';
import 'package:aun_reqstudio/features/collections/providers/collections_provider.dart';
import 'package:aun_reqstudio/features/environments/providers/active_environment_provider.dart';
import 'package:aun_reqstudio/features/environments/providers/environments_provider.dart';
import 'package:aun_reqstudio/features/history/providers/history_provider.dart';
import 'package:aun_reqstudio/features/request_builder/providers/request_builder_provider.dart';
import 'package:aun_reqstudio/features/request_builder/providers/request_execution_provider.dart';
import 'package:aun_reqstudio/features/request_builder/tabs/auth_tab_material.dart';
import 'package:aun_reqstudio/features/request_builder/tabs/body_tab_material.dart';
import 'package:aun_reqstudio/features/request_builder/tabs/headers_tab_material.dart';
import 'package:aun_reqstudio/features/request_builder/tabs/params_tab_material.dart';
import 'package:aun_reqstudio/features/request_builder/tabs/tests_tab_material.dart';
import 'package:aun_reqstudio/features/response_viewer/response_viewer_sheet_material.dart';
import 'package:aun_reqstudio/features/settings/providers/app_settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

const _requestBuilderTabShortcutKeys = <LogicalKeyboardKey>[
  LogicalKeyboardKey.digit1,
  LogicalKeyboardKey.digit2,
  LogicalKeyboardKey.digit3,
  LogicalKeyboardKey.digit4,
  LogicalKeyboardKey.digit5,
];

class RequestBuilderScreenMaterial extends ConsumerStatefulWidget {
  const RequestBuilderScreenMaterial({
    super.key,
    required this.collectionUid,
    this.requestUid,
    this.folderUid,
    this.openedFromHistory,
  });

  final String collectionUid;
  final String? requestUid;
  final String? folderUid;
  final HistoryEntry? openedFromHistory;

  @override
  ConsumerState<RequestBuilderScreenMaterial> createState() =>
      _RequestBuilderScreenMaterialState();
}

class _RequestBuilderScreenMaterialState
    extends ConsumerState<RequestBuilderScreenMaterial>
    with WidgetsBindingObserver {
  static final _interpolator = VariableInterpolator();
  static const _tabCount = 5;

  int _selectedTab = 0;
  late TextEditingController _urlController;
  late final FocusNode _urlFocusNode;
  late final PageController _tabPageController;
  Timer? _draftSaveTimer;
  bool _cachedRequestAutoSave = true;
  String? _appliedHistoryEntryUid;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _urlController = TextEditingController();
    _urlFocusNode = FocusNode()..addListener(_onUrlFocusChanged);
    _tabPageController = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.openedFromHistory == null) {
        _loadRequest();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final opened = widget.openedFromHistory;
    if (opened == null) return;
    if (_appliedHistoryEntryUid == opened.uid) return;
    _appliedHistoryEntryUid = opened.uid;

    final collections = ref.read(collectionsProvider);
    final req = opened.request;
    final title =
        _resolveRequestTitleForHistoryReplay(req, collections);
    final toLoad = title == req.name ? req : req.copyWith(name: title);
    final snapshot = opened.variableSnapshot;
    final openedUid = opened.uid;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.openedFromHistory?.uid != openedUid) return;
      ref.read(requestBuilderProvider.notifier).loadFromRequest(
            toLoad,
            replayVariableSnapshot: snapshot,
          );
      _urlController.text = ref.read(requestBuilderProvider).url;
    });
  }

  @override
  void didUpdateWidget(RequestBuilderScreenMaterial oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.openedFromHistory == null) {
      _appliedHistoryEntryUid = null;
    } else if (widget.openedFromHistory?.uid !=
        oldWidget.openedFromHistory?.uid) {
      _appliedHistoryEntryUid = null;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      unawaited(_persistDraftImmediate());
    }
  }

  String _draftScope() => RequestBuilderDraftStorage.scopeKey(
        collectionUid: widget.collectionUid,
        requestUid: widget.requestUid,
        folderUid: widget.folderUid,
      );

  Future<void> _persistDraftImmediate() async {
    if (!_cachedRequestAutoSave) return;
    final s = ref.read(requestBuilderProvider);
    if (!s.isDirty) return;
    final box =
        ref.read(hiveBoxProvider(HiveBoxes.requestBuilderDrafts));
    await RequestBuilderDraftStorage.save(box, _draftScope(), s);
  }

  void _scheduleDraftSave(RequestBuilderState s) {
    if (!_cachedRequestAutoSave || !s.isDirty) return;
    _draftSaveTimer?.cancel();
    _draftSaveTimer = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      unawaited(_persistDraftImmediate());
    });
  }

  Future<void> _saveToCollectionAndClearDraft(
      String collectionUid) async {
    await ref
        .read(requestBuilderProvider.notifier)
        .saveToCollection(collectionUid);
    final box =
        ref.read(hiveBoxProvider(HiveBoxes.requestBuilderDrafts));
    await RequestBuilderDraftStorage.clear(box, _draftScope());
  }

  void _onUrlFocusChanged() {
    if (mounted) setState(() {});
  }

  List<String> _urlSuggestionList(
    String prefix,
    List<HistoryEntry> history,
    Collection? collection,
  ) {
    final seen = <String>{};
    final ordered = <String>[];

    void addUnique(String u) {
      u = u.trim();
      if (u.isEmpty || seen.contains(u)) return;
      seen.add(u);
      ordered.add(u);
    }

    final histSorted = [...history]
      ..sort((a, b) => b.executedAt.compareTo(a.executedAt));
    for (final e in histSorted) {
      addUnique(e.request.url);
    }

    if (collection != null) {
      for (final r in collection.requests) {
        addUnique(r.url);
      }
      void walkFolders(List<Folder> folders) {
        for (final f in folders) {
          for (final r in f.requests) {
            addUnique(r.url);
          }
          walkFolders(f.subFolders);
        }
      }

      walkFolders(collection.folders);
    }

    final norm = prefix.trim().toLowerCase();
    return ordered
        .where((u) => norm.isEmpty || u.toLowerCase().contains(norm))
        .take(10)
        .toList();
  }

  void _loadRequest() {
    if (widget.openedFromHistory != null) return;

    if (ref.read(appSettingsProvider).requestAutoSave) {
      final box =
          ref.read(hiveBoxProvider(HiveBoxes.requestBuilderDrafts));
      final restored =
          RequestBuilderDraftStorage.tryLoad(box, _draftScope());
      if (restored != null) {
        final c = UrlQuerySync.canonicalizeUrlAndParams(
          restored.url,
          restored.params,
        );
        // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
        ref.read(requestBuilderProvider.notifier).state = restored.copyWith(
          url: c.url,
          params: c.params,
        );
        _urlController.text = c.url;
        return;
      }
    }

    final uid = widget.requestUid;
    if (uid == null) {
      // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
      ref.read(requestBuilderProvider.notifier).state =
          RequestBuilderState(
        collectionUid: widget.collectionUid,
        folderUid: widget.folderUid,
      );
      return;
    }

    final collections = ref.read(collectionsProvider);
    final col = collections
        .where((c) => c.uid == widget.collectionUid)
        .firstOrNull;
    if (col == null) return;

    final req = col.requests.where((r) => r.uid == uid).firstOrNull ??
        _findInFolders(col.folders, uid);
    if (req == null) return;

    ref.read(requestBuilderProvider.notifier).loadFromRequest(req);
    _urlController.text = ref.read(requestBuilderProvider).url;
  }

  String _resolveRequestTitleForHistoryReplay(
    HttpRequest request,
    List<Collection> collections,
  ) {
    final n = request.name.trim();
    if (n.isNotEmpty && n != 'New Request') return n;

    final colUid = request.collectionUid;
    if (colUid != null && colUid != 'history') {
      final col =
          collections.where((c) => c.uid == colUid).firstOrNull;
      if (col != null) {
        final found =
            col.requests.where((r) => r.uid == request.uid).firstOrNull ??
            _findInFolders(col.folders, request.uid);
        if (found != null) {
          final cn = found.name.trim();
          if (cn.isNotEmpty && cn != 'New Request') return cn;
        }
      }
    }

    final fromUrl = suggestRequestNameFromUrl(request.url).trim();
    if (fromUrl.isNotEmpty && fromUrl != 'New Request') return fromUrl;

    return n.isNotEmpty ? n : 'New Request';
  }

  HttpRequest? _findInFolders(List<Folder> folders, String uid) {
    for (final f in folders) {
      final found =
          f.requests.where((r) => r.uid == uid).firstOrNull;
      if (found != null) return found;
      final nested = _findInFolders(f.subFolders, uid);
      if (nested != null) return nested;
    }
    return null;
  }

  Future<void> _copyAsCurl() async {
    final raw =
        ref.read(requestBuilderProvider.notifier).toRequest();
    if (raw.url.trim().isEmpty) {
      await UserNotification.show(
        context: context,
        title: 'Nothing to copy',
        body: 'Enter a URL before copying as cURL.',
      );
      return;
    }
    final activeEnv = ref.read(activeEnvironmentProvider);
    final settings = ref.read(appSettingsProvider);
    final builderState = ref.read(requestBuilderProvider);
    final vars = buildInterpolationVariableMap(
      builder: builderState,
      env: activeEnv,
    );
    final req =
        _interpolator.interpolateRequestWithVariables(raw, vars);
    final defaultHdrs = _interpolator.interpolateHeadersWithVariables(
        settings.defaultHeaders, vars);
    final curl =
        CurlExporter.toCurl(req, defaultHeaders: defaultHdrs);
    await Clipboard.setData(ClipboardData(text: curl));
    if (!mounted) return;
    AppHaptics.light();
    await UserNotification.show(
      context: context,
      title: 'Copied',
      body: activeEnv != null
          ? 'cURL copied with active environment and dynamic variables applied.'
          : 'cURL copied (dynamic variables applied; no environment selected).',
    );
  }

  @override
  void dispose() {
    _draftSaveTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    final scope = RequestBuilderDraftStorage.scopeKey(
      collectionUid: widget.collectionUid,
      requestUid: widget.requestUid,
      folderUid: widget.folderUid,
    );
    RequestBuilderState? snap;
    if (_cachedRequestAutoSave) {
      try {
        snap = ref.read(requestBuilderProvider);
      } catch (_) {}
    }
    _urlFocusNode.dispose();
    _urlController.dispose();
    _tabPageController.dispose();
    super.dispose();
    if (snap != null && snap.isDirty) {
      try {
        final box =
            Hive.box<String>(HiveBoxes.requestBuilderDrafts);
        unawaited(
            RequestBuilderDraftStorage.save(box, scope, snap));
      } catch (_) {}
    }
  }

  void _onTabSegmentSelected(int? v) {
    final i = (v ?? 0).clamp(0, _tabCount - 1);
    if (i == _selectedTab) return;
    setState(() => _selectedTab = i);
    _tabPageController.animateToPage(
      i,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onTabPageChanged(int i) {
    if (i != _selectedTab) {
      setState(() => _selectedTab = i);
    }
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void _handleSendShortcut() {
    final loading =
        ref.read(requestExecutionProvider).isLoading;
    if (loading) {
      ref.read(requestExecutionProvider.notifier).cancel();
    } else {
      _sendRequest();
    }
  }

  void _handleSaveShortcut() {
    final state = ref.read(requestBuilderProvider);
    if (!state.isDirty || state.collectionUid == null) return;
    AppHaptics.light();
    unawaited(
        _saveToCollectionAndClearDraft(state.collectionUid!));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(requestBuilderProvider);
    final executionState = ref.watch(requestExecutionProvider);
    final isLoading = executionState.isLoading;
    final activeEnv = ref.watch(activeEnvironmentProvider);
    final envs = ref.watch(environmentsProvider);
    final history = ref.watch(historyProvider);
    final collectionForUrls = ref
        .watch(collectionsProvider)
        .where((c) => c.uid == widget.collectionUid)
        .firstOrNull;
    final urlSuggestions = _urlSuggestionList(
      _urlController.text,
      history,
      collectionForUrls,
    );
    final showUrlSuggestions =
        _urlFocusNode.hasFocus && urlSuggestions.isNotEmpty;

    ref.listen(requestExecutionProvider, (prev, next) {
      if (next.hasError && prev?.hasError != true) {
        UserNotification.show(
          context: context,
          title: 'Request failed',
          body: next.error.toString(),
        );
      }
    });
    ref.listen(requestExecutionProvider, (prev, next) {
      if (next.hasValue &&
          next.value != null &&
          !next.isLoading &&
          prev?.isLoading == true) {
        _showResponseSheet();
      }
    });
    ref.listen(requestBuilderProvider, (prev, next) {
      _scheduleDraftSave(next);
    });
    ref.listen(requestBuilderProvider.select((s) => s.url), (prev, next) {
      if (!mounted) return;
      if (!_urlFocusNode.hasFocus && _urlController.text != next) {
        _urlController.text = next;
        setState(() {});
      }
    });

    _cachedRequestAutoSave =
        ref.watch(appSettingsProvider).requestAutoSave;

    final undefinedVars = _findUndefinedVars(
      state.url,
      activeEnv?.variables
              .where((v) => v.isEnabled)
              .map((v) => v.key)
              .toSet() ??
          {},
    );

    final primary = Theme.of(context).colorScheme.primary;
    final secondary = Theme.of(context)
        .colorScheme
        .onSurface
        .withValues(alpha: 0.55);

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter, meta: true):
            _handleSendShortcut,
        const SingleActivator(
                LogicalKeyboardKey.enter, control: true):
            _handleSendShortcut,
        const SingleActivator(LogicalKeyboardKey.keyS, meta: true):
            _handleSaveShortcut,
        const SingleActivator(
                LogicalKeyboardKey.keyS, control: true):
            _handleSaveShortcut,
        for (var i = 0; i < _tabCount; i++)
          SingleActivator(_requestBuilderTabShortcutKeys[i],
              meta: true): () => _onTabSegmentSelected(i),
        for (var i = 0; i < _tabCount; i++)
          SingleActivator(
            _requestBuilderTabShortcutKeys[i],
            control: true,
          ): () => _onTabSegmentSelected(i),
      },
      child: GestureDetector(
        behavior: HitTestBehavior.deferToChild,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          appBar: AppBar(
            title: GestureDetector(
              onTap: _showRenameDialog,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      state.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.edit_outlined,
                    size: 16,
                    color: secondary,
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                tooltip: 'Copy as cURL',
                icon: const Icon(Icons.content_copy_outlined),
                onPressed: _copyAsCurl,
              ),
              if (state.isDirty && state.collectionUid != null)
                TextButton(
                  onPressed: () {
                    AppHaptics.light();
                    unawaited(_saveToCollectionAndClearDraft(
                        state.collectionUid!));
                  },
                  child: const Text('Save'),
                ),
            ],
          ),
          body: CustomScrollView(
          primary: false,
          physics: const NeverScrollableScrollPhysics(),
          slivers: [
            // ── URL bar ─────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: TextFieldTapRegion(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          _MethodSelectorMaterial(
                            method: state.method,
                            onChanged: (m) => ref
                                .read(requestBuilderProvider.notifier)
                                .setMethod(m),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              focusNode: _urlFocusNode,
                              controller: _urlController,
                              style: const TextStyle(
                                fontFamily: 'JetBrainsMono',
                                fontSize: 13,
                              ),
                              decoration: InputDecoration(
                                hintText:
                                    'https://api.example.com/endpoint',
                                hintStyle: const TextStyle(
                                  fontFamily: 'JetBrainsMono',
                                  fontSize: 13,
                                ),
                                suffixIcon: _urlController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear,
                                            size: 16),
                                        onPressed: () {
                                          _urlController.clear();
                                          ref
                                              .read(requestBuilderProvider
                                                  .notifier)
                                              .setUrl('');
                                        },
                                      )
                                    : null,
                              ),
                              onTapOutside: (_) => FocusManager
                                  .instance.primaryFocus
                                  ?.unfocus(),
                              onChanged: (v) {
                                ref
                                    .read(
                                        requestBuilderProvider.notifier)
                                    .setUrl(v);
                                setState(() {});
                              },
                              keyboardType: TextInputType.url,
                              autocorrect: false,
                            ),
                          ),
                        ],
                      ),
                      if (showUrlSuggestions)
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          constraints:
                              const BoxConstraints(maxHeight: 200),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Theme.of(context).dividerColor,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: ListView.separated(
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              itemCount: urlSuggestions.length,
                              separatorBuilder: (_, __) => Divider(
                                height: 0.5,
                                color: Theme.of(context).dividerColor,
                              ),
                              itemBuilder: (context, i) {
                                final s = urlSuggestions[i];
                                return InkWell(
                                  onTap: () {
                                    AppHaptics.light();
                                    _urlController.text = s;
                                    ref
                                        .read(requestBuilderProvider
                                            .notifier)
                                        .setUrl(s);
                                    _urlFocusNode.unfocus();
                                    setState(() {});
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    child: Text(
                                      s,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontFamily: 'JetBrainsMono',
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Environment pill + undefined var warning ──────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 4),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => _showEnvPicker(
                          context, ref, envs, activeEnv?.uid),
                      onLongPress: () =>
                          _showVariablesPreview(context, activeEnv),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: activeEnv != null
                              ? primary.withValues(alpha: 0.1)
                              : Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: activeEnv != null
                                ? primary.withValues(alpha: 0.3)
                                : Theme.of(context).dividerColor,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              activeEnv != null
                                  ? Icons.check_circle
                                  : Icons.circle_outlined,
                              size: 12,
                              color: activeEnv != null
                                  ? primary
                                  : secondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              activeEnv?.name ?? 'No Environment',
                              style: TextStyle(
                                fontSize: 12,
                                color: activeEnv != null
                                    ? primary
                                    : secondary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.keyboard_arrow_down,
                              size: 14,
                              color: activeEnv != null
                                  ? primary
                                  : secondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.list_alt_outlined,
                          size: 20, color: primary),
                      onPressed: () =>
                          _showVariablesPreview(context, activeEnv),
                      padding: const EdgeInsets.only(left: 4),
                      constraints: const BoxConstraints(
                          minWidth: 32, minHeight: 32),
                    ),
                    if (undefinedVars.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.warning_amber,
                                size: 12,
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Undefined: ${undefinedVars.join(', ')}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.orange,
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
            ),

            // ── History variable snapshot banner ─────────────────────────
            if (state.historyVariableSnapshot.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.teal.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Theme.of(context).dividerColor,
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.history, size: 16,
                            color: Colors.teal),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Using ${state.historyVariableSnapshot.length} variable(s) '
                            'from this history entry. Open the request from a collection '
                            'to use the active environment instead.',
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.3,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // ── Pre-request / Paste cURL ─────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 12, 4),
                child: Row(
                  children: [
                    TextButton.icon(
                      onPressed: () =>
                          _showPreRequestSheet(context),
                      icon: Icon(Icons.tune, size: 18, color: primary),
                      label: Text(
                        state.preRequestVariables.isEmpty
                            ? 'Pre-request vars'
                            : 'Pre-request (${state.preRequestVariables.length})',
                        style:
                            TextStyle(fontSize: 13, color: primary),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () =>
                          _pasteCurlIntoBuilder(context),
                      style: TextButton.styleFrom(
                        foregroundColor: primary,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                      ),
                      child: Text(
                        'Paste cURL',
                        style:
                            TextStyle(fontSize: 13, color: primary),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Send button ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                child: GestureDetector(
                  onTap: isLoading
                      ? () => ref
                          .read(requestExecutionProvider.notifier)
                          .cancel()
                      : _sendRequest,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: AppColors.ctaGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isLoading) ...[
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Text(
                          isLoading ? 'Sending…' : 'Send',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Tab bar ──────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 4),
                child: TabBar(
                  onTap: _onTabSegmentSelected,
                  controller: TabController(
                    length: _tabCount,
                    vsync: Navigator.of(context),
                    initialIndex: _selectedTab,
                  ),
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  labelColor: primary,
                  unselectedLabelColor: secondary,
                  indicatorColor: primary,
                  labelStyle: const TextStyle(
                    fontFamily: 'Satoshi',
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  tabs: [
                    const Tab(text: 'Params'),
                    const Tab(text: 'Headers'),
                    const Tab(text: 'Body'),
                    const Tab(text: 'Auth'),
                    Tab(
                      text: state.assertions.isEmpty
                          ? 'Tests'
                          : 'Tests (${state.assertions.length})',
                    ),
                  ],
                ),
              ),
            ),

            // ── Tab content ──────────────────────────────────────────────
            SliverFillRemaining(
              hasScrollBody: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: PrimaryScrollController.none(
                      child: PageView(
                        controller: _tabPageController,
                        onPageChanged: _onTabPageChanged,
                        physics: const PageScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        children: const [
                          ParamsTabMaterial(),
                          HeadersTabMaterial(),
                          BodyTabMaterial(),
                          AuthTabMaterial(),
                          TestsTabMaterial(),
                        ],
                      ),
                    ),
                  ),
                  if (executionState.hasValue &&
                      executionState.value != null)
                    _ResponseSummaryBarMaterial(
                      onTap: _showResponseSheet,
                      statusCode: executionState.value!.statusCode,
                      durationMs:
                          executionState.value!.durationMs,
                      sizeBytes: executionState.value!.sizeBytes,
                    ),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  List<String> _findUndefinedVars(String url, Set<String> defined) {
    final pattern = RegExp(r'\{\{([^}]+)\}\}');
    final matches = pattern.allMatches(url);
    return matches
        .map((m) => m.group(1)!.trim())
        .where((v) => !v.startsWith(r'$') && !defined.contains(v))
        .toSet()
        .toList();
  }

  void _showEnvPicker(
    BuildContext context,
    WidgetRef ref,
    List envs,
    String? activeUid,
  ) {
    final primary = Theme.of(context).colorScheme.primary;
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      useRootNavigator: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(ctx).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 2),
              child: Text(
                'Active Environment',
                style: Theme.of(ctx).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'Variables in {{braces}} are replaced with active environment values',
                style: Theme.of(ctx).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ),
            const Divider(height: 1),
            ListTile(
              title: Row(
                children: [
                  const Text('No Environment'),
                  if (activeUid == null) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.check, size: 16, color: primary),
                  ],
                ],
              ),
              onTap: () async {
                await ref
                    .read(activeEnvironmentProvider.notifier)
                    .clearActive();
                if (ctx.mounted) Navigator.pop(ctx);
              },
            ),
            ...envs.map(
              (e) => ListTile(
                title: Row(
                  children: [
                    Text(e.name),
                    if (e.uid == activeUid) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.check, size: 16, color: primary),
                    ],
                  ],
                ),
                onTap: () {
                  ref
                      .read(environmentsProvider.notifier)
                      .setActive(e.uid);
                  Navigator.pop(ctx);
                },
              ),
            ),
            const Divider(height: 1),
            ListTile(
              title: Text(
                'Cancel',
                style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              onTap: () => Navigator.pop(ctx),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _copyVariablePlaceholder(
    BuildContext sheetContext,
    String placeholder,
  ) async {
    await Clipboard.setData(ClipboardData(text: placeholder));
    AppHaptics.light();
    if (!sheetContext.mounted) return;
    await UserNotification.show(
      context: sheetContext,
      title: 'Copied',
      body: 'Variable placeholder copied to clipboard.',
    );
  }

  void _showVariablesPreview(
      BuildContext context, Environment? env) {
    final primary = Theme.of(context).colorScheme.primary;
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (ctx) => SizedBox(
        height: MediaQuery.sizeOf(ctx).height * 0.58,
        child: Column(
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 8, bottom: 8),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(ctx).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Text(
                    'Variables',
                    style: TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),
            Divider(
                height: 1, color: Theme.of(ctx).dividerColor),
            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  Text(
                    'Environment',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: Theme.of(ctx)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.55),
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (env == null)
                    Text(
                      'No environment selected. Choose one from the pill — '
                      'or use dynamic variables below.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(ctx)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.55),
                      ),
                    )
                  else ...[
                    Text(
                      env.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (env.variables.isEmpty)
                      Text(
                        'This environment has no variables yet.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(ctx)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.55),
                        ),
                      )
                    else
                      ...env.variables.map(
                        (v) => Padding(
                          padding:
                              const EdgeInsets.only(bottom: 10),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '{{${v.key}}}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight:
                                            FontWeight.w600,
                                        fontFamily:
                                            'JetBrainsMono',
                                        color: v.isEnabled
                                            ? primary
                                            : Theme.of(ctx)
                                                .colorScheme
                                                .onSurface
                                                .withValues(
                                                    alpha: 0.55),
                                      ),
                                    ),
                                  ),
                                  if (!v.isEnabled)
                                    Text(
                                      'off',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Theme.of(ctx)
                                            .colorScheme
                                            .onSurface
                                            .withValues(
                                                alpha: 0.55),
                                      ),
                                    ),
                                  if (v.isSecret)
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(
                                              left: 6),
                                      child: Icon(
                                        Icons.lock_outline,
                                        size: 12,
                                        color: Theme.of(ctx)
                                            .colorScheme
                                            .onSurface
                                            .withValues(
                                                alpha: 0.55),
                                      ),
                                    ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.content_copy_outlined,
                                      size: 18,
                                      color: primary
                                          .withValues(alpha: 0.85),
                                    ),
                                    onPressed: () =>
                                        _copyVariablePlaceholder(
                                          ctx,
                                          '{{${v.key}}}',
                                        ),
                                    padding: EdgeInsets.zero,
                                    constraints:
                                        const BoxConstraints(
                                            minWidth: 32,
                                            minHeight: 32),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                v.isSecret ? '••••••••' : v.value,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'JetBrainsMono',
                                  color: Theme.of(ctx)
                                      .colorScheme
                                      .onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                  const SizedBox(height: 20),
                  Text(
                    'Dynamic (built-in)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: Theme.of(ctx)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.55),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Use in URL, headers, or body as {{name}} — resolved at send time.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(ctx)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.55),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...VariableInterpolator.dynamicVariables.map(
                    (name) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '{{$name}}',
                              style: TextStyle(
                                fontSize: 13,
                                fontFamily: 'JetBrainsMono',
                                color: primary,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.content_copy_outlined,
                              size: 18,
                              color:
                                  primary.withValues(alpha: 0.85),
                            ),
                            onPressed: () =>
                                _copyVariablePlaceholder(
                                    ctx, '{{$name}}'),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                                minWidth: 32, minHeight: 32),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendRequest() {
    AppHaptics.light();
    FocusScope.of(context).unfocus();
    ref.read(requestExecutionProvider.notifier).execute();
  }

  Future<void> _showPreRequestSheet(BuildContext context) async {
    final initial =
        ref.read(requestBuilderProvider).preRequestVariables;
    final controller = TextEditingController(
      text:
          initial.entries.map((e) => '${e.key}=${e.value}').join('\n'),
    );
    final result = await showModalBottomSheet<int>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (ctx) => Padding(
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
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 12, 20, 16),
                    child: Text(
                      'Pre-request variables',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: Text(
                      'Applied on Send after the environment (or history snapshot). '
                      'One line per key=value.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(ctx)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.55),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: controller,
                      maxLines: 10,
                      minLines: 5,
                      style: const TextStyle(
                        fontFamily: 'JetBrainsMono',
                        fontSize: 14,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'baseUrl=https://api.example.com',
                        labelText: 'Variables',
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
                          onPressed: () => Navigator.pop(ctx, 1),
                          child: const Text('Apply'),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, 2),
                          child: Text(
                            'Clear',
                            style: TextStyle(
                              color: Theme.of(ctx).colorScheme.error,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, 0),
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
      ),
    );
    if (!mounted) {
      controller.dispose();
      return;
    }
    if (result == 1) {
      final map = <String, String>{};
      for (final line in controller.text.split('\n')) {
        final t = line.trim();
        if (t.isEmpty) continue;
        final i = t.indexOf('=');
        if (i <= 0) continue;
        map[t.substring(0, i).trim()] = t.substring(i + 1).trim();
      }
      ref
          .read(requestBuilderProvider.notifier)
          .setPreRequestVariables(map);
    } else if (result == 2) {
      ref
          .read(requestBuilderProvider.notifier)
          .clearPreRequestVariables();
    }
    controller.dispose();
  }

  Future<void> _pasteCurlIntoBuilder(
      BuildContext context) async {
    final controller = TextEditingController();
    final curlCommand = await showModalBottomSheet<String?>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (ctx) => Padding(
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
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 12, 20, 16),
                    child: Text(
                      'Paste cURL',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: controller,
                      maxLines: 8,
                      minLines: 5,
                      style: const TextStyle(
                        fontFamily: 'JetBrainsMono',
                        fontSize: 14,
                      ),
                      decoration: const InputDecoration(
                        hintText: "curl -X GET 'https://api.example.com'",
                        labelText: 'cURL command',
                      ),
                      autofocus: true,
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
                          onPressed: () =>
                              Navigator.pop(ctx, controller.text.trim()),
                          child: const Text('Apply'),
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
      ),
    );
    controller.dispose();
    if (!mounted) return;
    if (curlCommand == null || curlCommand.isEmpty) return;
    final parsed = CurlParser.parse(curlCommand);
    if (parsed == null) {
      if (!mounted) return;
      await UserNotification.show(
        context: context,
        title: 'cURL',
        body: 'Could not parse this command.',
      );
      return;
    }
    if (!mounted) return;
    ref
        .read(requestBuilderProvider.notifier)
        .applyImportedHttpRequest(parsed);
    _urlController.text = ref.read(requestBuilderProvider).url;
    setState(() {});
    if (!mounted) return;
    await UserNotification.show(
      context: context,
      title: 'Imported',
      body: 'Request fields were replaced from cURL.',
    );
  }

  void _showResponseSheet() {
    final response =
        ref.read(requestExecutionProvider).value;
    if (response == null) return;
    final exec = ref.read(requestExecutionProvider.notifier);
    final harReq = exec.lastSentRequest;
    final harStarted = exec.lastStartedAt;
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(ctx).size.height * 0.85,
        child: ResponseViewerSheetMaterial(
          response: response,
          harRequest: harReq,
          harStartedAt: harStarted,
        ),
      ),
    );
  }

  Future<void> _showRenameDialog() async {
    final controller = TextEditingController(
      text: ref.read(requestBuilderProvider).name,
    );
    final result = await showDialog<String?>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rename Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Your title replaces the auto-generated one. Leave the field '
              'empty and tap Rename to follow the URL again.',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(dialogContext)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text),
            child: const Text('Rename'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result != null) {
      ref
          .read(requestBuilderProvider.notifier)
          .applyRequestNameFromUserInput(result);
    }
  }
}

// ── Method selector ───────────────────────────────────────────────────────────

class _MethodSelectorMaterial extends StatelessWidget {
  const _MethodSelectorMaterial(
      {required this.method, required this.onChanged});

  final HttpMethod method;
  final void Function(HttpMethod) onChanged;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.methodColor(method.value);
    return GestureDetector(
      onTap: () async {
        final selected = await showModalBottomSheet<HttpMethod>(
          context: context,
          useSafeArea: true,
          useRootNavigator: true,
          builder: (ctx) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    margin:
                        const EdgeInsets.only(top: 12, bottom: 8),
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(ctx).dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 2),
                  child: Text(
                    'Select Method',
                    style: Theme.of(ctx).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
                const Divider(height: 1),
                ...HttpMethod.values.map(
                  (m) => ListTile(
                    title: Text(
                      m.value,
                      style: TextStyle(
                        fontFamily: 'JetBrainsMono',
                        fontWeight: FontWeight.w700,
                        color: AppColors.methodColor(m.value),
                      ),
                    ),
                    onTap: () => Navigator.pop(ctx, m),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  title: Text(
                    'Cancel',
                    style:
                        Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                  ),
                  onTap: () => Navigator.pop(ctx),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
        if (selected != null) onChanged(selected);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.4)),
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

// ── Response summary bar ──────────────────────────────────────────────────────

class _ResponseSummaryBarMaterial extends StatelessWidget {
  const _ResponseSummaryBarMaterial({
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
    final primary = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 10),
        color: color.withValues(alpha: 0.08),
        child: Row(
          children: [
            _ChipMaterial(label: '$statusCode', color: color),
            const SizedBox(width: 8),
            _ChipMaterial(
              label: durationMs < 1000
                  ? '${durationMs}ms'
                  : '${(durationMs / 1000).toStringAsFixed(2)}s',
              color: primary,
            ),
            const SizedBox(width: 8),
            _ChipMaterial(
              label: _formatSize(sizeBytes),
              color: Colors.indigo,
            ),
            const Spacer(),
            Text(
              'View Response',
              style: TextStyle(
                fontSize: 12,
                color: primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            Icon(Icons.keyboard_arrow_up, size: 14, color: primary),
          ],
        ),
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class _ChipMaterial extends StatelessWidget {
  const _ChipMaterial({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
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
