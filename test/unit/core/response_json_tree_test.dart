import 'package:aun_reqstudio/features/response_viewer/core/response_json_tree.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('json tree presentation expands matching nested branch for search', () {
    final root = buildResponseJsonTree({
      'outer': {
        'inner': {'target': 'needle'},
      },
    });

    final initial = buildResponseJsonTreePresentation(
      root: root,
      expansionOverrides: const {},
      query: '',
    );
    expect(
      initial.entries.any((entry) => entry.searchText.contains('needle')),
      isFalse,
    );

    final searched = buildResponseJsonTreePresentation(
      root: root,
      expansionOverrides: const {},
      query: 'needle',
    );
    expect(
      searched.entries.any((entry) => entry.searchText.contains('needle')),
      isTrue,
    );
    expect(searched.matches.length, 1);
  });
}
