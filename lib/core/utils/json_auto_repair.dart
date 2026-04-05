import 'dart:convert';

import 'package:aun_postman/core/utils/json_comment_stripper.dart';

/// True if [raw] may lose `//` or `/* */` content when [tryAutoRepairJson] runs.
bool jsonRepairMayRemoveComments(String raw) {
  if (jsonHasLineComments(raw) || raw.contains('/*')) return true;
  return _containsDoubleSlashCommentOutsideString(raw);
}

bool _containsDoubleSlashCommentOutsideString(String raw) {
  var i = 0;
  var inString = false;
  var escape = false;
  while (i + 1 < raw.length) {
    final c = raw[i];
    if (inString) {
      if (escape) {
        escape = false;
      } else if (c == r'\') {
        escape = true;
      } else if (c == '"') {
        inString = false;
      }
      i++;
      continue;
    }
    if (c == '"') {
      inString = true;
      i++;
      continue;
    }
    if (c == '/' && raw[i + 1] == '/') return true;
    i++;
  }
  return false;
}

/// Best-effort repair: UTF-8 BOM, `//` and `/* */` comments outside strings,
/// missing commas between object properties / array elements, trailing commas
/// before `}` or `]`, then pretty-print.
///
/// Returns `null` if the text is empty after cleanup or still not valid JSON.
String? tryAutoRepairJson(String raw) {
  var s = raw;
  if (s.isEmpty) return null;
  if (s.startsWith('\uFEFF')) {
    s = s.substring(1);
  }
  s = _removeBlockComments(s);
  s = _removeDoubleSlashCommentsOutsideStrings(s);
  s = s.trim();
  if (s.isEmpty) return null;

  Object? decoded;
  try {
    decoded = jsonDecode(s);
  } catch (_) {
    s = _insertMissingCommasRepeated(s);
    try {
      decoded = jsonDecode(s);
    } catch (_) {
      s = _removeTrailingCommasRepeated(s);
      try {
        decoded = jsonDecode(s);
      } catch (_) {
        s = _insertMissingCommasRepeated(s);
        try {
          decoded = jsonDecode(s);
        } catch (_) {
          return null;
        }
      }
    }
  }

  return const JsonEncoder.withIndent('  ').convert(decoded);
}

String _insertMissingCommasRepeated(String input) {
  var s = input;
  for (var n = 0; n < 16; n++) {
    final next = insertMissingCommasBetweenValues(s);
    if (next == s) break;
    s = next;
  }
  return s;
}

String _removeTrailingCommasRepeated(String input) {
  var s = input;
  for (var n = 0; n < 32; n++) {
    final next = _removeTrailingCommasOnce(s);
    if (next == s) break;
    s = next;
  }
  return s;
}

/// Removes a comma that sits directly before a closing `}` or `]` (outside
/// double-quoted strings, JSON rules).
String _removeTrailingCommasOnce(String input) {
  final buf = StringBuffer();
  var i = 0;
  var inString = false;
  var escape = false;

  while (i < input.length) {
    final c = input[i];
    if (inString) {
      buf.write(c);
      if (escape) {
        escape = false;
      } else if (c == r'\') {
        escape = true;
      } else if (c == '"') {
        inString = false;
      }
      i++;
      continue;
    }

    if (c == '"') {
      inString = true;
      buf.write(c);
      i++;
      continue;
    }

    if (c == ',') {
      var j = i + 1;
      while (j < input.length && _isJsonWhitespace(input.codeUnitAt(j))) {
        j++;
      }
      if (j < input.length && (input[j] == '}' || input[j] == ']')) {
        i++;
        continue;
      }
    }

    buf.write(c);
    i++;
  }
  return buf.toString();
}

bool _isJsonWhitespace(int u) =>
    u == 0x20 || u == 0x09 || u == 0x0A || u == 0x0D;

