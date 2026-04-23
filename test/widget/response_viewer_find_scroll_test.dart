import 'dart:convert';
import 'dart:io';

import 'package:aun_reqstudio/domain/models/http_response.dart';
import 'package:aun_reqstudio/features/response_viewer/response_viewer_sheet.dart';
import 'package:aun_reqstudio/features/response_viewer/response_viewer_sheet_material.dart';
import 'package:aun_reqstudio/features/response_viewer/response_viewer_syntax.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

HttpResponse _testResponseWithBody(String body) {
  return HttpResponse(
    statusCode: 200,
    statusMessage: 'OK',
    headers: const {'content-type': 'text/plain'},
    body: body,
    durationMs: 42,
    sizeBytes: body.length,
    receivedAt: DateTime(2026, 4, 20),
  );
}

String _longBodyWithMatches() {
  final lines = List<String>.generate(140, (i) {
    if (i == 10 || i == 80 || i == 120) return 'line $i target-word here';
    return 'line $i filler content';
  });
  return lines.join('\n');
}

String _veryLongBodyWithMatches() {
  final lines = List<String>.generate(5000, (i) {
    if (i == 0) return 'line $i very-first-line';
    if (i == 50 || i == 2500 || i == 4900) return 'line $i target-word here';
    return 'line $i filler content';
  });
  return lines.join('\n');
}

String _hugeSingleLineBody() {
  return List<String>.filled(220000, 'x').join();
}

String _hugeJsonBody() {
  return '{"payload":"${List<String>.filled(350000, 'x').join()}"}';
}

String _largePrettyJsonBody() {
  return const JsonEncoder.withIndent('  ').convert({
    'items': List<Map<String, Object>>.generate(
      12000,
      (i) => {'id': i, 'name': 'item_$i', 'active': i.isEven},
    ),
  });
}

String _wideJsonBody() {
  return '{"payload":"${List<String>.filled(240, 'x').join()}","meta":"tail"}';
}

String _nestedJsonBody() {
  return '{"outer":{"inner":{"target":"needle"}}}';
}

String _apiFixtureBody() {
  return File(
    'test/fixtures/response_viewer_master_data.json',
  ).readAsStringSync();
}

Widget _phoneViewport(Widget child) {
  return MediaQuery(
    data: const MediaQueryData(size: Size(390, 844)),
    child: child,
  );
}

String _apiFixtureSearchSampleBody() {
  final full = _apiFixtureBody();
  const sampleChars = 140000;
  if (full.length <= sampleChars) return full;
  return full.substring(0, sampleChars);
}

ScrollableState _firstVerticalScrollableState(WidgetTester tester) {
  final vertical = find.byWidgetPredicate(
    (w) =>
        w is Scrollable &&
        (w.axisDirection == AxisDirection.down ||
            w.axisDirection == AxisDirection.up),
  );
  return tester.state<ScrollableState>(vertical.first);
}

Iterable<Scrollable> _horizontalScrollables(WidgetTester tester) {
  return find
      .byWidgetPredicate(
        (w) =>
            w is Scrollable &&
            (w.axisDirection == AxisDirection.left ||
                w.axisDirection == AxisDirection.right),
      )
      .evaluate()
      .map((e) => e.widget as Scrollable);
}

Future<void> _pumpUntilVisible(
  WidgetTester tester,
  Finder finder, {
  int maxPumps = 20,
  Duration step = const Duration(milliseconds: 200),
}) async {
  for (var i = 0; i < maxPumps; i++) {
    if (finder.evaluate().isNotEmpty) {
      return;
    }
    await tester.pump(step);
  }
}

