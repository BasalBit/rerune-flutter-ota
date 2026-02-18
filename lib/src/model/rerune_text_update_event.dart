import 'package:flutter/widgets.dart';

@immutable
class ReRuneTextUpdateEvent {
  const ReRuneTextUpdateEvent({
    required this.revision,
    required this.updatedLocales,
  });

  final int revision;
  final List<Locale> updatedLocales;
}
