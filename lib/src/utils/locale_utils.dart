import 'package:flutter/widgets.dart';

String localeKey(Locale locale) {
  final languageCode = locale.languageCode;
  final scriptCode = locale.scriptCode;
  final countryCode = locale.countryCode;
  if (scriptCode != null && scriptCode.isNotEmpty) {
    if (countryCode != null && countryCode.isNotEmpty) {
      return '${languageCode}_${scriptCode}_$countryCode';
    }
    return '${languageCode}_$scriptCode';
  }
  if (countryCode != null && countryCode.isNotEmpty) {
    return '${languageCode}_$countryCode';
  }
  return languageCode;
}

List<String> localeFallbackKeys(Locale locale) {
  final keys = <String>[];
  final languageCode = locale.languageCode;
  final scriptCode = locale.scriptCode;
  final countryCode = locale.countryCode;

  if (scriptCode != null && scriptCode.isNotEmpty) {
    if (countryCode != null && countryCode.isNotEmpty) {
      keys.add('${languageCode}_${scriptCode}_$countryCode');
    }
    keys.add('${languageCode}_$scriptCode');
  }
  if (countryCode != null && countryCode.isNotEmpty) {
    keys.add('${languageCode}_$countryCode');
  }
  keys.add(languageCode);
  return keys;
}

Locale localeFromCode(String code) {
  final normalized = code.replaceAll('-', '_');
  final parts = normalized.split('_');
  if (parts.length >= 3) {
    return Locale.fromSubtags(
      languageCode: parts[0],
      scriptCode: parts[1],
      countryCode: parts[2],
    );
  }
  if (parts.length == 2) {
    final second = parts[1];
    if (second.length == 4) {
      return Locale.fromSubtags(languageCode: parts[0], scriptCode: second);
    }
    return Locale(parts[0], second);
  }
  return Locale(parts.first);
}
