import 'package:flutter/services.dart';

void downloadJsonFileImpl({required String fileName, required String content}) {
  // Non-web platforms cannot trigger a browser download.
}

Future<void> copyJsonToClipboardImpl(String content) {
  return Clipboard.setData(ClipboardData(text: content));
}
