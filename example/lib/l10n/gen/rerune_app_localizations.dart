import 'package:flutter/widgets.dart';
import 'package:rerune/rerune.dart';
import 'package:rerune/src/controller/ota_localization_controller.dart';

import 'app_localizations.dart';

class ReruneAppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const ReruneAppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLocalizations.delegate.isSupported(locale);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final base = await AppLocalizations.delegate.load(locale);
    return _ReruneAppLocalizations(base, ReRune._requireController(), locale);
  }

  @override
  bool shouldReload(covariant ReruneAppLocalizationsDelegate old) => false;
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

class ReRuneBuilder extends StatelessWidget {
  const ReRuneBuilder({super.key, required this.builder});

  final Widget Function(BuildContext context) builder;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ReRuneTextUpdateEvent>(
      stream: ReRune.onFetchedTextsApplied,
      builder: (context, _) => builder(context),
    );
  }
}

class ReRune {
  static OtaLocalizationController? _controller;

  static void setup({
    required String otaPublishId,
    ReRuneCacheStore? cacheStore,
    ReRuneUpdatePolicy? updatePolicy,
  }) {
    final controller = OtaLocalizationController(
      supportedLocales: AppLocalizations.supportedLocales,
      otaPublishId: otaPublishId,
      cacheStore: cacheStore,
      updatePolicy: updatePolicy,
    );
    _controller?.removeListener(_handleControllerChange);
    _controller = controller;
    controller.addListener(_handleControllerChange);
    controller.initialize();
  }

  static Future<ReRuneUpdateResult> checkForUpdates() {
    return _requireController().checkForUpdates();
  }

  static Stream<ReRuneTextUpdateEvent> get onFetchedTextsApplied {
    return _requireController().onReRuneFetchedTextsApplied;
  }

  static List<LocalizationsDelegate<dynamic>> get localizationsDelegates {
    return [
      const ReruneAppLocalizationsDelegate(),
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
