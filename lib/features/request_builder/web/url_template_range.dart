// Helpers for `{{variable}}` templates in request URLs (web URL bar).

/// A complete `{{name}}` span in a URL string (closed template).
class UrlVariableTemplateSpan {
  const UrlVariableTemplateSpan({
    required this.start,
    required this.end,
    required this.inner,
  });

  /// Inclusive start index of `{{` in the host string.
  final int start;

  /// Exclusive end index after `}}` in the host string.
  final int end;

  /// Trimmed variable key inside the braces.
  final String inner;
}

/// Returns the closed `{{…}}` template under [offset] (half-open `[start,end)`),
/// or `null` if [offset] is not inside a closed template token.
UrlVariableTemplateSpan? closedTemplateSpanAtTextOffset(
  String text,
  int offset,
) {
  final bounded = offset.clamp(0, text.length);
  final re = RegExp(r'\{\{([^}]+)\}\}');
  for (final m in re.allMatches(text)) {
    if (bounded >= m.start && bounded < m.end) {
      return UrlVariableTemplateSpan(
        start: m.start,
        end: m.end,
        inner: m.group(1)!.trim(),
      );
    }
  }
  return null;
}

/// Index of the opening `{{` for an **unclosed** template whose inner span
/// reaches [caret], or `null` if the caret is not editing inside such a span.
int? openBraceIndexForUnclosedTemplate(String text, int caret) {
  if (caret < 0) return null;
  final bounded = caret.clamp(0, text.length);
  final head = text.substring(0, bounded);
  final open = head.lastIndexOf('{{');
  if (open == -1) return null;
  final afterOpen = head.substring(open + 2);
  if (afterOpen.contains('}}')) return null;
  return open;
}

/// Environment keys to offer while the caret is inside an unclosed `{{`.
List<String> matchingEnvKeysForUrlCaret(
  String text,
  int caret,
  Set<String> enabledKeys, {
  int limit = 20,
}) {
  if (enabledKeys.isEmpty) return const [];
  final open = openBraceIndexForUnclosedTemplate(text, caret);
  if (open == null) return const [];
  final innerStart = open + 2;
  final prefix = text
      .substring(innerStart, caret.clamp(innerStart, text.length))
      .trimLeft()
      .toLowerCase();

  final matches = enabledKeys.where((k) {
    if (prefix.isEmpty) return true;
    final kl = k.toLowerCase();
    return kl.startsWith(prefix) || kl.contains(prefix);
  }).toList()
    ..sort((a, b) {
      final al = a.toLowerCase();
      final bl = b.toLowerCase();
      final aStarts = prefix.isNotEmpty && al.startsWith(prefix);
      final bStarts = prefix.isNotEmpty && bl.startsWith(prefix);
      if (aStarts != bStarts) return aStarts ? -1 : 1;
      return al.compareTo(bl);
    });
  return matches.take(limit).toList();
}

/// Replaces the partial variable being edited with [key], preserving a
/// trailing `}}` when it already exists.
({String newText, int newCaret}) applyEnvVariableSuggestion(
  String text,
  int caret,
  String key,
) {
  final open = openBraceIndexForUnclosedTemplate(text, caret);
  if (open == null) {
    return (newText: text, newCaret: caret.clamp(0, text.length));
  }
  final innerStart = open + 2;
  final closeIdx = text.indexOf('}}', innerStart);
  final boundedCaret = caret.clamp(innerStart, text.length);

  if (closeIdx != -1) {
    final nt = text.replaceRange(innerStart, closeIdx, key);
    final newCaret = (innerStart + key.length + 2).clamp(0, nt.length);
    return (newText: nt, newCaret: newCaret);
  }

  final nt = text.replaceRange(innerStart, boundedCaret, '$key}}');
  final newCaret = (innerStart + key.length + 2).clamp(0, nt.length);
  return (newText: nt, newCaret: newCaret);
}
