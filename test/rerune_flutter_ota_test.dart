import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rerune_flutter_ota/rerune_flutter_ota.dart';

void main() {
  test('manifest parses locales', () {
    final manifest = Manifest.fromJson({
      'version': 1,
      'locales': {
        'en': {'version': 2, 'url': 'https://example.com/en.arb'},
        'fr': {'version': 1, 'url': 'https://example.com/fr.arb'},
      },
    });

    expect(manifest.version, 1);
    expect(manifest.locales['en']?.version, 2);
    expect(
      manifest.locales['fr']?.url,
      Uri.parse('https://example.com/fr.arb'),
    );
  });

  test('update policy defaults', () {
    const policy = OtaUpdatePolicy();
    expect(policy.checkOnStart, isTrue);
    expect(policy.periodicInterval, isNull);
  });

  test('controller returns seeded bundle when cache empty', () {
    final controller = OtaLocalizationController(
      supportedLocales: const [Locale('en')],
      seedBundles: {
        const Locale('en'): {'hello': 'Hello'},
      },
    );

    final bundle = controller.bundleForLocale(const Locale('en'));
    expect(bundle['hello'], 'Hello');
  });
}
