// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rerune_flutter_ota/rerune_flutter_ota.dart';

import 'package:example/main.dart';

void main() {
  testWidgets('renders seeded translations', (WidgetTester tester) async {
    final controller = OtaLocalizationController(
      manifestUrl: Uri.parse('https://example.com/manifest.json'),
      supportedLocales: const [Locale('en')],
      updatePolicy: const OtaUpdatePolicy(checkOnStart: false),
      seedBundles: {
        const Locale('en'): {
          'title': 'Rerune OTA Example',
          'body': 'Translations update without restarting.',
          'button': 'Check for updates',
        },
      },
    );

    addTearDown(controller.dispose);

    await tester.pumpWidget(
      OtaLocalizationBuilder(
        controller: controller,
        builder: (context, delegate) {
          return MaterialApp(
            localizationsDelegates: [delegate],
            supportedLocales: controller.supportedLocales,
            home: ExampleHome(controller: controller),
          );
        },
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Rerune OTA Example'), findsOneWidget);
    expect(
      find.text('Translations update without restarting.'),
      findsOneWidget,
    );
    expect(find.text('Check for updates'), findsOneWidget);
  });
}
