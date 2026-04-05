/// Derives a short request title from a URL or partial endpoint string.
///
/// `{{variable}}` placeholders are removed so titles are stable and readable.
String suggestRequestNameFromUrl(String raw) {
  var s = _stripVariablePlaceholders(raw.trim());
  if (s.isEmpty) return 'New Request';

  final noFragment = s.split('#').first.trim();
  final withoutQuery = noFragment.split('?').first.trim();
  if (withoutQuery.isEmpty) return 'New Request';

  Uri? uri = Uri.tryParse(withoutQuery);
  if (uri == null) {
    uri = Uri.tryParse('https://$withoutQuery');
  } else if (uri.host.isEmpty && uri.scheme.isEmpty) {
    // Relative `/path` or `api.test/foo` — same as legacy behaviour
    uri = Uri.tryParse('https://$withoutQuery');
  }

  if (uri == null) return _truncate(withoutQuery, 64);

  var host = _stripVariablePlaceholders(uri.host);
  while (host.startsWith('.')) {
    host = host.substring(1);
  }

  final path = _normalizePathWithVarsStripped(uri.path);

  if (host.isNotEmpty) {
    if (path.isEmpty) {
      return _truncate(host, 64);
    }
    return _truncate('$host$path', 64);
  }

  if (path.isNotEmpty) {
    var p = path.startsWith('/') ? path.substring(1) : path;
    if (p.endsWith('/')) p = p.substring(0, p.length - 1);
    if (p.isEmpty) return 'New Request';
    return _truncate(p, 64);
  }

  return _truncate(withoutQuery, 64);
}

/// Removes `{{var}}` segments (same family as [VariableInterpolator]).
String _stripVariablePlaceholders(String input) {
  return input.replaceAll(RegExp(r'\{\{\s*[^}]+\s*\}\}'), '');
}

/// Drops empty path segments (e.g. `//` after removing a `{{var}}` in the middle).
String _normalizePathWithVarsStripped(String path) {
  final parts = path
      .split('/')
      .map(_stripVariablePlaceholders)
      .map((p) => p.trim())
      .where((p) => p.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '';
  return '/${parts.join('/')}';
}

String _truncate(String value, int maxChars) {
  if (value.length <= maxChars) return value;
  return '${value.substring(0, maxChars - 1)}…';
}