/// Removes `// …` through end of line when outside double-quoted strings.
String _removeDoubleSlashCommentsOutsideStrings(String input) {
  final buf = StringBuffer();
  var i = 0;
  var inString = false;
  var escape = false;

  while (i < input.length) {
    final c = input[i];
    if (inString) {
      buf.write(c);
      if (escape) {
        escape = false;
      } else if (c == r'\') {
        escape = true;
      } else if (c == '"') {
        inString = false;
      }
      i++;
      continue;
    }

    if (c == '"') {
      inString = true;
      buf.write(c);
      i++;
      continue;
    }

    if (c == '/' && i + 1 < input.length && input[i + 1] == '/') {
      while (i < input.length && input[i] != '\n' && input[i] != '\r') {
        i++;
      }
      continue;
    }

    buf.write(c);
    i++;
  }
  return buf.toString();
}

/// Removes `/* ... */` outside double-quoted strings (no nesting).
String _removeBlockComments(String input) {
  final buf = StringBuffer();
  var i = 0;
  var inString = false;
  var escape = false;

  while (i < input.length) {
    final c = input[i];
    if (inString) {
      buf.write(c);
      if (escape) {
        escape = false;
      } else if (c == r'\') {
        escape = true;
      } else if (c == '"') {
        inString = false;
      }
      i++;
      continue;
    }

    if (c == '"') {
      inString = true;
      buf.write(c);
      i++;
      continue;
    }

    if (c == '/' && i + 1 < input.length && input[i + 1] == '*') {
      i += 2;
      while (i + 1 < input.length) {
        if (input[i] == '*' && input[i + 1] == '/') {
          i += 2;
          break;
        }
        i++;
      }
      continue;
    }

    buf.write(c);
    i++;
  }
  return buf.toString();
}

class _CommaFrame {
  _CommaFrame(this.isObject);
  final bool isObject;
  bool commaAfterValue = false;
}

/// Inserts missing commas between object properties and between array elements
/// (outside double-quoted strings). Safe for standard JSON text; best-effort
/// for broken JSON the user is editing.
String insertMissingCommasBetweenValues(String input) =>
    _MissingCommaInserter(input).run();

class _MissingCommaInserter {
  _MissingCommaInserter(this.input);

  final String input;
  final StringBuffer out = StringBuffer();
  final List<_CommaFrame> frames = [];
  int i = 0;

  String run() {
    skipWsCopy();
    if (i < input.length && input[i] == '{') {
      parseObject();
    } else if (i < input.length && input[i] == '[') {
      parseArray();
    } else {
      parseValue();
    }
    while (i < input.length) {
      out.write(input[i]);
      i++;
    }
    return out.toString();
  }

  bool startsJsonValue(String s, int j) {
    if (j >= s.length) return false;
    final u = s.codeUnitAt(j);
    if (u == 0x22 || u == 0x7B || u == 0x5B) return true;
    if (u == 0x2D || (u >= 0x30 && u <= 0x39)) return true;
    if (s.startsWith('true', j)) return true;
    if (s.startsWith('false', j)) return true;
    if (s.startsWith('null', j)) return true;
    return false;
  }

  void skipWsCopy() {
    while (i < input.length && _isJsonWhitespace(input.codeUnitAt(i))) {
      out.write(input[i]);
      i++;
    }
  }

  void ensureCommaBeforeNext() {
    if (frames.isEmpty) return;
    final f = frames.last;
    if (!f.commaAfterValue) return;
    var j = i;
    while (j < input.length && _isJsonWhitespace(input.codeUnitAt(j))) {
      j++;
    }
    if (j >= input.length) return;
    final c = input[j];
    if (c == ',') {
      f.commaAfterValue = false;
      return;
    }
    if (c == '}' || c == ']') {
      f.commaAfterValue = false;
      return;
    }
    var insert = false;
    if (f.isObject && c == '"') {
      insert = true;
    } else if (!f.isObject && startsJsonValue(input, j)) {
      insert = true;
    } else if (f.isObject && startsJsonValue(input, j)) {
      insert = true;
    }
    if (!insert) return;
    while (i < j) {
      out.write(input[i]);
      i++;
    }
    out.write(',');
    f.commaAfterValue = false;
  }

