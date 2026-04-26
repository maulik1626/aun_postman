import 'dart:async';

import 'package:aun_reqstudio/app/platform.dart';
import 'package:aun_reqstudio/app/theme/app_colors.dart';
import 'package:aun_reqstudio/core/errors/app_exception.dart';
import 'package:aun_reqstudio/core/notifications/user_notification.dart';
import 'package:aun_reqstudio/core/services/ad_service.dart';
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
import 'package:aun_reqstudio/domain/models/environment_variable.dart';
import 'package:aun_reqstudio/domain/models/http_request.dart';
import 'package:aun_reqstudio/domain/models/http_response.dart';
import 'package:aun_reqstudio/domain/models/key_value_pair.dart';
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
import 'package:aun_reqstudio/features/request_builder/widgets/key_value_bulk_parser.dart';
import 'package:aun_reqstudio/features/request_builder/widgets/key_value_editor_web.dart';
import 'package:aun_reqstudio/app/web/web_chrome_layout.dart';
import 'package:aun_reqstudio/features/request_builder/web/url_template_range.dart';
import 'package:aun_reqstudio/features/request_builder/web/web_request_method_url_bar.dart';
import 'package:aun_reqstudio/features/request_builder/web/web_url_variable_edit_dialog.dart';
import 'package:aun_reqstudio/features/request_builder/widgets/pre_request_variables_outcome.dart';
import 'package:aun_reqstudio/features/request_builder/widgets/pre_request_variables_sheet_material.dart';
import 'package:aun_reqstudio/features/response_viewer/response_viewer_sheet_material.dart';
import 'package:aun_reqstudio/features/settings/providers/app_settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

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
    this.draftScopeId,
    this.openedFromHistory,
  });

  final String collectionUid;
  final String? requestUid;
  final String? folderUid;
  final String? draftScopeId;
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
  static const _webMinRequestPaneHeight = 240.0;
  static const _webMinResponsePaneHeight = 200.0;
  static const _webSplitterHeight = 8.0;

  int _selectedTab = 0;
  late TextEditingController _urlController;
  late final FocusNode _urlFocusNode;
  late final PageController _tabPageController;
  Timer? _autoPersistTimer;
  Future<void> _autoPersistSerial = Future<void>.value();
  bool _cachedRequestAutoSave = true;
  String? _appliedHistoryEntryUid;
  String _urlOverlayRebuildKey = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _urlController = TextEditingController()
      ..addListener(_onUrlControllerDriveWebOverlay);
    _urlFocusNode = FocusNode()..addListener(_onUrlFocusChanged);
    _tabPageController = PageController();
    // Defer past the current build: Riverpod forbids notifier updates from
    // initState while the tree is still mounting (scoped tabs mount under the
    // same frame as the parent workspace).
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
    final title = _resolveRequestTitleForHistoryReplay(req, collections);
    final toLoad = title == req.name ? req : req.copyWith(name: title);
    final snapshot = opened.variableSnapshot;
    final openedUid = opened.uid;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.openedFromHistory?.uid != openedUid) return;
      ref
          .read(requestBuilderProvider.notifier)
          .loadFromRequest(toLoad, replayVariableSnapshot: snapshot);
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
      unawaited(_flushAutoPersistImmediate());
    }
  }

  @override
  void deactivate() {
    if (_cachedRequestAutoSave) {
      unawaited(_flushAutoPersistImmediate());
    }
    super.deactivate();
  }

  String _draftScope() {
    final baseScope = RequestBuilderDraftStorage.scopeKey(
      collectionUid: widget.collectionUid,
      requestUid: widget.requestUid,
      folderUid: widget.folderUid,
    );
    final draftScopeId = widget.draftScopeId;
    return draftScopeId == null ? baseScope : '$baseScope|$draftScopeId';
  }

  Future<void> _persistDraftImmediate() async {
    if (!_cachedRequestAutoSave) return;
    final s = ref.read(requestBuilderProvider);
    if (!s.isDirty) return;
    final box = ref.read(hiveBoxProvider(HiveBoxes.requestBuilderDrafts));
    await RequestBuilderDraftStorage.save(box, _draftScope(), s);
  }

  static const _autoPersistDebounce = Duration(milliseconds: 550);

  void _scheduleAutoPersist(RequestBuilderState s) {
    if (!_cachedRequestAutoSave || !s.isDirty) return;
    _autoPersistTimer?.cancel();
    _autoPersistTimer = Timer(_autoPersistDebounce, () {
      if (!mounted) return;
      unawaited(_runDebouncedAutoPersist());
    });
  }

  Future<void> _flushAutoPersistImmediate() async {
    _autoPersistTimer?.cancel();
    if (!_cachedRequestAutoSave || !mounted) return;
    final s = ref.read(requestBuilderProvider);
    if (!s.isDirty) return;
    await _executeAutoPersist();
  }

  Future<void> _runDebouncedAutoPersist() async {
    if (!_cachedRequestAutoSave || !mounted) return;
    final s = ref.read(requestBuilderProvider);
    if (!s.isDirty) return;
    await _executeAutoPersist();
  }

  Future<void> _executeAutoPersist() async {
    final previous = _autoPersistSerial;
    late final Future<void> pending;
    pending = previous.then((_) async {
      if (!_cachedRequestAutoSave || !mounted) return;
      final s = ref.read(requestBuilderProvider);
      if (!s.isDirty) return;

      if (widget.openedFromHistory != null) {
        await _persistDraftImmediate();
        return;
      }

      final collectionUid = s.collectionUid ?? widget.collectionUid;
      if (collectionUid.isNotEmpty && s.url.trim().isNotEmpty) {
        try {
          await _saveToCollectionAndClearDraft(collectionUid);
          return;
        } catch (e, st) {
          assert(() {
            debugPrint('RequestBuilder auto-save failed: $e\n$st');
            return true;
          }());
          await _persistDraftImmediate();
          if (!mounted) return;
          if (e is StorageException) {
            await UserNotification.show(
              context: context,
              title: 'Could not auto-save',
              body:
                  'Your changes are kept as a draft. Try saving again in a moment.',
            );
          }
        }
        return;
      }

      await _persistDraftImmediate();
    });
    _autoPersistSerial = pending.catchError((Object _, StackTrace __) {});
    await pending;
  }

  Future<void> _saveToCollectionAndClearDraft(String collectionUid) async {
    await ref
        .read(requestBuilderProvider.notifier)
        .saveToCollection(collectionUid);
    final box = ref.read(hiveBoxProvider(HiveBoxes.requestBuilderDrafts));
    await RequestBuilderDraftStorage.clear(box, _draftScope());
  }

  void _onUrlFocusChanged() {
    if (mounted) setState(() {});
  }

  void _onUrlControllerDriveWebOverlay() {
    if (!AppPlatform.usesWebCustomUi || !mounted) return;
    final sel = _urlController.selection;
    final snapshot =
        '${_urlController.text}\x1E${sel.baseOffset}\x1E${sel.extentOffset}';
    if (snapshot == _urlOverlayRebuildKey) return;
    _urlOverlayRebuildKey = snapshot;
    setState(() {});
  }

  int _urlCaretOffset() {
    final o = _urlController.selection.baseOffset;
    if (o < 0) return _urlController.text.length;
    return o.clamp(0, _urlController.text.length);
  }

  Future<void> _onWebUrlVariableTemplateDoubleTap(
    UrlVariableTemplateSpan span,
  ) async {
    if (!AppPlatform.usesWebCustomUi || !mounted) return;
    final env = ref.read(activeEnvironmentProvider);
    await showWebUrlVariableEditDialog(
      context: context,
      span: span,
      currentUrl: _urlController.text,
      activeEnv: env,
      onApply: (newUrl) {
        _urlController.value = TextEditingValue(
          text: newUrl,
          selection: TextSelection.collapsed(offset: newUrl.length),
        );
        ref.read(requestBuilderProvider.notifier).setUrl(newUrl);
        setState(() {});
      },
      persistActiveEnvVariable: env == null
          ? null
          : (key, value, isSecret) async {
              final active = ref.read(activeEnvironmentProvider);
              if (active == null || !mounted) return;
              EnvironmentVariable? match;
              for (final v in active.variables) {
                if (v.key == key) {
                  match = v;
                  break;
                }
              }
              final updated = match == null
                  ? active.copyWith(
                      variables: [
                        ...active.variables,
                        EnvironmentVariable(
                          uid: const Uuid().v4(),
                          key: key,
                          value: value,
                          isSecret: isSecret,
                        ),
                      ],
                    )
                  : active.copyWith(
                      variables: active.variables
                          .map(
                            (v) => v.uid == match!.uid
                                ? v.copyWith(value: value, isSecret: isSecret)
                                : v,
                          )
                          .toList(),
                    );
              await ref.read(environmentsProvider.notifier).update(updated);
            },
    );
  }

  void _onWebUrlOverlayPick(_WebUrlSuggestionPick pick) {
    if (pick.url != null) {
      _urlController.text = pick.url!;
      ref.read(requestBuilderProvider.notifier).setUrl(pick.url!);
      _urlFocusNode.unfocus();
      setState(() {});
      return;
    }
    final key = pick.envKey;
    if (key == null) return;
    final caret = _urlCaretOffset();
    final applied = applyEnvVariableSuggestion(
      _urlController.text,
      caret,
      key,
    );
    _urlController.value = TextEditingValue(
      text: applied.newText,
      selection: TextSelection.collapsed(offset: applied.newCaret),
    );
    ref.read(requestBuilderProvider.notifier).setUrl(applied.newText);
    _urlFocusNode.unfocus();
    setState(() {});
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
      final box = ref.read(hiveBoxProvider(HiveBoxes.requestBuilderDrafts));
      final restored = RequestBuilderDraftStorage.tryLoad(box, _draftScope());
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
      ref.read(requestBuilderProvider.notifier).state = RequestBuilderState(
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

    final req =
        col.requests.where((r) => r.uid == uid).firstOrNull ??
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
      final col = collections.where((c) => c.uid == colUid).firstOrNull;
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
      final found = f.requests.where((r) => r.uid == uid).firstOrNull;
      if (found != null) return found;
      final nested = _findInFolders(f.subFolders, uid);
      if (nested != null) return nested;
    }
    return null;
  }

  Future<void> _copyAsCurl() async {
    final raw = ref.read(requestBuilderProvider.notifier).toRequest();
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
    final req = _interpolator.interpolateRequestWithVariables(raw, vars);
    final defaultHdrs = _interpolator.interpolateHeadersWithVariables(
      settings.defaultHeaders,
      vars,
    );
    final curl = CurlExporter.toCurl(req, defaultHeaders: defaultHdrs);
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
    _autoPersistTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    final scope = _draftScope();
    RequestBuilderState? snap;
    if (_cachedRequestAutoSave) {
      try {
        snap = ref.read(requestBuilderProvider);
      } catch (_) {}
    }
    _urlFocusNode.dispose();
    _urlController.removeListener(_onUrlControllerDriveWebOverlay);
    _urlController.dispose();
    _tabPageController.dispose();
    super.dispose();
    if (snap != null && snap.isDirty) {
      try {
        final box = Hive.box<String>(HiveBoxes.requestBuilderDrafts);
        unawaited(RequestBuilderDraftStorage.save(box, scope, snap));
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

  void _onWebTabSelected(int i) {
    final next = i.clamp(0, _tabCount - 1);
    if (next != _selectedTab) {
      setState(() => _selectedTab = next);
    }
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void _handleSendShortcut() {
    final loading = ref.read(requestExecutionProvider).isLoading;
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
    unawaited(_saveToCollectionAndClearDraft(state.collectionUid!));
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
    final envKeysActive = activeEnv?.variables
            .where((v) => v.isEnabled)
            .map((v) => v.key)
            .toSet() ??
        const <String>{};
    final caret = _urlCaretOffset();
    final envVarSuggestions = matchingEnvKeysForUrlCaret(
      _urlController.text,
      caret,
      envKeysActive,
    );
    final inOpenVarTemplate =
        AppPlatform.usesWebCustomUi &&
        openBraceIndexForUnclosedTemplate(_urlController.text, caret) != null;
    final webUrlOverlayPicks = <_WebUrlSuggestionPick>[
      if (AppPlatform.usesWebCustomUi && inOpenVarTemplate)
        for (final k in envVarSuggestions)
          _WebUrlSuggestionPick.env(k, activeEnv)
      else if (AppPlatform.usesWebCustomUi)
        for (final u in urlSuggestions) _WebUrlSuggestionPick.url(u),
    ];
    final showWebUrlOverlay =
        AppPlatform.usesWebCustomUi &&
        _urlFocusNode.hasFocus &&
        webUrlOverlayPicks.isNotEmpty;
    final showUrlSuggestions =
        !AppPlatform.usesWebCustomUi &&
        _urlFocusNode.hasFocus &&
        urlSuggestions.isNotEmpty;

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
        if (AppPlatform.usesWebCustomUi) {
          setState(() {});
        } else {
          unawaited(_showResponseSheet());
        }
      }
    });
    ref.listen(requestBuilderProvider, (prev, next) {
      _scheduleAutoPersist(next);
    });
    ref.listen(requestBuilderProvider.select((s) => s.url), (prev, next) {
      if (!mounted) return;
      if (!_urlFocusNode.hasFocus && _urlController.text != next) {
        _urlController.text = next;
        setState(() {});
      }
    });

    _cachedRequestAutoSave = ref.watch(appSettingsProvider).requestAutoSave;

    final undefinedVars = _findUndefinedVars(
      state.url,
      activeEnv?.variables
              .where((v) => v.isEnabled)
              .map((v) => v.key)
              .toSet() ??
          {},
    );

    final primary = Theme.of(context).colorScheme.primary;
    final secondary = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.55);

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter, meta: true):
            _handleSendShortcut,
        const SingleActivator(LogicalKeyboardKey.enter, control: true):
            _handleSendShortcut,
        const SingleActivator(LogicalKeyboardKey.keyS, meta: true):
            _handleSaveShortcut,
        const SingleActivator(LogicalKeyboardKey.keyS, control: true):
            _handleSaveShortcut,
        for (var i = 0; i < _tabCount; i++)
          SingleActivator(_requestBuilderTabShortcutKeys[i], meta: true): () =>
              _onTabSegmentSelected(i),
        for (var i = 0; i < _tabCount; i++)
          SingleActivator(
            _requestBuilderTabShortcutKeys[i],
            control: true,
          ): () =>
              _onTabSegmentSelected(i),
      },
      child: GestureDetector(
        behavior: HitTestBehavior.deferToChild,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          appBar: AppPlatform.usesWebCustomUi
              ? null
              : AppBar(
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
                        Icon(Icons.edit_outlined, size: 16, color: secondary),
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
                          unawaited(
                            _saveToCollectionAndClearDraft(
                              state.collectionUid!,
                            ),
                          );
                        },
                        child: const Text('Save'),
                      ),
                  ],
                ),
          body: AppPlatform.usesWebCustomUi
              ? _buildWebRequestResponseBody(
                  context: context,
                  state: state,
                  executionState: executionState,
                  isLoading: isLoading,
                  activeEnv: activeEnv,
                  envs: envs,
                  undefinedVars: undefinedVars,
                  showWebUrlOverlay: showWebUrlOverlay,
                  webUrlOverlayPicks: webUrlOverlayPicks,
                  definedEnvKeys: envKeysActive,
                  primary: primary,
                  secondary: secondary,
                )
              : CustomScrollView(
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
                                    useWebDialog: AppPlatform.usesWebCustomUi,
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
                                        suffixIcon:
                                            _urlController.text.isNotEmpty
                                            ? IconButton(
                                                icon: const Icon(
                                                  Icons.clear,
                                                  size: 16,
                                                ),
                                                onPressed: () {
                                                  _urlController.clear();
                                                  ref
                                                      .read(
                                                        requestBuilderProvider
                                                            .notifier,
                                                      )
                                                      .setUrl('');
                                                },
                                              )
                                            : null,
                                      ),
                                      onTapOutside: (_) => FocusManager
                                          .instance
                                          .primaryFocus
                                          ?.unfocus(),
                                      onChanged: (v) {
                                        ref
                                            .read(
                                              requestBuilderProvider.notifier,
                                            )
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
                                  constraints: const BoxConstraints(
                                    maxHeight: 200,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerHighest,
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
                                                .read(
                                                  requestBuilderProvider
                                                      .notifier,
                                                )
                                                .setUrl(s);
                                            _urlFocusNode.unfocus();
                                            setState(() {});
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
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
                          horizontal: 12,
                          vertical: 4,
                        ),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => _showEnvPicker(
                                context,
                                ref,
                                envs,
                                activeEnv?.uid,
                              ),
                              onLongPress: () =>
                                  _showVariablesPreview(context, activeEnv),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: activeEnv != null
                                      ? primary.withValues(alpha: 0.1)
                                      : Theme.of(
                                          context,
                                        ).colorScheme.surfaceContainerHighest,
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
                              icon: Icon(
                                Icons.list_alt_outlined,
                                size: 20,
                                color: primary,
                              ),
                              onPressed: () =>
                                  _showVariablesPreview(context, activeEnv),
                              padding: const EdgeInsets.only(left: 4),
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                            ),
                            if (undefinedVars.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withValues(
                                      alpha: 0.12,
                                    ),
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
                                const Icon(
                                  Icons.history,
                                  size: 16,
                                  color: Colors.teal,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Using ${state.historyVariableSnapshot.length} variable(s) '
                                    'from this history entry. Open the request from a collection '
                                    'to use the active environment instead.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      height: 1.3,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
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
                              onPressed: _showPreRequestSheet,
                              icon: Icon(Icons.tune, size: 18, color: primary),
                              label: Text(
                                state.preRequestVariables.isEmpty
                                    ? 'Pre-request vars'
                                    : 'Pre-request (${state.preRequestVariables.length})',
                                style: TextStyle(fontSize: 13, color: primary),
                              ),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                              ),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: _pasteCurlIntoBuilder,
                              style: TextButton.styleFrom(
                                foregroundColor: primary,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                              ),
                              child: Text(
                                'Paste cURL',
                                style: TextStyle(fontSize: 13, color: primary),
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
                          horizontal: 12,
                          vertical: 8,
                        ),
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
                          horizontal: 12,
                          vertical: 4,
                        ),
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
                          if (!AppPlatform.usesWebCustomUi &&
                              executionState.hasValue &&
                              executionState.value != null)
                            _ResponseSummaryBarMaterial(
                              onTap: _showResponseSheet,
                              statusCode: executionState.value!.statusCode,
                              durationMs: executionState.value!.durationMs,
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

  Widget _buildWebRequestResponseBody({
    required BuildContext context,
    required RequestBuilderState state,
    required AsyncValue executionState,
    required bool isLoading,
    required Environment? activeEnv,
    required List envs,
    required List<String> undefinedVars,
    required bool showWebUrlOverlay,
    required List<_WebUrlSuggestionPick> webUrlOverlayPicks,
    required Set<String> definedEnvKeys,
    required Color primary,
    required Color secondary,
  }) {
    final response = executionState.valueOrNull;
    final exec = ref.read(requestExecutionProvider.notifier);
    return _WebRequestResponseSplitView(
      minRequestHeight: _webMinRequestPaneHeight,
      minResponseHeight: _webMinResponsePaneHeight,
      splitterHeight: _webSplitterHeight,
      requestPane: _buildWebRequestEditorPane(
        context: context,
        state: state,
        executionState: executionState,
        isLoading: isLoading,
        activeEnv: activeEnv,
        envs: envs,
        undefinedVars: undefinedVars,
        showWebUrlOverlay: showWebUrlOverlay,
        webUrlOverlayPicks: webUrlOverlayPicks,
        definedEnvKeys: definedEnvKeys,
        primary: primary,
        secondary: secondary,
      ),
      responsePane: _WebInlineResponsePanel(
        response: response,
        harRequest: exec.lastSentRequest,
        harStartedAt: exec.lastStartedAt,
      ),
    );
  }

  Widget _buildWebRequestEditorPane({
    required BuildContext context,
    required RequestBuilderState state,
    required AsyncValue executionState,
    required bool isLoading,
    required Environment? activeEnv,
    required List envs,
    required List<String> undefinedVars,
    required bool showWebUrlOverlay,
    required List<_WebUrlSuggestionPick> webUrlOverlayPicks,
    required Set<String> definedEnvKeys,
    required Color primary,
    required Color secondary,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(color: scheme.surfaceContainerLowest),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _WebRequestToolbar(
            title: state.name,
            isDirty: state.isDirty,
            canSave: state.collectionUid != null,
            isLoading: isLoading,
            method: state.method,
            urlController: _urlController,
            urlFocusNode: _urlFocusNode,
            showWebUrlOverlay: showWebUrlOverlay,
            webUrlOverlayPicks: webUrlOverlayPicks,
            definedEnvKeys: definedEnvKeys,
            activeEnvironmentName: activeEnv?.name,
            undefinedVars: undefinedVars,
            onRename: _showRenameDialog,
            onCopyCurl: _copyAsCurl,
            onSave: state.collectionUid == null
                ? null
                : () {
                    AppHaptics.light();
                    unawaited(
                      _saveToCollectionAndClearDraft(state.collectionUid!),
                    );
                  },
            onSend: isLoading
                ? () => ref.read(requestExecutionProvider.notifier).cancel()
                : _sendRequest,
            onMethodChanged: (m) =>
                ref.read(requestBuilderProvider.notifier).setMethod(m),
            onUrlChanged: (value) {
              ref.read(requestBuilderProvider.notifier).setUrl(value);
              setState(() {});
            },
            onUrlCleared: () {
              _urlController.clear();
              ref.read(requestBuilderProvider.notifier).setUrl('');
              setState(() {});
            },
            onWebOverlayPick: _onWebUrlOverlayPick,
            onUrlVariableTemplateDoubleTap: _onWebUrlVariableTemplateDoubleTap,
            onEnvironmentPressed: () =>
                _showEnvPicker(context, ref, envs, activeEnv?.uid),
            onVariablesPressed: () => _showVariablesPreview(context, activeEnv),
            onPreRequestPressed: _showPreRequestSheet,
            onPasteCurlPressed: _pasteCurlIntoBuilder,
          ),
          _WebRequestTabBar(
            selectedTab: _selectedTab,
            assertionCount: state.assertions.length,
            onSelected: _onWebTabSelected,
          ),
          Expanded(
            child: _WebRequestEditorSurface(child: _buildWebEditorTab(state)),
          ),
        ],
      ),
    );
  }

  Widget _buildWebEditorTab(RequestBuilderState state) {
    final loadedUid = state.loadedRequestUid;
    return switch (_selectedTab) {
      0 => KeyValueEditorWeb(
        key: ValueKey('web-params-${loadedUid ?? 'draft'}'),
        title: 'Query Params',
        keyPlaceholder: 'Key',
        valuePlaceholder: 'Value',
        rows: state.params
            .map((p) => (key: p.key, value: p.value, isEnabled: p.isEnabled))
            .toList(),
        onChanged: (rows) {
          ref
              .read(requestBuilderProvider.notifier)
              .setParams(
                rows
                    .map(
                      (r) => RequestParam(
                        key: r.key,
                        value: r.value,
                        isEnabled: r.isEnabled,
                      ),
                    )
                    .toList(),
              );
        },
      ),
      1 => KeyValueEditorWeb(
        key: ValueKey('web-headers-${loadedUid ?? 'draft'}'),
        title: 'Headers',
        keyPlaceholder: 'Key',
        valuePlaceholder: 'Value',
        rows: state.headers
            .map((h) => (key: h.key, value: h.value, isEnabled: h.isEnabled))
            .toList(),
        onChanged: (rows) {
          ref
              .read(requestBuilderProvider.notifier)
              .setHeaders(
                rows
                    .map(
                      (r) => RequestHeader(
                        key: r.key,
                        value: r.value,
                        isEnabled: r.isEnabled,
                      ),
                    )
                    .toList(),
              );
        },
      ),
      2 => const BodyTabMaterial(),
      3 => const AuthTabMaterial(),
      4 => const TestsTabMaterial(),
      _ => const ParamsTabMaterial(),
    };
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
    if (AppPlatform.usesWebCustomUi) {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Active Environment'),
          content: SizedBox(
            width: 420,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 420),
              child: ListView(
                shrinkWrap: true,
                children: [
                  ListTile(
                    title: const Text('No Environment'),
                    trailing: activeUid == null
                        ? Icon(Icons.check, size: 16, color: primary)
                        : null,
                    onTap: () async {
                      await ref
                          .read(activeEnvironmentProvider.notifier)
                          .clearActive();
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                  ),
                  for (final e in envs)
                    ListTile(
                      title: Text(e.name),
                      trailing: e.uid == activeUid
                          ? Icon(Icons.check, size: 16, color: primary)
                          : null,
                      onTap: () {
                        ref
                            .read(environmentsProvider.notifier)
                            .setActive(e.uid);
                        Navigator.pop(ctx);
                      },
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
      return;
    }
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
                  ref.read(environmentsProvider.notifier).setActive(e.uid);
                  Navigator.pop(ctx);
                },
              ),
            ),
            const Divider(height: 1),
            ListTile(
              title: Text(
                'Cancel',
                style: Theme.of(
                  ctx,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
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

  void _showVariablesPreview(BuildContext context, Environment? env) {
    final primary = Theme.of(context).colorScheme.primary;
    if (AppPlatform.usesWebCustomUi) {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Variables'),
          content: SizedBox(
            width: 640,
            height: 520,
            child: ListView(
              children: [
                Text(
                  env == null
                      ? 'No environment selected. Dynamic variables are still available.'
                      : env.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                if (env != null)
                  for (final v in env.variables)
                    ListTile(
                      dense: true,
                      title: Text(
                        '{{${v.key}}}',
                        style: TextStyle(
                          fontFamily: 'JetBrainsMono',
                          color: v.isEnabled ? primary : null,
                        ),
                      ),
                      subtitle: Text(v.isSecret ? '••••••••' : v.value),
                      trailing: IconButton(
                        tooltip: 'Copy placeholder',
                        icon: const Icon(Icons.content_copy_outlined, size: 18),
                        onPressed: () =>
                            _copyVariablePlaceholder(ctx, '{{${v.key}}}'),
                      ),
                    ),
                const Divider(),
                const Text(
                  'Dynamic',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                for (final name in VariableInterpolator.dynamicVariables)
                  ListTile(
                    dense: true,
                    title: Text(
                      '{{$name}}',
                      style: TextStyle(
                        fontFamily: 'JetBrainsMono',
                        color: primary,
                      ),
                    ),
                    trailing: IconButton(
                      tooltip: 'Copy placeholder',
                      icon: const Icon(Icons.content_copy_outlined, size: 18),
                      onPressed: () =>
                          _copyVariablePlaceholder(ctx, '{{$name}}'),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Done'),
            ),
          ],
        ),
      );
      return;
    }
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
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: Theme.of(ctx).dividerColor),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  Text(
                    'Environment',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: Theme.of(
                        ctx,
                      ).colorScheme.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (env == null)
                    Text(
                      'No environment selected. Choose one from the pill — '
                      'or use dynamic variables below.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(
                          ctx,
                        ).colorScheme.onSurface.withValues(alpha: 0.55),
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
                          color: Theme.of(
                            ctx,
                          ).colorScheme.onSurface.withValues(alpha: 0.55),
                        ),
                      )
                    else
                      ...env.variables.map(
                        (v) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '{{${v.key}}}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'JetBrainsMono',
                                        color: v.isEnabled
                                            ? primary
                                            : Theme.of(ctx)
                                                  .colorScheme
                                                  .onSurface
                                                  .withValues(alpha: 0.55),
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
                                            .withValues(alpha: 0.55),
                                      ),
                                    ),
                                  if (v.isSecret)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 6),
                                      child: Icon(
                                        Icons.lock_outline,
                                        size: 12,
                                        color: Theme.of(ctx)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.55),
                                      ),
                                    ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.content_copy_outlined,
                                      size: 18,
                                      color: primary.withValues(alpha: 0.85),
                                    ),
                                    onPressed: () => _copyVariablePlaceholder(
                                      ctx,
                                      '{{${v.key}}}',
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 32,
                                      minHeight: 32,
                                    ),
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
                                  color: Theme.of(ctx).colorScheme.onSurface,
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
                      color: Theme.of(
                        ctx,
                      ).colorScheme.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Use in URL, headers, or body as {{name}} — resolved at send time.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(
                        ctx,
                      ).colorScheme.onSurface.withValues(alpha: 0.55),
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
                              color: primary.withValues(alpha: 0.85),
                            ),
                            onPressed: () =>
                                _copyVariablePlaceholder(ctx, '{{$name}}'),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
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

  Future<void> _showPreRequestSheet() async {
    final initial = ref.read(requestBuilderProvider).preRequestVariables;
    final initialText = bulkKeyValueRowsToText(
      initial.entries.map((e) => (key: e.key, value: e.value, isEnabled: true)),
    );
    final PreRequestVariablesOutcome? outcome;
    if (AppPlatform.usesWebCustomUi) {
      outcome = await _showPreRequestVariablesDialog(context, initialText);
    } else {
      outcome = await showPreRequestVariablesSheetMaterial(
        context,
        initialLines: initialText,
      );
    }
    if (!mounted) return;
    if (outcome is PreRequestVariablesApplied) {
      final rows = parseBulkKeyValueRows(outcome.linesText);
      final map = <String, String>{};
      for (final r in rows) {
        final k = r.key.trim();
        if (k.isEmpty) continue;
        map[k] = r.value;
      }
      ref.read(requestBuilderProvider.notifier).setPreRequestVariables(map);
    } else if (outcome is PreRequestVariablesCleared) {
      ref.read(requestBuilderProvider.notifier).clearPreRequestVariables();
    }
  }

  Future<PreRequestVariablesOutcome?> _showPreRequestVariablesDialog(
    BuildContext context,
    String initialLines,
  ) async {
    final controller = TextEditingController(text: initialLines);
    final result = await showDialog<PreRequestVariablesOutcome?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pre-request variables'),
        content: SizedBox(
          width: 640,
          child: TextField(
            controller: controller,
            maxLines: 12,
            minLines: 8,
            style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 13),
            decoration: const InputDecoration(
              hintText: 'baseUrl=https://api.example.com',
              labelText: 'Entries',
              helperText: 'One line per row. Use tab, ":" or "=" separators.',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, PreRequestVariablesCleared()),
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(ctx, PreRequestVariablesApplied(controller.text)),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  Future<void> _pasteCurlIntoBuilder() async {
    final controller = TextEditingController();
    final String? curlCommand;
    if (AppPlatform.usesWebCustomUi) {
      curlCommand = await showDialog<String?>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Paste cURL'),
          content: SizedBox(
            width: 680,
            child: TextField(
              controller: controller,
              maxLines: 9,
              minLines: 6,
              style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 13),
              decoration: const InputDecoration(
                hintText: "curl -X GET 'https://api.example.com'",
                labelText: 'cURL command',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('Apply'),
            ),
          ],
        ),
      );
    } else {
      curlCommand = await showModalBottomSheet<String?>(
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
    }
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
    ref.read(requestBuilderProvider.notifier).applyImportedHttpRequest(parsed);
    _urlController.text = ref.read(requestBuilderProvider).url;
    setState(() {});
    if (!mounted) return;
    await UserNotification.show(
      context: context,
      title: 'Imported',
      body: 'Request fields were replaced from cURL.',
    );
  }

  Future<void> _showResponseSheet() async {
    if (AppPlatform.usesWebCustomUi) {
      setState(() {});
      return;
    }
    final response = ref.read(requestExecutionProvider).value;
    if (response == null) return;
    final exec = ref.read(requestExecutionProvider.notifier);
    final harReq = exec.lastSentRequest;
    final harStarted = exec.lastStartedAt;
    await showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      useRootNavigator: true,
      isDismissible: true,
      enableDrag: true,
      builder: (ctx) => PopScope(
        canPop: true,
        child: SizedBox(
          height: MediaQuery.of(ctx).size.height * 0.85,
          child: ResponseViewerSheetMaterial(
            response: response,
            harRequest: harReq,
            harStartedAt: harStarted,
          ),
        ),
      ),
    );
    if (!mounted) return;
    await AdService.instance.maybeShowPostRequestInterstitial();
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
                color: Theme.of(
                  dialogContext,
                ).colorScheme.onSurface.withValues(alpha: 0.55),
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
            onPressed: () => Navigator.pop(dialogContext, controller.text),
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
  const _MethodSelectorMaterial({
    required this.method,
    required this.onChanged,
    this.useWebDialog = false,
  });

  final HttpMethod method;
  final void Function(HttpMethod) onChanged;
  final bool useWebDialog;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.methodColor(method.value);
    return GestureDetector(
      onTap: () async {
        final HttpMethod? selected;
        if (useWebDialog) {
          selected = await showDialog<HttpMethod>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Select Method'),
              content: SizedBox(
                width: 360,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final m in HttpMethod.values)
                      ListTile(
                        dense: true,
                        title: Text(
                          m.value,
                          style: TextStyle(
                            fontFamily: 'JetBrainsMono',
                            fontWeight: FontWeight.w700,
                            color: AppColors.methodColor(m.value),
                          ),
                        ),
                        trailing: m == method
                            ? Icon(
                                Icons.check,
                                color: Theme.of(ctx).colorScheme.primary,
                              )
                            : null,
                        onTap: () => Navigator.pop(ctx, m),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          );
        } else {
          selected = await showModalBottomSheet<HttpMethod>(
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
        if (selected != null) onChanged(selected);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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

class _WebUrlSuggestionPick {
  const _WebUrlSuggestionPick._({
    required this.title,
    this.subtitle,
    this.url,
    this.envKey,
  });

  factory _WebUrlSuggestionPick.url(String url) =>
      _WebUrlSuggestionPick._(title: url, url: url);

  factory _WebUrlSuggestionPick.env(String key, Environment? env) {
    String? subtitle;
    if (env != null) {
      final row = env.variables
          .where((v) => v.key == key && v.isEnabled)
          .firstOrNull;
      final val = row?.value.trim();
      if (val != null && val.isNotEmpty) {
        subtitle = val.length > 48 ? '${val.substring(0, 48)}…' : val;
      }
    }
    return _WebUrlSuggestionPick._(
      title: '{{$key}}',
      subtitle: subtitle,
      envKey: key,
    );
  }

  final String title;
  final String? subtitle;
  final String? url;
  final String? envKey;
}

class _WebRequestToolbar extends StatelessWidget {
  const _WebRequestToolbar({
    required this.title,
    required this.isDirty,
    required this.canSave,
    required this.isLoading,
    required this.method,
    required this.urlController,
    required this.urlFocusNode,
    required this.showWebUrlOverlay,
    required this.webUrlOverlayPicks,
    required this.definedEnvKeys,
    required this.activeEnvironmentName,
    required this.undefinedVars,
    required this.onRename,
    required this.onCopyCurl,
    required this.onSave,
    required this.onSend,
    required this.onMethodChanged,
    required this.onUrlChanged,
    required this.onUrlCleared,
    required this.onWebOverlayPick,
    required this.onUrlVariableTemplateDoubleTap,
    required this.onEnvironmentPressed,
    required this.onVariablesPressed,
    required this.onPreRequestPressed,
    required this.onPasteCurlPressed,
  });

  final String title;
  final bool isDirty;
  final bool canSave;
  final bool isLoading;
  final HttpMethod method;
  final TextEditingController urlController;
  final FocusNode urlFocusNode;
  final bool showWebUrlOverlay;
  final List<_WebUrlSuggestionPick> webUrlOverlayPicks;
  final Set<String> definedEnvKeys;
  final String? activeEnvironmentName;
  final List<String> undefinedVars;
  final VoidCallback onRename;
  final VoidCallback onCopyCurl;
  final VoidCallback? onSave;
  final VoidCallback onSend;
  final ValueChanged<HttpMethod> onMethodChanged;
  final ValueChanged<String> onUrlChanged;
  final VoidCallback onUrlCleared;
  final ValueChanged<_WebUrlSuggestionPick> onWebOverlayPick;
  final ValueChanged<UrlVariableTemplateSpan> onUrlVariableTemplateDoubleTap;
  final VoidCallback onEnvironmentPressed;
  final VoidCallback onVariablesPressed;
  final VoidCallback onPreRequestPressed;
  final VoidCallback onPasteCurlPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final border = scheme.outlineVariant.withValues(alpha: 0.62);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(bottom: BorderSide(color: border)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.http_outlined,
                  size: 16,
                  color: AppColors.methodColor(method.value),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: InkWell(
                    onTap: onRename,
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (isDirty) ...[
                            const SizedBox(width: 4),
                            Text(
                              'Unsaved',
                              style: TextStyle(
                                color: scheme.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                _WebToolbarIconButton(
                  icon: Icons.content_copy_outlined,
                  tooltip: 'Copy as cURL',
                  onPressed: onCopyCurl,
                ),
                const SizedBox(width: 4),
                OutlinedButton(
                  onPressed: canSave && isDirty ? onSave : null,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(58, 30),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text('Save', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            TextFieldTapRegion(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        WebRequestMethodUrlBar(
                          method: method,
                          onMethodChanged: onMethodChanged,
                          urlController: urlController,
                          urlFocusNode: urlFocusNode,
                          urlFieldFocused: urlFocusNode.hasFocus,
                          definedEnvKeys: definedEnvKeys,
                          showClearButton: urlController.text.isNotEmpty,
                          onClear: onUrlCleared,
                          onUrlChanged: onUrlChanged,
                          hintText: 'Enter request URL',
                          onClosedTemplateDoubleTap:
                              onUrlVariableTemplateDoubleTap,
                        ),
                        if (showWebUrlOverlay)
                          _WebUrlSuggestions(
                            picks: webUrlOverlayPicks,
                            onSelected: onWebOverlayPick,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    height: kWebChromeSingleLineFieldHeight,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: isLoading ? null : AppColors.ctaGradient,
                        color: isLoading ? scheme.errorContainer : null,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextButton.icon(
                        onPressed: onSend,
                        icon: Icon(
                          isLoading ? Icons.stop_circle_outlined : Icons.send,
                          size: 16,
                          color: isLoading
                              ? scheme.onErrorContainer
                              : Colors.white,
                        ),
                        label: Text(
                          isLoading ? 'Cancel' : 'Send',
                          style: TextStyle(
                            color: isLoading
                                ? scheme.onErrorContainer
                                : Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          minimumSize: const Size(
                            0,
                            kWebChromeSingleLineFieldHeight,
                          ),
                          fixedSize: const Size.fromHeight(
                            kWebChromeSingleLineFieldHeight,
                          ),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 28,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _WebToolbarPill(
                    icon: activeEnvironmentName == null
                        ? Icons.circle_outlined
                        : Icons.check_circle,
                    label: activeEnvironmentName ?? 'No Environment',
                    onPressed: onEnvironmentPressed,
                  ),
                  const SizedBox(width: 6),
                  _WebToolbarPill(
                    icon: Icons.data_object_outlined,
                    label: 'Variables',
                    onPressed: onVariablesPressed,
                  ),
                  const SizedBox(width: 6),
                  _WebToolbarPill(
                    icon: Icons.tune_outlined,
                    label: 'Pre-request',
                    onPressed: onPreRequestPressed,
                  ),
                  const SizedBox(width: 6),
                  _WebToolbarPill(
                    icon: Icons.terminal,
                    label: 'Paste cURL',
                    onPressed: onPasteCurlPressed,
                  ),
                  if (undefinedVars.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    _WebToolbarPill(
                      icon: Icons.warning_amber_rounded,
                      label: 'Undefined: ${undefinedVars.join(', ')}',
                      foreground: Colors.orange.shade800,
                      background: Colors.orange.withValues(alpha: 0.1),
                      onPressed: onVariablesPressed,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WebUrlSuggestions extends StatelessWidget {
  const _WebUrlSuggestions({
    required this.picks,
    required this.onSelected,
  });

  final List<_WebUrlSuggestionPick> picks;
  final ValueChanged<_WebUrlSuggestionPick> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(top: 6),
      constraints: const BoxConstraints(maxHeight: 168),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: picks.length,
        separatorBuilder: (_, __) =>
            Divider(height: 1, color: scheme.outlineVariant),
        itemBuilder: (context, index) {
          final pick = picks[index];
          final sub = pick.subtitle;
          return InkWell(
            onTap: () => onSelected(pick),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pick.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'JetBrainsMono',
                      fontSize: 12,
                      fontWeight:
                          pick.envKey != null ? FontWeight.w700 : FontWeight.w500,
                      color: pick.envKey != null
                          ? scheme.primary
                          : scheme.onSurface,
                    ),
                  ),
                  if (sub != null && sub.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: scheme.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _WebToolbarIconButton extends StatelessWidget {
  const _WebToolbarIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        visualDensity: VisualDensity.compact,
        iconSize: 16,
        onPressed: onPressed,
        icon: Icon(icon),
      ),
    );
  }
}

class _WebToolbarPill extends StatelessWidget {
  const _WebToolbarPill({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.foreground,
    this.background,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color? foreground;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = foreground ?? scheme.onSurface.withValues(alpha: 0.76);
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 13, color: fg),
      label: Text(
        label,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600),
      ),
      style: OutlinedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        backgroundColor: background ?? scheme.surfaceContainerHighest,
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.7)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        minimumSize: const Size(0, 26),
      ),
    );
  }
}

class _WebRequestTabBar extends StatelessWidget {
  const _WebRequestTabBar({
    required this.selectedTab,
    required this.assertionCount,
    required this.onSelected,
  });

  final int selectedTab;
  final int assertionCount;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final tabs = <({String label, int index})>[
      (label: 'Params', index: 0),
      (label: 'Authorization', index: 3),
      (label: 'Headers', index: 1),
      (label: 'Body', index: 2),
      (
        label: assertionCount == 0 ? 'Tests' : 'Tests ($assertionCount)',
        index: 4,
      ),
    ];
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          bottom: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.64),
          ),
        ),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemBuilder: (context, index) {
          final tab = tabs[index];
          final selected = tab.index == selectedTab;
          return InkWell(
            onTap: () => onSelected(tab.index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: selected ? scheme.primary : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                tab.label,
                style: TextStyle(
                  color: selected
                      ? scheme.primary
                      : scheme.onSurface.withValues(alpha: 0.68),
                  fontSize: 11.5,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 2),
        itemCount: tabs.length,
      ),
    );
  }
}

class _WebRequestEditorSurface extends StatelessWidget {
  const _WebRequestEditorSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(color: scheme.surfaceContainerLowest),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.62),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _WebRequestResponseSplitView extends StatefulWidget {
  const _WebRequestResponseSplitView({
    required this.requestPane,
    required this.responsePane,
    required this.minRequestHeight,
    required this.minResponseHeight,
    required this.splitterHeight,
  });

  final Widget requestPane;
  final Widget responsePane;
  final double minRequestHeight;
  final double minResponseHeight;
  final double splitterHeight;

  @override
  State<_WebRequestResponseSplitView> createState() =>
      _WebRequestResponseSplitViewState();
}

class _WebRequestResponseSplitViewState
    extends State<_WebRequestResponseSplitView> {
  final ValueNotifier<double?> _responsePaneHeight = ValueNotifier<double?>(
    null,
  );

  @override
  void dispose() {
    _responsePaneHeight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalHeight = constraints.maxHeight;
        final available = totalHeight - widget.splitterHeight;
        final hasMinSpace =
            available >= widget.minRequestHeight + widget.minResponseHeight;
        final maxResponse = hasMinSpace
            ? available - widget.minRequestHeight
            : widget.minResponseHeight;
        final defaultResponse = (available * 0.45)
            .clamp(widget.minResponseHeight, maxResponse)
            .toDouble();

        return ValueListenableBuilder<double?>(
          valueListenable: _responsePaneHeight,
          builder: (context, raw, _) {
            final responseHeight = (raw ?? defaultResponse)
                .clamp(widget.minResponseHeight, maxResponse)
                .toDouble();
            final requestHeight = available - responseHeight;
            return Column(
              children: [
                SizedBox(
                  height: requestHeight,
                  child: RepaintBoundary(child: widget.requestPane),
                ),
                _WebResponseSplitter(
                  height: widget.splitterHeight,
                  onDragUpdate: (delta) {
                    final next = (responseHeight - delta)
                        .clamp(widget.minResponseHeight, maxResponse)
                        .toDouble();
                    if (next != responseHeight) {
                      _responsePaneHeight.value = next;
                    }
                  },
                  onDoubleTap: () =>
                      _responsePaneHeight.value = defaultResponse,
                ),
                SizedBox(
                  height: responseHeight,
                  child: RepaintBoundary(child: widget.responsePane),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _WebInlineResponsePanel extends StatelessWidget {
  const _WebInlineResponsePanel({
    required this.response,
    required this.harRequest,
    required this.harStartedAt,
  });

  final HttpResponse? response;
  final HttpRequest? harRequest;
  final DateTime? harStartedAt;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          top: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.8)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _WebResponseHeader(response: response),
          if (response != null) const _WebResponseTopTabs(),
          Expanded(
            child: response == null
                ? const _EmptyWebResponsePane()
                : ResponseViewerSheetMaterial(
                    response: response!,
                    harRequest: harRequest,
                    harStartedAt: harStartedAt,
                    showSheetHandle: false,
                  ),
          ),
        ],
      ),
    );
  }
}

class _WebResponseHeader extends StatelessWidget {
  const _WebResponseHeader({required this.response});

  final HttpResponse? response;

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDuration(int ms) {
    if (ms < 1000) return '${ms}ms';
    return '${(ms / 1000).toStringAsFixed(2)}s';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          bottom: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.62),
          ),
        ),
      ),
      child: Row(
        children: [
          const Text(
            'Response',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
          const SizedBox(width: 8),
          if (response == null)
            Text(
              'Awaiting first send',
              style: TextStyle(
                color: scheme.onSurface.withValues(alpha: 0.5),
                fontSize: 11,
              ),
            )
          else ...[
            _ResponseStatBadge(
              label: '${response!.statusCode}',
              color: AppColors.statusColor(response!.statusCode),
            ),
            const SizedBox(width: 4),
            _ResponseStatBadge(
              label: _formatDuration(response!.durationMs),
              color: scheme.primary,
            ),
            const SizedBox(width: 4),
            _ResponseStatBadge(
              label: _formatSize(response!.sizeBytes),
              color: scheme.tertiary,
            ),
          ],
          const Spacer(),
          if (response != null) ...[
            Icon(
              Icons.copy_all_outlined,
              size: 15,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 10),
            Icon(
              Icons.share_outlined,
              size: 15,
              color: scheme.onSurfaceVariant,
            ),
          ],
        ],
      ),
    );
  }
}

class _WebResponseTopTabs extends StatelessWidget {
  const _WebResponseTopTabs();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          bottom: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
      ),
      child: Row(
        children: [
          const _WebResponseTabChip(label: 'Pretty', selected: true),
          const SizedBox(width: 6),
          const _WebResponseTabChip(label: 'Raw'),
          const SizedBox(width: 6),
          const _WebResponseTabChip(label: 'Headers'),
          const SizedBox(width: 6),
          const _WebResponseTabChip(label: 'Cookies'),
          const Spacer(),
          Icon(Icons.search, size: 15, color: scheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Icon(Icons.wrap_text, size: 15, color: scheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Icon(Icons.more_horiz, size: 16, color: scheme.onSurfaceVariant),
        ],
      ),
    );
  }
}

class _WebResponseTabChip extends StatelessWidget {
  const _WebResponseTabChip({required this.label, this.selected = false});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: selected ? scheme.surfaceContainerHigh : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: selected
              ? scheme.outlineVariant.withValues(alpha: 0.8)
              : Colors.transparent,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected
              ? scheme.onSurface
              : scheme.onSurface.withValues(alpha: 0.65),
        ),
      ),
    );
  }
}

class _ResponseStatBadge extends StatelessWidget {
  const _ResponseStatBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontFamily: 'JetBrainsMono',
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _WebResponseSplitter extends StatelessWidget {
  const _WebResponseSplitter({
    required this.height,
    required this.onDragUpdate,
    required this.onDoubleTap,
  });

  final double height;
  final ValueChanged<double> onDragUpdate;
  final VoidCallback onDoubleTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return MouseRegion(
      cursor: SystemMouseCursors.resizeUpDown,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragUpdate: (details) => onDragUpdate(details.delta.dy),
        onDoubleTap: onDoubleTap,
        child: Container(
          key: const ValueKey('web-response-splitter'),
          height: height,
          color: scheme.surfaceContainerHighest,
          alignment: Alignment.center,
          child: Container(
            width: 36,
            height: 2,
            decoration: BoxDecoration(
              color: scheme.outline.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyWebResponsePane extends StatelessWidget {
  const _EmptyWebResponsePane();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        border: Border(
          top: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notes_outlined,
              size: 38,
              color: scheme.onSurface.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 10),
            Text(
              'Response will appear here',
              style: TextStyle(
                color: scheme.onSurface.withValues(alpha: 0.72),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Send a request to inspect status, headers, body, tests, and HAR.',
              style: TextStyle(
                color: scheme.onSurface.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
          ],
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
            _ChipMaterial(label: _formatSize(sizeBytes), color: Colors.indigo),
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
