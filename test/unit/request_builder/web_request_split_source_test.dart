import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final sourceFile = File(
    'lib/features/request_builder/request_builder_screen_material.dart',
  );

  test('web request builder owns inline response split pane primitives', () {
    final source = sourceFile.readAsStringSync();

    expect(source, contains('_buildWebRequestResponseBody'));
    expect(source, contains('class _WebRequestResponseSplitView'));
    expect(source, contains('class _WebResponseSplitter'));
    expect(source, contains("ValueKey('web-response-splitter')"));
    expect(source, contains('class _EmptyWebResponsePane'));
    expect(source, contains('class _WebInlineResponsePanel'));
    expect(source, contains('showSheetHandle: false'));
  });

  test('web request builder uses dense workspace primitives', () {
    final source = sourceFile.readAsStringSync();

    expect(source, contains('class _WebRequestToolbar'));
    expect(source, contains('class _WebRequestTabBar'));
    expect(source, contains('class _WebRequestEditorSurface'));
    expect(source, contains('KeyValueEditorWeb('));
    expect(source, contains("title: 'Query Params'"));
    expect(source, contains("title: 'Headers'"));
  });

  test('web split view drives drag updates through a ValueNotifier', () {
    final source = sourceFile.readAsStringSync();

    expect(source, contains('ValueNotifier<double?> _responsePaneHeight'));
    expect(source, contains('ValueListenableBuilder<double?>'));
    expect(source, contains('onDragUpdate: (delta) {'));
    expect(source, contains('_responsePaneHeight.value = next'));
    expect(source, isNot(contains('_webResponsePaneRatio')));
    expect(source, isNot(contains('nextHeight / availableHeight')));
    expect(
      source,
      isNot(contains('_webResponsePaneHeight = (responseHeight - delta)')),
    );
  });

  test('web response completion does not open the mobile response sheet', () {
    final source = sourceFile.readAsStringSync();

    expect(
      source,
      contains(
        'if (AppPlatform.usesWebCustomUi) {\n          setState(() {});',
      ),
    );
    expect(source, contains('Future<void> _showResponseSheet() async'));
    expect(source, contains('await showModalBottomSheet'));
  });

  test('request builder web interactions use dialogs instead of sheets', () {
    final source = sourceFile.readAsStringSync();
    final methodUrlBar = File(
      'lib/features/request_builder/web/web_request_method_url_bar.dart',
    ).readAsStringSync();

    expect(source, contains('_showPreRequestVariablesDialog'));
    expect(source, contains('WebRequestMethodUrlBar'));
    expect(methodUrlBar, contains('MenuAnchor'));
    expect(source, contains('showDialog<String?>'));
    expect(source, contains('showDialog<void>'));
  });

  test('legacy web key-value table widgets are removed', () {
    final source = sourceFile.readAsStringSync();

    expect(source, isNot(contains('class _WebKeyValueTable')));
    expect(source, isNot(contains('class _WebKeyValueTableRow')));
    expect(source, isNot(contains('class _WebTableHeaderCell')));
    expect(source, isNot(contains('class _WebTableTextField')));
    expect(source, isNot(contains('class _WebTableDescriptionCell')));
  });
}