void main() {
  testWidgets('Cupertino response find next scrolls and shows scrollbar', (
    tester,
  ) async {
    final response = _testResponseWithBody(_longBodyWithMatches());

    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoPageScaffold(
          child: ResponseViewerSheet(response: response),
        ),
      ),
    );

    await tester.enterText(
      find.byType(CupertinoSearchTextField),
      'target-word',
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('1/3'), findsOneWidget);
    expect(find.byType(CupertinoScrollbar), findsWidgets);
    expect(
      _firstVerticalScrollableState(tester).position.pixels,
      greaterThan(0),
    );

    await tester.tap(find.byIcon(CupertinoIcons.chevron_down));
    await tester.pump();

    expect(find.text('2/3'), findsOneWidget);
  });

  testWidgets('Material response find next scrolls and shows scrollbar', (
    tester,
  ) async {
    final response = _testResponseWithBody(_longBodyWithMatches());

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ResponseViewerSheetMaterial(response: response)),
      ),
    );

    await tester.enterText(find.byType(TextField).first, 'target-word');
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('1/3'), findsOneWidget);
    expect(find.byType(Scrollbar), findsWidgets);
    expect(
      _firstVerticalScrollableState(tester).position.pixels,
      greaterThan(0),
    );

    await tester.tap(find.byIcon(Icons.keyboard_arrow_down));
    await tester.pump();

    expect(find.text('2/3'), findsOneWidget);
  });

  testWidgets(
    'Cupertino response starts at line 1 and drag moves scroll end-to-end',
    (tester) async {
      final response = _testResponseWithBody(_veryLongBodyWithMatches());

      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: ResponseViewerSheet(response: response),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('very-first-line'), findsOneWidget);
      expect(find.byType(CupertinoScrollbar), findsWidgets);

      final scrollable = _firstVerticalScrollableState(tester);
      expect(scrollable.position.pixels, 0.0);

      final listFinder = find.byType(ListView).first;
      await tester.drag(listFinder, const Offset(0, -2400));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      final offsetAfterDragUp = scrollable.position.pixels;
      expect(offsetAfterDragUp, greaterThan(0));

      await tester.drag(listFinder, const Offset(0, 6000));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(scrollable.position.pixels, lessThan(offsetAfterDragUp));
    },
  );

  testWidgets(
    'Long response find next/prev jumps instantly on both platforms',
    (tester) async {
      final response = _testResponseWithBody(_veryLongBodyWithMatches());

      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: ResponseViewerSheet(response: response),
          ),
        ),
      );
      await tester.enterText(
        find.byType(CupertinoSearchTextField),
        'target-word',
      );
      await _pumpUntilVisible(tester, find.text('1/3'));

      await tester.tap(find.byIcon(CupertinoIcons.chevron_down));
      await tester.pump();
      await _pumpUntilVisible(tester, find.text('2/3'));
      await tester.tap(find.byIcon(CupertinoIcons.chevron_up));
      await tester.pump();
      await _pumpUntilVisible(tester, find.text('1/3'));

      await tester.pumpWidget(
        MaterialApp(
          home: _phoneViewport(
            Scaffold(body: ResponseViewerSheetMaterial(response: response)),
          ),
        ),
      );
      await tester.enterText(find.byType(TextField).first, 'target-word');
      await _pumpUntilVisible(tester, find.text('1/3'));

      await tester.tap(find.byIcon(Icons.keyboard_arrow_down));
      await tester.pump();
      await _pumpUntilVisible(tester, find.text('2/3'));
      await tester.tap(find.byIcon(Icons.keyboard_arrow_up));
      await tester.pump();
      await _pumpUntilVisible(tester, find.text('1/3'));
    },
  );

  testWidgets(
    'Huge single-line body renders without crashing on both platforms',
    (tester) async {
      final response = _testResponseWithBody(_hugeSingleLineBody());

      await tester.pumpWidget(
        CupertinoApp(
          home: _phoneViewport(
            CupertinoPageScaffold(
              child: ResponseViewerSheet(response: response),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ResponseViewerSheet), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          home: _phoneViewport(
            Scaffold(body: ResponseViewerSheetMaterial(response: response)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ResponseViewerSheetMaterial), findsOneWidget);
    },
  );

  testWidgets('Huge JSON keeps syntax highlighting on both platforms', (
    tester,
  ) async {
    final body = _hugeJsonBody();
    final response = HttpResponse(
      statusCode: 200,
      statusMessage: 'OK',
      headers: const {'content-type': 'application/json'},
      body: body,
      durationMs: 42,
      sizeBytes: body.length,
      receivedAt: DateTime(2026, 4, 20),
    );

    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoPageScaffold(
          child: ResponseViewerSheet(response: response),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(HighlightedLineWidget), findsWidgets);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ResponseViewerSheetMaterial(response: response)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(HighlightedLineWidget), findsWidgets);
  });

  testWidgets('Large pretty JSON keeps unwrap enabled on both platforms', (
    tester,
  ) async {
    final body = _largePrettyJsonBody();
    final response = HttpResponse(
      statusCode: 200,
      statusMessage: 'OK',
      headers: const {'content-type': 'application/json'},
      body: body,
      durationMs: 42,
      sizeBytes: body.length,
      receivedAt: DateTime(2026, 4, 20),
    );

    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoPageScaffold(
          child: ResponseViewerSheet(response: response),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(CupertinoSwitch), findsNWidgets(2));
    expect(find.text('Too large'), findsNothing);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ResponseViewerSheetMaterial(response: response)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(Switch), findsNWidgets(2));
    expect(find.text('Too large'), findsNothing);
  });

  testWidgets(
    'Material large-response search shows loader during debounce and resolves',
    (tester) async {
      final body = _apiFixtureSearchSampleBody();
      final response = HttpResponse(
        statusCode: 200,
        statusMessage: 'OK',
        headers: const {'content-type': 'application/json'},
        body: body,
        durationMs: 42,
        sizeBytes: body.length,
        receivedAt: DateTime(2026, 4, 24),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ResponseViewerSheetMaterial(response: response)),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'territoryName');
      await tester.pump();

      expect(find.text('Waiting...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsWidgets);

      await _pumpUntilVisible(tester, find.text('1/1'));

      expect(find.text('1/1'), findsOneWidget);
    },
  );

  testWidgets(
    'Cupertino large-response search starts loader without blocking typing',
    (tester) async {
      final body = _apiFixtureSearchSampleBody();
      final response = HttpResponse(
        statusCode: 200,
        statusMessage: 'OK',
        headers: const {'content-type': 'application/json'},
        body: body,
        durationMs: 42,
        sizeBytes: body.length,
        receivedAt: DateTime(2026, 4, 24),
      );

      await tester.pumpWidget(
        CupertinoApp(
          home: _phoneViewport(
            CupertinoPageScaffold(
              child: ResponseViewerSheet(response: response),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(CupertinoSearchTextField),
        'territoryName',
      );
      await tester.pump();

      expect(find.text('Waiting...'), findsOneWidget);
      expect(find.byType(CupertinoActivityIndicator), findsWidgets);
      expect(find.text('territoryName'), findsOneWidget);
    },
  );

  testWidgets(
    'JSON can switch between tree and text pretty views on both platforms',
    (tester) async {
      final body = _nestedJsonBody();
      final response = HttpResponse(
        statusCode: 200,
        statusMessage: 'OK',
        headers: const {'content-type': 'application/json'},
        body: body,
        durationMs: 42,
        sizeBytes: body.length,
        receivedAt: DateTime(2026, 4, 20),
      );

      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: ResponseViewerSheet(response: response),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HighlightedLineWidget), findsWidgets);
      await tester.tap(find.text('Tree').first);
      await tester.pumpAndSettle();
      expect(find.byType(HighlightedLineWidget), findsNothing);
      await tester.tap(find.text('Text').first);
      await tester.pumpAndSettle();
      expect(find.byType(HighlightedLineWidget), findsWidgets);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ResponseViewerSheetMaterial(response: response)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HighlightedLineWidget), findsWidgets);
      await tester.tap(find.text('Tree').first);
      await tester.pumpAndSettle();
      expect(find.byType(HighlightedLineWidget), findsNothing);
      await tester.tap(find.text('Text').first);
      await tester.pumpAndSettle();
      expect(find.byType(HighlightedLineWidget), findsWidgets);
    },
  );

  testWidgets('JSON tree can open when unwrap is enabled', (tester) async {
    final body = _nestedJsonBody();
    final response = HttpResponse(
      statusCode: 200,
      statusMessage: 'OK',
      headers: const {'content-type': 'application/json'},
      body: body,
      durationMs: 42,
      sizeBytes: body.length,
      receivedAt: DateTime(2026, 4, 20),
    );

    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoPageScaffold(
          child: ResponseViewerSheet(response: response),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final cupertinoSwitches = find.byType(CupertinoSwitch);
    expect(cupertinoSwitches, findsNWidgets(2));
    await tester.tap(cupertinoSwitches.at(1));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tree').first);
    await tester.pumpAndSettle();
    expect(find.byType(HighlightedLineWidget), findsNothing);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ResponseViewerSheetMaterial(response: response)),
      ),
    );
    await tester.pumpAndSettle();

    final materialSwitches = find.byType(Switch);
    expect(materialSwitches, findsNWidgets(2));
    await tester.tap(materialSwitches.at(1));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tree').first);
    await tester.pumpAndSettle();
    expect(find.byType(HighlightedLineWidget), findsNothing);
  });

  testWidgets(
    'Structured JSON search expands nested matches on both platforms',
    (tester) async {
      final body = _nestedJsonBody();
      final response = HttpResponse(
        statusCode: 200,
        statusMessage: 'OK',
        headers: const {'content-type': 'application/json'},
        body: body,
        durationMs: 42,
        sizeBytes: body.length,
        receivedAt: DateTime(2026, 4, 20),
      );

      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: ResponseViewerSheet(response: response),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tree').first);
      await tester.pumpAndSettle();
      expect(find.textContaining('needle'), findsNothing);

      await tester.enterText(find.byType(CupertinoSearchTextField), 'needle');
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.textContaining('"needle"'), findsOneWidget);
      expect(find.text('1/1'), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ResponseViewerSheetMaterial(response: response)),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tree').first);
      await tester.pumpAndSettle();
      expect(find.textContaining('needle'), findsNothing);

      await tester.enterText(find.byType(TextField).first, 'needle');
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.textContaining('"needle"'), findsOneWidget);
      expect(find.text('1/1'), findsOneWidget);
    },
  );

  testWidgets(
    'Unwrapped JSON uses one shared horizontal body scroll on both platforms',
    (tester) async {
      final body = _wideJsonBody();
      final response = HttpResponse(
        statusCode: 200,
        statusMessage: 'OK',
        headers: const {'content-type': 'application/json'},
        body: body,
        durationMs: 42,
        sizeBytes: body.length,
        receivedAt: DateTime(2026, 4, 20),
      );

      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: ResponseViewerSheet(response: response),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final cupertinoSwitches = find.byType(CupertinoSwitch);
      expect(cupertinoSwitches, findsNWidgets(2));
      await tester.tap(cupertinoSwitches.first);
      await tester.pumpAndSettle();

      expect(_horizontalScrollables(tester).length, lessThanOrEqualTo(2));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ResponseViewerSheetMaterial(response: response)),
        ),
      );
      await tester.pumpAndSettle();

      final materialSwitches = find.byType(Switch);
      expect(materialSwitches, findsNWidgets(2));
      await tester.tap(materialSwitches.first);
      await tester.pumpAndSettle();

      expect(_horizontalScrollables(tester).length, lessThanOrEqualTo(3));
    },
  );

  testWidgets('Material response sheet open-close cycle is stable', (
    tester,
  ) async {
    final response = _testResponseWithBody(_veryLongBodyWithMatches());
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (ctx) => SizedBox(
                    height: MediaQuery.of(ctx).size.height * 0.85,
                    child: ResponseViewerSheetMaterial(response: response),
                  ),
                );
              },
              child: const Text('Open sheet'),
            ),
          ),
        ),
      ),
    );

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('Open sheet'));
      await tester.pumpAndSettle();
      expect(find.byType(ResponseViewerSheetMaterial), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(ResponseViewerSheetMaterial), findsNothing);
    }
  });
}
