import 'package:aun_reqstudio/features/request_builder/widgets/pre_request_variables_outcome.dart';
import 'package:aun_reqstudio/features/request_builder/widgets/pre_request_variables_sheet.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'Cupertino pre-request sheet matches bulk CTAs and Clear in title',
    (tester) async {
      PreRequestVariablesOutcome? last;

      await tester.pumpWidget(
        CupertinoApp(
          home: Builder(
            builder: (ctx) => CupertinoPageScaffold(
              child: Center(
                child: CupertinoButton(
                  onPressed: () async {
                    last = await showPreRequestVariablesSheetCupertino(
                      ctx,
                      initialLines: 'x:1',
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Pre-request variables'), findsOneWidget);
      expect(find.text('Clear'), findsOneWidget);
      expect(find.text('Apply'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      final field = find.byWidgetPredicate(
        (w) =>
            w is CupertinoTextField &&
            w.placeholder == 'baseUrl=https://api.example.com',
      );
      expect(field, findsOneWidget);

      await tester.enterText(field, 'a:2\nb\t3');
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      expect(last, isA<PreRequestVariablesApplied>());
      expect((last! as PreRequestVariablesApplied).linesText, contains('a:2'));
    },
  );

  testWidgets('Cupertino Clear returns cleared outcome', (tester) async {
    PreRequestVariablesOutcome? last;

    await tester.pumpWidget(
      CupertinoApp(
        home: Builder(
          builder: (ctx) => CupertinoPageScaffold(
            child: Center(
              child: CupertinoButton(
                onPressed: () async {
                  last = await showPreRequestVariablesSheetCupertino(
                    ctx,
                    initialLines: 'k:v',
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();

    expect(last, isA<PreRequestVariablesCleared>());
  });
}
