import 'package:aun_reqstudio/features/request_builder/providers/request_builder_provider.dart';
import 'package:aun_reqstudio/features/shell/web_workspace_tab_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('web request tabs keep independent draft state', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: ProviderScope(child: _WorkspaceHarness())),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('url-field-tab-a')),
      'https://api.example.com/a',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tab B'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('url-field-tab-b')),
      'https://api.example.com/b',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tab A'));
    await tester.pumpAndSettle();
    expect(_activeTextFieldValue(tester), 'https://api.example.com/a');

    await tester.tap(find.byKey(const ValueKey('close-active-tab')));
    await tester.pumpAndSettle();
    expect(find.text('Close request tab?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Tab A'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('close-active-tab')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Close tab'));
    await tester.pumpAndSettle();

    expect(find.text('Tab A'), findsNothing);
    expect(find.text('Tab B'), findsOneWidget);
    expect(_activeTextFieldValue(tester), 'https://api.example.com/b');
  });
}

String _activeTextFieldValue(WidgetTester tester) {
  final editable = tester.widget<EditableText>(find.byType(EditableText));
  return editable.controller.text;
}

class _WorkspaceHarness extends StatefulWidget {
  const _WorkspaceHarness();

  @override
  State<_WorkspaceHarness> createState() => _WorkspaceHarnessState();
}

class _WorkspaceHarnessState extends State<_WorkspaceHarness> {
  final WebWorkspaceTabController _controller = WebWorkspaceTabController();

  @override
  void initState() {
    super.initState();
    _controller
      ..openNewRequest(collectionUid: 'collection-1', timestamp: 1)
      ..reportTabStatus(
        tabId: 'new:collection-1:root:1',
        title: 'Tab A',
        isDirty: true,
        isSending: false,
        hasResponse: false,
      )
      ..openNewRequest(collectionUid: 'collection-1', timestamp: 2)
      ..reportTabStatus(
        tabId: 'new:collection-1:root:2',
        title: 'Tab B',
        isDirty: true,
        isSending: false,
        hasResponse: false,
      )
      ..focusTab('new:collection-1:root:1');
    _controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onControllerChanged)
      ..dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _closeActiveTab() async {
    final tabId = _controller.activeTabId;
    if (tabId == null) return;
    if (!_controller.requestCloseTab(tabId)) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => const _CloseDialog(),
      );
      if (confirmed != true) return;
    }
    _controller.closeTab(tabId);
  }

  @override
  Widget build(BuildContext context) {
    final tabs = _controller.tabs;
    final activeIndex = tabs.indexWhere(
      (tab) => tab.id == _controller.activeTabId,
    );
    return Scaffold(
      body: Column(
        children: [
          Row(
            children: [
              for (final tab in tabs)
                TextButton(
                  onPressed: () => _controller.focusTab(tab.id),
                  child: Text(tab.title),
                ),
              IconButton(
                key: const ValueKey('close-active-tab'),
                onPressed: _closeActiveTab,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          Expanded(
            child: activeIndex == -1
                ? const SizedBox.shrink()
                : IndexedStack(
                    index: activeIndex,
                    children: [
                      for (final tab in tabs)
                        ProviderScope(
                          key: ValueKey('scope-${tab.id}'),
                          child: _TabEditor(
                            key: ValueKey('editor-${tab.id}'),
                            tabId: tab.id,
                            label: tab.title,
                            onStatusChanged: _controller.reportTabStatus,
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _TabEditor extends ConsumerWidget {
  const _TabEditor({
    super.key,
    required this.tabId,
    required this.label,
    required this.onStatusChanged,
  });

  final String tabId;
  final String label;
  final void Function({
    required String tabId,
    required String title,
    required bool isDirty,
    required bool isSending,
    required bool hasResponse,
    String? requestUid,
  })
  onStatusChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(requestBuilderProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onStatusChanged(
        tabId: tabId,
        title: label,
        isDirty: state.isDirty,
        isSending: false,
        hasResponse: false,
      );
    });

    final keySuffix = label == 'Tab A' ? 'tab-a' : 'tab-b';
    return Center(
      child: SizedBox(
        width: 520,
        child: TextFormField(
          key: ValueKey('url-field-$keySuffix'),
          initialValue: state.url,
          decoration: InputDecoration(labelText: '$label URL'),
          onChanged: ref.read(requestBuilderProvider.notifier).setUrl,
        ),
      ),
    );
  }
}

class _CloseDialog extends StatelessWidget {
  const _CloseDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Close request tab?'),
      content: const Text('Closing this tab discards its draft state.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Close tab'),
        ),
      ],
    );
  }
}
