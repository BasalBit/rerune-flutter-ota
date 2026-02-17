import 'package:flutter/material.dart';
import 'package:rerune/rerune.dart';

import 'l10n/gen/app_localizations.dart';
import 'l10n/gen/rerune_app_localizations.dart';

const _projectId = '699485820fd61693e4cafffd';
const _apiKey =
    '5d774ba71a9d3915234733f868a0987fbd0eb065a01365b27216e2dbed436729';

void main() {
  ReRune.setup(
    projectId: _projectId,
    apiKey: _apiKey,
    updatePolicy: const OtaUpdatePolicy(
      checkOnStart: true,
      periodicInterval: Duration(seconds: 10),
    ),
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
      home: const ExampleHome(),
    );
  }
}

class ExampleHome extends StatelessWidget {
  const ExampleHome({super.key});

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
                await ReRune.checkForUpdates();
              },
              child: Text(t.button),
            ),
          ],
        ),
      ),
    );
  }
}
