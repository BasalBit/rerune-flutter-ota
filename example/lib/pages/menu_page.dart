import 'package:flutter/material.dart';

import 'event_listener_page.dart';
import 'manual_refresh_page.dart';
import 'builder_page.dart';

class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rerune OTA menu')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Choose a refresh strategy',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          const Text(
            'All pages use the same ReRune.setup-backed runtime instance.',
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ManualRefreshPage()),
              );
            },
            child: const Text('1) Manual refresh page'),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const EventListenerPage()),
              );
            },
            child: const Text('2) Stream event listener + setState'),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const BuilderPage()));
            },
            child: const Text('3) Builder-driven fetched updates'),
          ),
        ],
      ),
    );
  }
}
