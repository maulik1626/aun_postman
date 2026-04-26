import 'package:aun_reqstudio/features/request_builder/web/url_template_range.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('openBraceIndexForUnclosedTemplate', () {
    test('returns null when no template', () {
      expect(openBraceIndexForUnclosedTemplate('https://a.com', 10), isNull);
    });

    test('detects caret inside unclosed variable', () {
      expect(openBraceIndexForUnclosedTemplate('https://{{base', 12), 8);
      expect(openBraceIndexForUnclosedTemplate('{{', 2), 0);
    });

    test('returns null when variable already closed before caret', () {
      expect(
        openBraceIndexForUnclosedTemplate('https://{{x}}/y', 14),
        isNull,
      );
    });

    test('detects second unclosed variable', () {
      expect(
        openBraceIndexForUnclosedTemplate('{{a}}/{{b', 10),
        6,
      );
    });
  });

  group('matchingEnvKeysForUrlCaret', () {
    test('returns keys filtered by prefix', () {
      final keys = {'BASE', 'BASE_URL', 'OTHER'};
      expect(
        matchingEnvKeysForUrlCaret('x={{ba', 7, keys),
        ['BASE', 'BASE_URL'],
      );
    });

    test('returns empty when not in template', () {
      expect(
        matchingEnvKeysForUrlCaret('https://api.com', 10, {'A'}),
        isEmpty,
      );
    });
  });

  group('closedTemplateSpanAtTextOffset', () {
    test('returns span when offset is on inner key', () {
      const u = 'https://{{host}}/{{path}}';
      final a = closedTemplateSpanAtTextOffset(u, 12);
      expect(a, isNotNull);
      expect(a!.inner, 'host');
      expect(a.start, 8);
      expect(a.end, 16);
    });

    test('returns null when offset is outside templates', () {
      expect(closedTemplateSpanAtTextOffset('https://x.com', 5), isNull);
    });

    test('returns null when offset is past the token', () {
      const u = '{{a}}';
      expect(closedTemplateSpanAtTextOffset(u, 0), isNotNull);
      expect(closedTemplateSpanAtTextOffset(u, 5), isNull);
    });
  });

  group('applyEnvVariableSuggestion', () {
    test('closes incomplete template', () {
      final r = applyEnvVariableSuggestion('x={{ba', 7, 'BASE');
      expect(r.newText, 'x={{BASE}}');
      expect(r.newCaret, r.newText.length);
    });

    test('replaces inner when closing exists', () {
      final r = applyEnvVariableSuggestion('x={{old}}y', 6, 'NEW');
      expect(r.newText, 'x={{NEW}}y');
      expect(r.newCaret, 9);
    });
  });
}
