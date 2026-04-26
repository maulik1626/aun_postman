import 'package:aun_reqstudio/features/request_builder/web/web_request_url_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WebRequestUrlField overlay metrics', () {
    test(
      'highlight span tree measures like uniform mono text (caret stays on glyphs)',
      () {
        const text = '{{staging}}/authentication/send_otp/';
        final scheme = ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        );
        final base = webRequestUrlFieldBaseTextStyle(scheme.onSurface);
        final strut = webRequestUrlFieldStrutStyle();
        final uniform = TextPainter(
          text: TextSpan(text: text, style: base),
          textDirection: TextDirection.ltr,
          strutStyle: strut,
        )..layout();
        final rich = TextPainter(
          text: buildWebRequestUrlFieldOverlaySpanForTest(
            text: text,
            scheme: scheme,
            definedEnvKeys: const {'staging'},
          ),
          textDirection: TextDirection.ltr,
          strutStyle: strut,
        )..layout();
        expect((uniform.width - rich.width).abs(), lessThan(1.5));
      },
    );
  });
}
