import 'package:flutter/material.dart';
import 'package:rerune/rerune.dart';

import 'l10n/gen/app_localizations.dart';
import 'pages/menu_page.dart';

const _projectId = '699485820fd61693e4cafffd';
const _apiKey =
    '5d774ba71a9d3915234733f868a0987fbd0eb065a01365b27216e2dbed436729';

void main() {
  final controller = ReRuneLocalizationController(
    supportedLocales: AppLocalizations.supportedLocales,
    projectId: _projectId,
    apiKey: _apiKey,
    updatePolicy: const ReRuneUpdatePolicy(checkOnStart: false),
  );
  controller.initialize();
  runApp(OtaExampleApp(controller: controller));
}

class OtaExampleApp extends StatefulWidget {
  const OtaExampleApp({required this.controller, super.key});

  final ReRuneLocalizationController controller;

  @override
  State<OtaExampleApp> createState() => _OtaExampleAppState();
}

class _OtaExampleAppState extends State<OtaExampleApp> {
  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rerune OTA',
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MenuPage(controller: widget.controller),
    );
  }
}
