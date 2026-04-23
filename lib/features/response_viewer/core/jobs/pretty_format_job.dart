import 'dart:convert';

import 'package:xml/xml.dart';

typedef PrettyFormatResult = ({String text, String language});

PrettyFormatResult runPrettyFormatJob(({String raw, bool unwrapJson}) input) {
  final raw = input.raw;
  try {
    if (input.unwrapJson) {
      return (text: _minifyJson(raw), language: 'json');
    }
    final decoded = jsonDecode(raw);
    return (
      text: const JsonEncoder.withIndent('  ').convert(decoded),
      language: 'json',
    );
  } catch (_) {}

  try {
    final doc = XmlDocument.parse(raw);
    return (text: doc.toXmlString(pretty: true, indent: '  '), language: 'xml');
  } catch (_) {}

  return (text: raw, language: 'plaintext');
}

String _minifyJson(String input) {
  if (input.isEmpty) return input;

  final out = StringBuffer();
  var inString = false;
  var escaping = false;
  var sawContent = false;

  for (var i = 0; i < input.length; i++) {
    final char = input[i];

    if (inString) {
      out.write(char);
      if (escaping) {
        escaping = false;
      } else if (char == r'\') {
        escaping = true;
      } else if (char == '"') {
        inString = false;
      }
      sawContent = true;
      continue;
    }

    switch (char) {
      case ' ':
      case '\n':
      case '\r':
      case '\t':
        continue;
      case '"':
        inString = true;
        out.write(char);
        sawContent = true;
      default:
        out.write(char);
        sawContent = true;
    }
  }

  if (inString || !sawContent) {
    final decoded = jsonDecode(input);
    return const JsonEncoder().convert(decoded);
  }

  return out.toString();
}
