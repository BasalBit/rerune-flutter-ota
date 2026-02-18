import 'package:flutter/material.dart';
import 'package:rerune/rerune.dart';

import 'l10n/gen/rerune_app_localizations.dart';
import 'pages/menu_page.dart';

const _otaPublishId =
    '74268f4ce18af2b19538b4193200cc58fe63af6ffb300f32aec0683965504232';

void main() {
  ReRune.setup(
    otaPublishId: _otaPublishId,
    updatePolicy: const ReRuneUpdatePolicy(checkOnStart: true),
  );
  runApp(const OtaExampleApp());
}

class OtaExampleApp extends StatelessWidget {
  const OtaExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rerune OTA',
      localizationsDelegates: ReRune.localizationsDelegates,
      supportedLocales: ReRune.supportedLocales,
      home: const MenuPage(),
    );
  }
}
