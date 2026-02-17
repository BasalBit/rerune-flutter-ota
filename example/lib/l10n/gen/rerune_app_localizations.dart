import 'package:flutter/widgets.dart';
import 'package:rerune_flutter_ota/rerune_flutter_ota.dart';

import 'app_localizations.dart';

class ReruneAppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const ReruneAppLocalizationsDelegate({
    required this.controller,
    required this.revision,
  });

  final OtaLocalizationController controller;
  final int revision;

  @override
  bool isSupported(Locale locale) =>
      AppLocalizations.delegate.isSupported(locale);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final base = await AppLocalizations.delegate.load(locale);
    return _ReruneAppLocalizations(base, controller, locale);
  }

  @override
  bool shouldReload(covariant ReruneAppLocalizationsDelegate old) {
    return old.revision != revision || old.controller != controller;
  }
}

class _ReruneAppLocalizations extends AppLocalizations {
  _ReruneAppLocalizations(this._base, this._controller, this._locale)
    : super(_base.localeName);

  final AppLocalizations _base;
  final OtaLocalizationController _controller;
  final Locale _locale;

  @override
  String get body {
    final fallback = _base.body;
    return _controller.resolveText(_locale, key: 'body', fallback: fallback);
  }

  @override
  String get button {
    final fallback = _base.button;
    return _controller.resolveText(_locale, key: 'button', fallback: fallback);
  }

  @override
  String get title {
    final fallback = _base.title;
    return _controller.resolveText(_locale, key: 'title', fallback: fallback);
  }
}

class ReruneAppLocalizationsSetup {
  static List<LocalizationsDelegate<dynamic>> localizationsDelegates(
    LocalizationsDelegate<AppLocalizations> otaDelegate,
  ) {
    return [
      otaDelegate,
      ...AppLocalizations.localizationsDelegates.where(
        (delegate) => delegate.type != AppLocalizations,
      ),
    ];
  }

  static List<Locale> get supportedLocales => AppLocalizations.supportedLocales;
}
