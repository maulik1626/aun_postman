import 'package:aun_reqstudio/domain/models/http_response.dart';
import 'package:aun_reqstudio/features/response_viewer/response_viewer_sheet.dart';
import 'package:aun_reqstudio/features/response_viewer/response_viewer_sheet_material.dart';
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

ScrollableState _firstVerticalScrollableState(WidgetTester tester) {
  final vertical = find.byWidgetPredicate(
    (w) =>
        w is Scrollable &&
        (w.axisDirection == AxisDirection.down ||
            w.axisDirection == AxisDirection.up),
  );
  return tester.state<ScrollableState>(vertical.first);
}

void main() {
  testWidgets('Cupertino response find next scrolls and shows scrollbar',
      (tester) async {
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

    expect(find.text('1/3'), findsOneWidget);
    expect(find.byType(CupertinoScrollbar), findsWidgets);

    await tester.tap(find.byIcon(CupertinoIcons.chevron_down));
    await tester.pump();

    expect(find.text('2/3'), findsOneWidget);
  });

  testWidgets('Material response find next scrolls and shows scrollbar',
      (tester) async {
    final response = _testResponseWithBody(_longBodyWithMatches());

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ResponseViewerSheetMaterial(response: response),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField).first, 'target-word');
    await tester.pumpAndSettle();

    expect(find.text('1/3'), findsOneWidget);
    expect(find.byType(Scrollbar), findsWidgets);

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
  });

  testWidgets('Long response find next/prev jumps instantly on both platforms',
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
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(CupertinoIcons.chevron_down));
    await tester.pump();
    expect(find.text('2/3'), findsOneWidget);
    await tester.tap(find.byIcon(CupertinoIcons.chevron_up));
    await tester.pump();
    expect(find.text('1/3'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ResponseViewerSheetMaterial(response: response),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField).first, 'target-word');
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.keyboard_arrow_down));
    await tester.pump();
    expect(find.text('2/3'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.keyboard_arrow_up));
    await tester.pump();
    expect(find.text('1/3'), findsOneWidget);
  });
}
