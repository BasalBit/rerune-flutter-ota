import 'package:flutter/material.dart';
import 'package:rerune_flutter_ota/rerune_flutter_ota.dart';

import 'l10n/gen/app_localizations.dart';
import 'l10n/gen/rerune_app_localizations.dart';

void main() {
  runApp(const OtaExampleApp());
}

class OtaExampleApp extends StatefulWidget {
  const OtaExampleApp({super.key});

  @override
  State<OtaExampleApp> createState() => _OtaExampleAppState();
}

class _OtaExampleAppState extends State<OtaExampleApp> {
  late final OtaLocalizationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = OtaLocalizationController(
      supportedLocales: const [
        Locale('de'),
        Locale('en'),
        Locale('it'),
        Locale('pt'),
      ],
      updatePolicy: const OtaUpdatePolicy(
        checkOnStart: true,
        periodicInterval: Duration(seconds: 10),
      ),
    );
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OtaTypedLocalizationBuilder<AppLocalizations>(
      controller: _controller,
      delegateFactory: (context, controller, revision) {
        return ReruneAppLocalizationsDelegate(
          controller: controller,
          revision: revision,
        );
      },
      builder: (context, delegate) {
        return MaterialApp(
          title: 'Rerune OTA',
          localizationsDelegates:
              ReruneAppLocalizationsSetup.localizationsDelegates(delegate),
          supportedLocales: ReruneAppLocalizationsSetup.supportedLocales,
          home: ExampleHome(controller: _controller),
        );
      },
    );
  }
}

class ExampleHome extends StatelessWidget {
  const ExampleHome({super.key, required this.controller});

  final OtaLocalizationController controller;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(t.title)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.body, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () async {
                await controller.checkForUpdates();
              },
              child: Text(t.button),
            ),
          ],
        ),
      ),
    );
  }
}
