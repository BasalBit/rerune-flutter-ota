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
  rerune_flutter_ota:
    path: ../rerune_flutter_ota
```

Add your `rerune.json` to the app root and include it as an asset:

```yaml
flutter:
  assets:
    - rerune.json
```

If you pass `apiKey` to the controller, the file is optional and ignored.

## Usage

```dart
final controller = OtaLocalizationController(
  manifestUrl: Uri.parse('https://example.com/manifest.json'),
  supportedLocales: const [Locale('en'), Locale('es')],
  // Optional: override api_key from rerune.json
  // apiKey: 'your-api-key',
  // Optional: override project_id/platform from rerune.json
  // projectId: 'your-project-id',
  // platform: 'flutter',
  seedBundles: {
    const Locale('en'): {'title': 'Hello'},
    const Locale('es'): {'title': 'Hola'},
  },
);

await controller.initialize();

return OtaLocalizationBuilder(
  controller: controller,
  builder: (context, delegate) {
    return MaterialApp(
      localizationsDelegates: [delegate],
      supportedLocales: controller.supportedLocales,
      home: MyHomePage(),
    );
  },
);
```

## Manifest format

```json
{
  "version": 7,
  "locales": {
    "en": {
      "version": 3,
      "url": "https://api.example.com/sdk/projects/<projectId>/translations/flutter/en",
      "sha256": "..."
    },
    "es": {
      "version": 2,
      "url": "https://api.example.com/sdk/projects/<projectId>/translations/flutter/es"
    }
  }
}
```

If a locale entry omits `url`, the SDK will construct it using:
`/sdk/projects/{projectId}/translations/{platform}/{locale}` with values
from `rerune.json` or controller overrides.
