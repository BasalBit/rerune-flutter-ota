import 'package:flutter/widgets.dart';

import 'ota_error.dart';

class OtaUpdateResult {
  const OtaUpdateResult({
    required this.updatedLocales,
    required this.skippedLocales,
    required this.errors,
  });

  final List<Locale> updatedLocales;
  final List<Locale> skippedLocales;
  final List<OtaError> errors;

  bool get hasUpdates => updatedLocales.isNotEmpty;
  bool get hasErrors => errors.isNotEmpty;
}
