import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rerune/rerune.dart';

void main() {
  testWidgets('default mode rebuilds on controller notifications', (
    WidgetTester tester,
  ) async {
    final controller = _TestLocalizationController();
    addTearDown(controller.dispose);
    final observedRevisions = <int>[];

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ReRuneBuilder<String>(
          controller: controller,
          delegateFactory: (context, _, revision) {
            observedRevisions.add(revision);
            return _TestDelegate();
          },
          builder: (context, _) => const SizedBox.shrink(),
        ),
      ),
    );

    expect(observedRevisions, [0]);

    controller.emitAnyControllerChange();
    await tester.pump();

    expect(observedRevisions, [0, 0]);
  });

  testWidgets('fetched-only mode ignores generic controller changes', (
    WidgetTester tester,
  ) async {
    final controller = _TestLocalizationController();
    addTearDown(controller.dispose);
    final observedRevisions = <int>[];

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ReRuneBuilder<String>(
          controller: controller,
          refreshMode: ReRuneLocalizationRefreshMode.fetchedUpdatesOnly,
          delegateFactory: (context, _, revision) {
            observedRevisions.add(revision);
            return _TestDelegate();
          },
          builder: (context, _) => const SizedBox.shrink(),
        ),
      ),
    );

    expect(observedRevisions, [0]);

    controller.emitAnyControllerChange();
    await tester.pump();

    expect(observedRevisions, [0]);
  });

  testWidgets('fetched-only mode rebuilds when fetched revision changes', (
    WidgetTester tester,
  ) async {
    final controller = _TestLocalizationController();
    addTearDown(controller.dispose);
    final observedRevisions = <int>[];

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ReRuneBuilder<String>(
          controller: controller,
          refreshMode: ReRuneLocalizationRefreshMode.fetchedUpdatesOnly,
          delegateFactory: (context, _, revision) {
            observedRevisions.add(revision);
            return _TestDelegate();
          },
          builder: (context, _) => const SizedBox.shrink(),
        ),
      ),
    );

    expect(observedRevisions, [0]);

    controller.emitFetchedUpdate();
    await tester.pump();

    expect(observedRevisions, [0, 1]);
  });
}

class _TestDelegate extends LocalizationsDelegate<String> {
  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<String> load(Locale locale) async => '';

  @override
  bool shouldReload(covariant LocalizationsDelegate<String> old) => false;
}

class _TestLocalizationController extends ReRuneLocalizationController {
  _TestLocalizationController()
    : super(
        supportedLocales: const [Locale('en')],
        projectId: 'project',
        apiKey: 'key',
        updatePolicy: const ReRuneUpdatePolicy(checkOnStart: false),
      );

  final ValueNotifier<int> _fetchedRevision = ValueNotifier<int>(0);

  @override
  int get reRuneFetchedRevision => _fetchedRevision.value;

  @override
  ValueListenable<int> get reRuneFetchedRevisionListenable => _fetchedRevision;

  void emitAnyControllerChange() {
    notifyListeners();
  }

  void emitFetchedUpdate() {
    _fetchedRevision.value += 1;
  }

  @override
  void dispose() {
    _fetchedRevision.dispose();
    super.dispose();
  }
}
