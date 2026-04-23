import 'package:aun_reqstudio/features/response_viewer/core/response_body_share_spec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('detectResponseBodyKind', () {
    test('pretty JSON flag wins', () {
      expect(
        detectResponseBodyKind(
          'not json',
          {'content-type': 'text/plain'},
          prettyBodyIsJson: true,
        ),
        'JSON',
      );
    });

    test('DOCTYPE html', () {
      expect(
        detectResponseBodyKind(
          '<!DOCTYPE html><html></html>',
          {},
          prettyBodyIsJson: false,
        ),
        'HTML',
      );
    });

    test('content-type json', () {
      expect(
        detectResponseBodyKind(
          'plain',
          {'content-type': 'application/json; charset=utf-8'},
          prettyBodyIsJson: false,
        ),
        'JSON',
      );
    });
  });

  group('responseBodyShareSpec', () {
    test('JSON body uses json extension', () {
      final spec = responseBodyShareSpec(
        body: '{"a":1}',
        headers: {'content-type': 'application/json'},
        prettyBodyIsJson: true,
      );
      expect(spec.extension, 'json');
      expect(spec.mimeType, 'application/json');
    });

    test('HTML body uses html extension', () {
      final spec = responseBodyShareSpec(
        body: '<html><body>x</body></html>',
        headers: {},
        prettyBodyIsJson: false,
      );
      expect(spec.extension, 'html');
      expect(spec.mimeType, 'text/html');
    });

    test('XML body uses xml extension', () {
      final spec = responseBodyShareSpec(
        body: '<root/>',
        headers: {},
        prettyBodyIsJson: false,
      );
      expect(spec.extension, 'xml');
      expect(spec.mimeType, 'application/xml');
    });

    test('SVG uses svg when content-type declares it', () {
      final spec = responseBodyShareSpec(
        body: '<svg xmlns="http://www.w3.org/2000/svg"/>',
        headers: {'content-type': 'image/svg+xml'},
        prettyBodyIsJson: false,
      );
      expect(spec.extension, 'svg');
      expect(spec.mimeType, 'image/svg+xml');
    });

    test('TEXT + yaml content-type', () {
      final spec = responseBodyShareSpec(
        body: 'a: 1',
        headers: {'content-type': 'application/yaml'},
        prettyBodyIsJson: false,
      );
      expect(spec.extension, 'yaml');
      expect(spec.mimeType, 'application/yaml');
    });

    test('TEXT + hal+json', () {
      final spec = responseBodyShareSpec(
        body: '{}',
        headers: {'content-type': 'application/hal+json'},
        prettyBodyIsJson: false,
      );
      expect(spec.extension, 'json');
      expect(spec.mimeType, 'application/hal+json');
    });

    test('unknown text subtype becomes sanitized extension', () {
      final spec = responseBodyShareSpec(
        body: 'x',
        headers: {'content-type': 'text/vnd.custom-thing'},
        prettyBodyIsJson: false,
      );
      expect(spec.extension, 'custom-thing');
      expect(spec.mimeType, 'text/vnd.custom-thing');
    });

    test('empty body and headers falls back to txt', () {
      final spec = responseBodyShareSpec(
        body: '',
        headers: {},
        prettyBodyIsJson: false,
      );
      expect(spec.extension, 'txt');
      expect(spec.mimeType, 'text/plain');
    });
  });
}
