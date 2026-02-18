// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:rerune/rerune.dart';

import 'package:example/main.dart';
import 'package:example/l10n/gen/app_localizations.dart';

void main() {
  testWidgets('renders menu and opens all demo pages', (
    WidgetTester tester,
  ) async {
    final controller = ReRuneLocalizationController(
      supportedLocales: AppLocalizations.supportedLocales,
      projectId: 'project',
      apiKey: 'key',
      updatePolicy: const ReRuneUpdatePolicy(checkOnStart: false),
    );

    await tester.pumpWidget(OtaExampleApp(controller: controller));

    await tester.pump();

    expect(find.text('Rerune OTA menu'), findsOneWidget);
    expect(find.text('1) Manual refresh page'), findsOneWidget);
    expect(find.text('2) Stream event listener + setState'), findsOneWidget);
    expect(
      find.text('3) ReRuneBuilder (fetched updates only)'),
      findsOneWidget,
    );

    await tester.tap(find.text('1) Manual refresh page'));
    await tester.pumpAndSettle();
    expect(find.text('Manual refresh'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('2) Stream event listener + setState'));
    await tester.pumpAndSettle();
    expect(find.text('Event listener + setState'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('3) ReRuneBuilder (fetched updates only)'));
    await tester.pumpAndSettle();
    expect(find.text('ReRuneBuilder'), findsOneWidget);
  });
}
