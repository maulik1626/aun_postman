import 'browser_json_export_stub.dart'
    if (dart.library.html) 'browser_json_export_web.dart' as impl;

String safeJsonFileName(String value) {
  final safe = value
      .replaceAll(RegExp(r'[^\w\s.-]'), '_')
      .replaceAll(RegExp(r'\s+'), '_')
      .trim();
  return safe.isEmpty ? 'export' : safe;
}

void downloadJsonFile({required String fileName, required String content}) {
  impl.downloadJsonFileImpl(fileName: fileName, content: content);
}

Future<void> copyJsonToClipboard(String content) {
  return impl.copyJsonToClipboardImpl(content);
}
