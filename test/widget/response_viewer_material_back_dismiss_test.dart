import 'package:aun_reqstudio/domain/models/http_response.dart';
import 'package:aun_reqstudio/features/response_viewer/response_viewer_sheet_material.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

HttpResponse _response() {
  const body = '{"ok":true,"message":"hello"}';
  return HttpResponse(
    statusCode: 200,
    statusMessage: 'OK',
    headers: const {'content-type': 'application/json'},
    body: body,
    durationMs: 20,
    sizeBytes: body.length,
    receivedAt: DateTime(2026, 4, 21),
  );
}

void main() {
  testWidgets('Android back dismisses response bottom sheet first', (tester) async {
    final response = _response();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () {
                  showModalBottomSheet<void>(
                    context: context,
                    useRootNavigator: true,
                    isScrollControlled: true,
                    builder: (ctx) => SizedBox(
                      height: MediaQuery.of(ctx).size.height * 0.85,
                      child: ResponseViewerSheetMaterial(response: response),
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.byType(ResponseViewerSheetMaterial), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(ResponseViewerSheetMaterial), findsNothing);
    expect(find.text('Open'), findsOneWidget);
  });
}
