import 'package:flutter/widgets.dart';
import 'package:intl/message_format.dart';

class OtaLocalizations {
  OtaLocalizations({
    required this.locale,
    required Map<String, String> messages,
  }) : _messages = Map.unmodifiable(messages);

  final Locale locale;
  final Map<String, String> _messages;

  String text(String key, {Map<String, Object?>? args}) {
    final raw = _messages[key];
    if (raw == null) {
      return key;
    }
    if (args == null || args.isEmpty) {
      return raw;
    }
    try {
      final formatter = MessageFormat(raw, locale: locale.toString());
      return formatter.format(Map<String, Object>.from(args));
    } on FormatException {
      return raw;
    }
  }

  static OtaLocalizations of(BuildContext context) {
    final localizations = Localizations.of<OtaLocalizations>(
      context,
      OtaLocalizations,
    );
    assert(localizations != null, 'OtaLocalizations not found in context.');
    return localizations!;
  }
}
