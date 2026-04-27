import 'dart:convert';
import 'dart:html' as html;

import 'package:flutter/services.dart';

void downloadJsonFileImpl({required String fileName, required String content}) {
  final bytes = utf8.encode(content);
  final blob = html.Blob([bytes], 'application/json');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..style.display = 'none'
    ..download = fileName;
  html.document.body?.children.add(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
}

Future<void> copyJsonToClipboardImpl(String content) {
  return Clipboard.setData(ClipboardData(text: content));
}
