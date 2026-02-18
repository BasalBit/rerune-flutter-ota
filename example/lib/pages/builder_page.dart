import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../l10n/gen/rerune_app_localizations.dart';

class BuilderPage extends StatelessWidget {
  const BuilderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: ReRune.fetchedRevisionListenable,
      builder: (context, _, _) {
        return const _BuilderBody();
      },
    );
  }
}

class _BuilderBody extends StatelessWidget {
  const _BuilderBody();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: const Text('Builder-driven refresh')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'This page uses ValueListenableBuilder to rebuild only on fetched OTA revisions.',
          ),
          const SizedBox(height: 24),
          Text(t.title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          Text(t.body, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () {
              ReRune.checkForUpdates();
            },
            child: Text(t.button),
          ),
        ],
      ),
    );
  }
}