  void parseString() {
    out.write(input[i]);
    i++;
    while (i < input.length) {
      final c = input[i];
      out.write(c);
      if (c == r'\') {
        i++;
        if (i < input.length) {
          out.write(input[i]);
          i++;
        }
        continue;
      }
      if (c == '"') {
        i++;
        break;
      }
      i++;
    }
  }

  void parseNumberOrLiteral() {
    if (input.startsWith('true', i)) {
      out.write('true');
      i += 4;
      return;
    }
    if (input.startsWith('false', i)) {
      out.write('false');
      i += 5;
      return;
    }
    if (input.startsWith('null', i)) {
      out.write('null');
      i += 4;
      return;
    }
    if (i < input.length &&
        (input[i] == '-' ||
            (input.codeUnitAt(i) >= 0x30 && input.codeUnitAt(i) <= 0x39))) {
      out.write(input[i]);
      i++;
      while (i < input.length) {
        final u = input.codeUnitAt(i);
        if ((u >= 0x30 && u <= 0x39) ||
            u == 0x2E ||
            u == 0x45 ||
            u == 0x65 ||
            u == 0x2B ||
            u == 0x2D) {
          out.write(input[i]);
          i++;
        } else {
          break;
        }
      }
    }
  }

  void parseValue() {
    skipWsCopy();
    ensureCommaBeforeNext();
    skipWsCopy();
    if (i >= input.length) return;
    final c = input[i];
    if (c == '"') {
      parseString();
      if (frames.isNotEmpty) {
        frames.last.commaAfterValue = true;
      }
      return;
    }
    if (c == '{') {
      parseObject();
      if (frames.isNotEmpty) {
        frames.last.commaAfterValue = true;
      }
      return;
    }
    if (c == '[') {
      parseArray();
      if (frames.isNotEmpty) {
        frames.last.commaAfterValue = true;
      }
      return;
    }
    parseNumberOrLiteral();
    if (frames.isNotEmpty) {
      frames.last.commaAfterValue = true;
    }
  }

  void parseObject() {
    out.write('{');
    i++;
    frames.add(_CommaFrame(true));
    skipWsCopy();
    if (i < input.length && input[i] == '}') {
      out.write('}');
      i++;
      frames.removeLast();
      return;
    }
    while (i < input.length) {
      skipWsCopy();
      ensureCommaBeforeNext();
      skipWsCopy();
      if (i >= input.length) break;
      if (input[i] == '}') {
        out.write('}');
        i++;
        frames.removeLast();
        return;
      }
      if (input[i] != '"') {
        out.write(input[i]);
        i++;
        continue;
      }
      parseString();
      skipWsCopy();
      if (i < input.length && input[i] == ':') {
        out.write(':');
        i++;
      }
      parseValue();
      skipWsCopy();
      if (i < input.length && input[i] == '}') {
        out.write('}');
        i++;
        frames.removeLast();
        return;
      }
      if (i < input.length && input[i] == ',') {
        out.write(',');
        i++;
        frames.last.commaAfterValue = false;
        continue;
      }
    }
    if (frames.isNotEmpty && frames.last.isObject) {
      frames.removeLast();
    }
  }

  void parseArray() {
    out.write('[');
    i++;
    frames.add(_CommaFrame(false));
    skipWsCopy();
    if (i < input.length && input[i] == ']') {
      out.write(']');
      i++;
      frames.removeLast();
      return;
    }
    while (i < input.length) {
      skipWsCopy();
      ensureCommaBeforeNext();
      skipWsCopy();
      if (i >= input.length) break;
      if (input[i] == ']') {
        out.write(']');
        i++;
        frames.removeLast();
        return;
      }
      parseValue();
      skipWsCopy();
      if (i < input.length && input[i] == ']') {
        out.write(']');
        i++;
        frames.removeLast();
        return;
      }
      if (i < input.length && input[i] == ',') {
        out.write(',');
        i++;
        frames.last.commaAfterValue = false;
        continue;
      }
    }
    if (frames.isNotEmpty && !frames.last.isObject) {
      frames.removeLast();
    }
  }
}
