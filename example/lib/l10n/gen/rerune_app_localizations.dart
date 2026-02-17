import 'package:flutter/widgets.dart';
import 'package:rerune/rerune.dart';

import 'app_localizations.dart';

class ReruneAppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const ReruneAppLocalizationsDelegate({required this.controller});

  final OtaLocalizationController controller;

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
    return old.controller != controller;
  }
}

class _ReruneAppLocalizations extends AppLocalizations {
  _ReruneAppLocalizations(this._base, this._controller, this._locale)
    : super(_base.localeName);

  final AppLocalizations _base;
  final OtaLocalizationController _controller;
  final Locale _locale;

  @override
  String get title {
    final fallback = _base.title;
    return _controller.resolveText(_locale, key: 'title', fallback: fallback);
  }

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
}

class ReRune {
  static OtaLocalizationController? _controller;

  static void setup({
    String? projectId,
    String? apiKey,
    Uri? manifestUrl,
    CacheStore? cacheStore,
    OtaUpdatePolicy? updatePolicy,
  }) {
    final controller = OtaLocalizationController(
      supportedLocales: AppLocalizations.supportedLocales,
      projectId: projectId,
      apiKey: apiKey,
      manifestUrl: manifestUrl,
      cacheStore: cacheStore,
      updatePolicy: updatePolicy,
    );
    _controller?.removeListener(_handleControllerChange);
    _controller = controller;
    controller.addListener(_handleControllerChange);
    controller.initialize();
  }

  static OtaLocalizationController get controller => _requireController();

  static Future<OtaUpdateResult> checkForUpdates() {
    return _requireController().checkForUpdates();
  }

  static List<LocalizationsDelegate<dynamic>> get localizationsDelegates {
    final controller = _requireController();
    return [
      ReruneAppLocalizationsDelegate(controller: controller),
      ...AppLocalizations.localizationsDelegates.where(
        (delegate) => delegate.type != AppLocalizations,
      ),
    ];
  }

  static List<Locale> get supportedLocales => AppLocalizations.supportedLocales;

  static OtaLocalizationController _requireController() {
    final current = _controller;
    if (current != null) {
      return current;
    }
    throw StateError(
      'ReRune.setup(...) must be called before accessing ReRune delegates/locales.',
    );
  }

  static void _handleControllerChange() {
    final root = WidgetsBinding.instance.rootElement;
    if (root == null) {
      return;
    }
    root.markNeedsBuild();
    WidgetsBinding.instance.scheduleFrame();
  }
}
