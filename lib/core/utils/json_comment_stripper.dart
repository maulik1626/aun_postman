import 'dart:convert';

/// True if [input] has at least one whole-line `//` comment — the same lines
/// [stripJsonLineComments] would remove.
bool jsonHasLineComments(String input) {
  if (input.isEmpty) return false;
  for (final line in input.split(RegExp(r'\r?\n'))) {
    if (line.trimLeft().startsWith('//')) return true;
  }
  return false;
}

/// Removes whole-line `//` comments from a raw JSON editor string so the
/// remainder can be sent as strict JSON.
///
/// Lines whose first non-whitespace characters are `//` are dropped. Does not
/// strip trailing `//` on the same line as JSON.
String stripJsonLineComments(String input) {
  if (input.isEmpty) return input;
  final kept = <String>[];
  for (final line in input.split(RegExp(r'\r?\n'))) {
    if (line.trimLeft().startsWith('//')) continue;
    kept.add(line);
  }
  return kept.join('\n');
}

/// True when [raw] is empty/whitespace after line-comment strip + trim, or when
/// that remainder parses as JSON. Matches how the app sends and pretty-prints
/// raw JSON bodies.
bool isValidJsonBodyContent(String raw) {
  final t = stripJsonLineComments(raw).trim();
  if (t.isEmpty) return true;
  try {
    jsonDecode(t);
    return true;
  } catch (_) {
    return false;
  }
}
