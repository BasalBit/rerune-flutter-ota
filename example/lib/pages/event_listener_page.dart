import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../l10n/gen/rerune_app_localizations.dart';

class EventListenerPage extends StatefulWidget {
  const EventListenerPage({super.key});

  @override
  State<EventListenerPage> createState() => _EventListenerPageState();
}

class _EventListenerPageState extends State<EventListenerPage> {
  Object? _lastEvent;
  Object? _lastResult;
  bool _isChecking = false;
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = ReRune.onFetchedTextsApplied.listen((event) {
      if (!mounted) {
        return;
      }
      setState(() {
        _lastEvent = event;
      });
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _checkForUpdates() async {
    setState(() {
      _isChecking = true;
    });
    final result = await ReRune.checkForUpdates();
    if (!mounted) {
      return;
    }
    setState(() {
      _isChecking = false;
      _lastResult = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final title = t.title;
    final body = t.body;
    final button = t.button;

    return Scaffold(
      appBar: AppBar(title: const Text('Event listener + setState')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'This page listens to onReRuneFetchedTextsApplied and rebuilds with setState.',
          ),
          const SizedBox(height: 24),
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          Text(body, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _isChecking ? null : _checkForUpdates,
            child: Text(_isChecking ? 'Checking...' : button),
          ),
          const SizedBox(height: 20),
          Text(
            _lastEvent == null
                ? 'No fetched-update event observed yet.'
                : 'Last fetched revision: ${(_lastEvent as dynamic).revision} - locales: ${(_lastEvent as dynamic).updatedLocales.join(', ')}',
          ),
          const SizedBox(height: 8),
          Text(
            _lastResult == null
                ? 'No check result yet.'
                : 'Last check -> updates: ${(_lastResult as dynamic).updatedLocales.length}, errors: ${(_lastResult as dynamic).errors.length}',
          ),
        ],
      ),
    );
  }
}
