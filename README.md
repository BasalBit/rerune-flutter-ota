# Rerune Flutter OTA

Update ARB translation files at runtime (mobile, web, desktop) using a manifest
endpoint. The SDK downloads new translations, caches them, and rebuilds
`Localizations` without restarting the app.

## Features
- Manifest-driven ARB updates with ETag support
- Local cache for offline fallback
- Hot swap translations without app restart
- Works on mobile, web, and desktop

## Getting started
Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  rerune_flutter_ota: ^0.0.1
```

Add your `rerune.json` to the app root and include it as an asset:

```yaml
flutter:
  assets:
    - rerune.json
    - lib/languages/I10n/
```

If you pass `apiKey` to the controller, the file is optional and ignored.

When `translations_path` is set in `rerune.json`, the SDK automatically loads
seed bundles from `app_<code>.arb` files in that folder.

## Seamless AppLocalizations integration

The SDK can overlay OTA translations on top of your generated
`AppLocalizations` API, so your widgets keep using:

```dart
Text(AppLocalizations.of(context)!.helloWorld)
```

1. Generate Flutter localizations (`flutter gen-l10n`).

2. Generate the Rerune wrapper:

```bash
dart run rerune_flutter_ota:generate \
  --input lib/l10n/app_localizations.dart \
  --output lib/l10n/rerune_app_localizations.dart
```

3. Wire the generated delegate in your app root:

```dart
import 'l10n/app_localizations.dart';
import 'l10n/rerune_app_localizations.dart';

final controller = OtaLocalizationController(
  supportedLocales: const [Locale('en'), Locale('es')],
  // Optional: override api_key from rerune.json
  // apiKey: 'your-api-key',
  // Optional: override project_id/platform from rerune.json
  // projectId: 'your-project-id',
  // platform: 'flutter',
);

await controller.initialize();

return OtaTypedLocalizationBuilder<AppLocalizations>(
  controller: controller,
  delegateFactory: (context, controller, revision) {
    return ReruneAppLocalizationsDelegate(
      controller: controller,
      revision: revision,
    );
  },
  builder: (context, delegate) {
    return MaterialApp(
      localizationsDelegates:
          ReruneAppLocalizationsSetup.localizationsDelegates(delegate),
      supportedLocales: ReruneAppLocalizationsSetup.supportedLocales,
      home: MyHomePage(),
    );
  },
);
```

`OtaLocalizationController` always uses `https://rerune.io/api` for manifest and
translation requests.

## Manifest format

```json
{
  "version": 7,
  "locales": {
    "en": {
      "version": 3,
      "url": "https://rerune.io/api/sdk/projects/<projectId>/translations/flutter/en",
      "sha256": "..."
    },
    "es": {
      "version": 2,
      "url": "https://rerune.io/api/sdk/projects/<projectId>/translations/flutter/es"
    }
  }
}
```

Manifest URL is derived internally from `https://rerune.io/api` + `project_id`:
`/sdk/projects/{projectId}/translations/manifest?platform={platform}`.

If a locale entry omits `url`, the SDK constructs it using:
`/sdk/projects/{projectId}/translations/{platform}/{locale}` with values
from `rerune.json` or controller overrides.

## Links
- Homepage: https://rerune.io/
- Repository: https://github.com/BasalBit/rerune-flutter-ota
- Issues: https://github.com/BasalBit/rerune-flutter-ota/issues
