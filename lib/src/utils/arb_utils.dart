import 'dart:convert';

Map<String, String> parseArb(String data) {
  final decoded = jsonDecode(data);
  if (decoded is! Map) {
    throw const FormatException('ARB content must be a JSON object.');
  }
  final map = <String, String>{};
  for (final entry in decoded.entries) {
    final key = entry.key;
    final value = entry.value;
    if (key is! String || key.startsWith('@')) {
      continue;
    }
    if (value is String) {
      map[key] = value;
    } else if (value != null) {
      map[key] = value.toString();
    }
  }
  return map;
}
