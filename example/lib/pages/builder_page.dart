import 'package:flutter/material.dart';
import 'package:rerune/rerune.dart';

import '../l10n/gen/app_localizations.dart';
import '../l10n/gen/rerune_app_localizations.dart';

class BuilderPage extends StatelessWidget {
  const BuilderPage({required this.controller, super.key});

  final ReRuneLocalizationController controller;

  @override
  Widget build(BuildContext context) {
    return ReRuneBuilder<AppLocalizations>(
      controller: controller,
      refreshMode: ReRuneLocalizationRefreshMode.fetchedUpdatesOnly,
      delegateFactory: (context, activeController, _) {
        return ReruneAppLocalizationsDelegate(controller: activeController);
      },
      builder: (context, delegate) {
        return Localizations.override(
          context: context,
          delegates: [delegate],
          child: _BuilderBody(controller: controller),
        );
      },
    );
  }
}

class _BuilderBody extends StatelessWidget {
  const _BuilderBody({required this.controller});

  final ReRuneLocalizationController controller;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: const Text('ReRuneBuilder')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'This page relies on ReRuneBuilder with fetched-updates-only mode.',
          ),
          const SizedBox(height: 24),
          Text(t.title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          Text(t.body, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () {
              controller.checkForUpdates();
            },
            child: Text(t.button),
          ),
        ],
      ),
    );
  }
}
