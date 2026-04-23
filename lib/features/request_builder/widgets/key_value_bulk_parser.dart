import 'dart:convert';

typedef KeyValueDraft = ({String key, String value, bool isEnabled});

List<KeyValueDraft> parseBulkKeyValueRows(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return const [(key: '', value: '', isEnabled: true)];
  }

  final jsonRows = _tryParseJsonRows(trimmed);
  if (jsonRows != null) {
    return jsonRows.isEmpty
        ? const [(key: '', value: '', isEnabled: true)]
        : jsonRows;
  }

  final parsed = <KeyValueDraft>[];
  for (final line in raw.split('\n')) {
    final entry = _parseLine(line);
    if (entry != null) {
      parsed.add(entry);
    }
  }

  return parsed.isEmpty
      ? const [(key: '', value: '', isEnabled: true)]
      : parsed;
}

String bulkKeyValueRowsToText(Iterable<KeyValueDraft> rows) {
  return rows
      .where((row) => row.key.trim().isNotEmpty || row.value.trim().isNotEmpty)
      .map((row) => '${row.key}:${row.value}')
      .join('\n');
}

KeyValueDraft? _parseLine(String rawLine) {
  final trimmed = rawLine.trim();
  if (trimmed.isEmpty) {
    return null;
  }

  final tabIndex = trimmed.indexOf('\t');
  final colonIndex = trimmed.indexOf(':');
  final eqIndex = trimmed.indexOf('=');

  var splitAt = -1;
  if (tabIndex > 0) {
    splitAt = tabIndex;
  } else if (colonIndex > 0 && (eqIndex <= 0 || colonIndex < eqIndex)) {
    splitAt = colonIndex;
  } else if (eqIndex > 0) {
    splitAt = eqIndex;
  }

  if (splitAt <= 0) {
    return (key: trimmed, value: '', isEnabled: true);
  }

  return (
    key: trimmed.substring(0, splitAt).trim(),
    value: trimmed.substring(splitAt + 1).trim(),
    isEnabled: true,
  );
}

List<KeyValueDraft>? _tryParseJsonRows(String trimmed) {
  final startsLikeJson =
      trimmed.startsWith('{') ||
      trimmed.startsWith('[') ||
      trimmed.startsWith('"');
  if (!startsLikeJson) {
    return null;
  }

  dynamic decoded;
  try {
    decoded = jsonDecode(trimmed);
  } on FormatException {
    return null;
  }

  if (decoded is! Map && decoded is! List) {
    return null;
  }

  final rows = <KeyValueDraft>[];
  _flattenJsonValue(decoded, '', rows);
  return rows;
}

void _flattenJsonValue(dynamic value, String path, List<KeyValueDraft> rows) {
  if (value is Map) {
    if (value.isEmpty) {
      if (path.isNotEmpty) {
        rows.add((key: path, value: '{}', isEnabled: true));
      }
      return;
    }

    value.forEach((dynamic key, dynamic nestedValue) {
      final keyPart = key.toString();
      final nextPath = path.isEmpty ? keyPart : '$path.$keyPart';
      _flattenJsonValue(nestedValue, nextPath, rows);
    });
    return;
  }

  if (value is List) {
    if (value.isEmpty) {
      if (path.isNotEmpty) {
        rows.add((key: path, value: '[]', isEnabled: true));
      }
      return;
    }

    for (var i = 0; i < value.length; i++) {
      final nextPath = path.isEmpty ? '[$i]' : '$path[$i]';
      _flattenJsonValue(value[i], nextPath, rows);
    }
    return;
  }

  if (path.isEmpty) {
    return;
  }

  rows.add((key: path, value: _stringifyJsonLeaf(value), isEnabled: true));
}

String _stringifyJsonLeaf(dynamic value) {
  if (value == null) {
    return 'null';
  }
  if (value is String) {
    return value;
  }
  if (value is num || value is bool) {
    return value.toString();
  }

  return jsonEncode(value);
}
