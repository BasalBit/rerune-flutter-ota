// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rerune/rerune.dart';

import 'package:example/main.dart';
import 'package:example/l10n/gen/rerune_app_localizations.dart';

void main() {
  testWidgets('renders bundled translations', (WidgetTester tester) async {
    ReRune.setup(
      projectId: 'project',
      apiKey: 'key',
      updatePolicy: const OtaUpdatePolicy(checkOnStart: false),
    );

    addTearDown(() => ReRune.controller.dispose());
    await tester.pump();

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: ReRune.localizationsDelegates,
        supportedLocales: ReRune.supportedLocales,
        home: const ExampleHome(),
      ),
    );

    await tester.pump();

    expect(find.text('Rerune OTA Example'), findsOneWidget);
    expect(
      find.text('Translations update without restarting.'),
      findsOneWidget,
    );
    expect(find.text('Check for updates'), findsOneWidget);
  });
}
