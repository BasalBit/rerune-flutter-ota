import 'package:flutter/widgets.dart';

import 'ota_error.dart';

class ReRuneUpdateResult {
  const ReRuneUpdateResult({
    required this.updatedLocales,
    required this.skippedLocales,
    required this.errors,
  });

  final List<Locale> updatedLocales;
  final List<Locale> skippedLocales;
  final List<ReRuneError> errors;

  bool get hasUpdates => updatedLocales.isNotEmpty;
  bool get hasErrors => errors.isNotEmpty;
}
