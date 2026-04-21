import 'dart:convert';

import 'package:xml/xml.dart';

typedef PrettyFormatResult = ({String text, String language});

PrettyFormatResult runPrettyFormatJob(
  ({String raw, bool unwrapJson}) input,
) {
  final raw = input.raw;
  try {
    final decoded = jsonDecode(raw);
    return (
      text: input.unwrapJson
          ? const JsonEncoder().convert(decoded)
          : const JsonEncoder.withIndent('  ').convert(decoded),
      language: 'json',
    );
  } catch (_) {}

  try {
    final doc = XmlDocument.parse(raw);
    return (text: doc.toXmlString(pretty: true, indent: '  '), language: 'xml');
  } catch (_) {}

  return (text: raw, language: 'plaintext');
}
