import 'package:aun_reqstudio/features/response_viewer/core/response_processing_controller.dart';
import 'package:aun_reqstudio/features/response_viewer/core/response_viewer_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('computePretty transitions from loading to ready', () async {
    final controller = ResponseProcessingController();

    final result = await controller.computePretty(
      raw: '{"name":"aun"}',
      unwrapJson: false,
    );

    expect(result.language, 'json');
    expect(result.text.contains('\n'), isTrue);
    expect(controller.prettyState, ResponsePrettyState.ready);
  });

  test('computeSearchMatches returns match positions', () async {
    final controller = ResponseProcessingController();
    final body = 'line one\\nline two target\\nline three target';

    final matches = await controller.computeSearchMatches(
      text: body,
      query: 'target',
    );

    expect(matches, isNotEmpty);
    expect(matches.first, isA<SearchMatch>());
    expect(controller.searchState, ResponseSearchState.ready);
  });
}
