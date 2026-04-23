/// File extension (no dot) and MIME type for sharing HTTP response bodies.
class ResponseBodyShareSpec {
  const ResponseBodyShareSpec({
    required this.extension,
    required this.mimeType,
  });

  final String extension;
  final String mimeType;
}

/// Matches response viewer body labeling: JSON / HTML / XML / TEXT.
String detectResponseBodyKind(
  String body,
  Map<String, String> headers, {
  required bool prettyBodyIsJson,
}) {
  if (prettyBodyIsJson) return 'JSON';
  final trimmed = body.trimLeft();
  if (trimmed.startsWith('<!DOCTYPE html') || trimmed.startsWith('<html')) {
    return 'HTML';
  }
  if (trimmed.startsWith('<')) {
    return 'XML';
  }
  final ct = headers['content-type'] ?? headers['Content-Type'] ?? '';
  final ctl = ct.toLowerCase();
  if (ctl.contains('json')) return 'JSON';
  if (ctl.contains('xml')) return 'XML';
  if (ctl.contains('html')) return 'HTML';
  return 'TEXT';
}

/// Primary media type from [headers], lowercased, without parameters.
String? primaryResponseMediaType(Map<String, String> headers) {
  final raw = headers['content-type'] ??
      headers['Content-Type'] ??
      headers['CONTENT-TYPE'] ??
      '';
  if (raw.isEmpty) return null;
  final cut = raw.split(';').first.trim().toLowerCase();
  return cut.isEmpty ? null : cut;
}

/// Resolves share filename extension and `XFile` MIME from body + headers.
ResponseBodyShareSpec responseBodyShareSpec({
  required String body,
  required Map<String, String> headers,
  required bool prettyBodyIsJson,
}) {
  final kind = detectResponseBodyKind(
    body,
    headers,
    prettyBodyIsJson: prettyBodyIsJson,
  );
  final mt = primaryResponseMediaType(headers);

  switch (kind) {
    case 'JSON':
      if (mt != null &&
          mt != 'application/json' &&
          mt.contains('json')) {
        return ResponseBodyShareSpec(extension: 'json', mimeType: mt);
      }
      return const ResponseBodyShareSpec(
        extension: 'json',
        mimeType: 'application/json',
      );
    case 'HTML':
      return const ResponseBodyShareSpec(
        extension: 'html',
        mimeType: 'text/html',
      );
    case 'XML':
      return _specForXmlFamily(mt);
    default:
      return _specForPlainOrUnknown(mt);
  }
}

ResponseBodyShareSpec _specForXmlFamily(String? mt) {
  if (mt != null) {
    switch (mt) {
      case 'image/svg+xml':
        return const ResponseBodyShareSpec(
          extension: 'svg',
          mimeType: 'image/svg+xml',
        );
      case 'application/xhtml+xml':
        return const ResponseBodyShareSpec(
          extension: 'xhtml',
          mimeType: 'application/xhtml+xml',
        );
      case 'application/rss+xml':
      case 'application/atom+xml':
        return ResponseBodyShareSpec(extension: 'xml', mimeType: mt);
      default:
        if (mt.endsWith('+xml') && mt != 'application/xhtml+xml') {
          return ResponseBodyShareSpec(extension: 'xml', mimeType: mt);
        }
    }
  }
  return const ResponseBodyShareSpec(
    extension: 'xml',
    mimeType: 'application/xml',
  );
}

ResponseBodyShareSpec _specForPlainOrUnknown(String? mt) {
  if (mt == null || mt.isEmpty) {
    return const ResponseBodyShareSpec(
      extension: 'txt',
      mimeType: 'text/plain',
    );
  }

  switch (mt) {
    case 'application/json':
    case 'text/json':
      return const ResponseBodyShareSpec(
        extension: 'json',
        mimeType: 'application/json',
      );
    case 'text/html':
      return const ResponseBodyShareSpec(
        extension: 'html',
        mimeType: 'text/html',
      );
    case 'application/xml':
    case 'text/xml':
      return const ResponseBodyShareSpec(
        extension: 'xml',
        mimeType: 'application/xml',
      );
    case 'text/plain':
      return const ResponseBodyShareSpec(
        extension: 'txt',
        mimeType: 'text/plain',
      );
    case 'text/css':
      return const ResponseBodyShareSpec(extension: 'css', mimeType: 'text/css');
    case 'text/javascript':
    case 'application/javascript':
    case 'application/ecmascript':
    case 'text/ecmascript':
      return const ResponseBodyShareSpec(
        extension: 'js',
        mimeType: 'application/javascript',
      );
    case 'text/csv':
      return const ResponseBodyShareSpec(extension: 'csv', mimeType: 'text/csv');
    case 'text/tab-separated-values':
      return ResponseBodyShareSpec(extension: 'tsv', mimeType: mt);
    case 'text/markdown':
    case 'text/x-markdown':
      return const ResponseBodyShareSpec(
        extension: 'md',
        mimeType: 'text/markdown',
      );
    case 'application/yaml':
    case 'application/x-yaml':
    case 'text/yaml':
    case 'text/x-yaml':
      return const ResponseBodyShareSpec(
        extension: 'yaml',
        mimeType: 'application/yaml',
      );
    case 'application/sql':
    case 'application/x-sql':
      return ResponseBodyShareSpec(extension: 'sql', mimeType: mt);
    case 'application/graphql':
      return const ResponseBodyShareSpec(
        extension: 'graphql',
        mimeType: 'application/graphql',
      );
    case 'application/protobuf':
    case 'application/x-protobuf':
      return ResponseBodyShareSpec(extension: 'pb', mimeType: mt);
    case 'application/octet-stream':
      return const ResponseBodyShareSpec(
        extension: 'bin',
        mimeType: 'application/octet-stream',
      );
    case 'text/event-stream':
      return const ResponseBodyShareSpec(
        extension: 'txt',
        mimeType: 'text/event-stream',
      );
    default:
      break;
  }

  if (mt.startsWith('application/')) {
    final sub = mt.substring('application/'.length);
    if (sub.endsWith('+json') || sub == 'json') {
      return ResponseBodyShareSpec(extension: 'json', mimeType: mt);
    }
    if (sub.endsWith('+xml')) {
      return ResponseBodyShareSpec(extension: 'xml', mimeType: mt);
    }
  }

  if (mt.startsWith('text/')) {
    final sub = mt.substring('text/'.length);
    if (sub.isNotEmpty && sub != 'plain') {
      final ext = _sanitizeSubtypeAsExtension(sub);
      if (ext != null) {
        return ResponseBodyShareSpec(extension: ext, mimeType: mt);
      }
    }
  }

  if (mt.contains('/')) {
    final sub = mt.split('/').last;
    final ext = _sanitizeSubtypeAsExtension(sub);
    if (ext != null && ext.length <= 24) {
      return ResponseBodyShareSpec(extension: ext, mimeType: mt);
    }
  }

  return const ResponseBodyShareSpec(
    extension: 'txt',
    mimeType: 'text/plain',
  );
}

String? _sanitizeSubtypeAsExtension(String raw) {
  final cleaned = raw
      .split('+')
      .first
      .split('.')
      .last
      .replaceAll(RegExp(r'[^a-z0-9_-]'), '');
  if (cleaned.isEmpty || cleaned.length > 32) return null;
  return cleaned;
}
