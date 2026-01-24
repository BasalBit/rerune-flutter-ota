import 'package:flutter/widgets.dart';

String localeKey(Locale locale) {
  final countryCode = locale.countryCode;
  if (countryCode == null || countryCode.isEmpty) {
    return locale.languageCode;
  }
  return '${locale.languageCode}_$countryCode';
}
