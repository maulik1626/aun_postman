import 'dart:convert';
import 'dart:typed_data';

/// Parses hex strings (with optional whitespace) into bytes. Returns null if invalid.
Uint8List? tryDecodeHex(String input) {
  final cleaned = input.replaceAll(RegExp(r'\s'), '');
  if (cleaned.isEmpty || cleaned.length.isOdd) return null;
  if (!RegExp(r'^[0-9a-fA-F]+$').hasMatch(cleaned)) return null;
  final out = Uint8List(cleaned.length ~/ 2);
  for (var i = 0; i < cleaned.length; i += 2) {
    out[i ~/ 2] = int.parse(cleaned.substring(i, i + 2), radix: 16);
  }
  return out;
}

/// Formats bytes as lowercase hex, with a space every [group] nibbles-pair (byte group).
String formatHex(List<int> bytes, {int group = 8}) {
  if (bytes.isEmpty) return '';
  final sb = StringBuffer();
  for (var i = 0; i < bytes.length; i++) {
    if (i > 0 && i % group == 0) sb.write(' ');
    sb.write(bytes[i].toRadixString(16).padLeft(2, '0'));
  }
  return sb.toString();
}

/// Normalizes base64 input (ignores whitespace). Returns null if invalid.
Uint8List? tryDecodeBase64(String input) {
  final normalized = input.replaceAll(RegExp(r'\s'), '');
  if (normalized.isEmpty) return null;
  try {
    return Uint8List.fromList(base64Decode(normalized));
  } catch (_) {
    return null;
  }
}
