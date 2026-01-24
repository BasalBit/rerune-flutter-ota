import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../controller/ota_localization_controller.dart';
import '../localizations/ota_localizations.dart';

class OtaLocalizationsDelegate extends LocalizationsDelegate<OtaLocalizations> {
  OtaLocalizationsDelegate({required this.controller, required this.revision});

  final OtaLocalizationController controller;
  final int revision;

  @override
  bool isSupported(Locale locale) {
    return controller.supportedLocales.any(
      (supported) => supported.languageCode == locale.languageCode,
    );
  }

  @override
  Future<OtaLocalizations> load(Locale locale) {
    final bundle = controller.bundleForLocale(locale);
    return SynchronousFuture(
      OtaLocalizations(locale: locale, messages: bundle),
    );
  }

  @override
  bool shouldReload(covariant OtaLocalizationsDelegate old) {
    return old.revision != revision;
  }
}
