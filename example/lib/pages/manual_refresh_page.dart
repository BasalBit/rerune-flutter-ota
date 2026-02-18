import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../l10n/gen/rerune_app_localizations.dart';

class ManualRefreshPage extends StatefulWidget {
  const ManualRefreshPage({super.key});

  @override
  State<ManualRefreshPage> createState() => _ManualRefreshPageState();
}

class _ManualRefreshPageState extends State<ManualRefreshPage> {
  Locale? _resolvedLocale;
  String? _title;
  String? _body;
  String? _button;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context);
    if (_resolvedLocale != locale || _title == null) {
      _updateDisplayedTexts();
    }
  }

  Future<void> _checkForUpdates() async {
    final result = await ReRune.checkForUpdates();
    if (!mounted) {
      return;
    }

    final message = result.hasErrors
        ? 'Update check finished with ${result.errors.length} error(s).'
        : result.hasUpdates
        ? 'Updates fetched for ${result.updatedLocales.length} locale(s). Tap "Refresh page" to apply.'
        : 'No updates available.';

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _refreshPage() {
    setState(_updateDisplayedTexts);
  }

  void _updateDisplayedTexts() {
    final t = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    _resolvedLocale = locale;
    _title = t.title;
    _body = t.body;
    _button = t.button;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manual refresh')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'This page does not auto-refresh text after updates. Check for updates first, then refresh the page manually.',
          ),
          const SizedBox(height: 24),
          Text(_title ?? '', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          Text(_body ?? '', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _checkForUpdates,
            child: Text(_button ?? 'Check for updates'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _refreshPage,
            child: const Text('Refresh page'),
          ),
        ],
      ),
    );
  }
}
