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
  rerune: ^0.1.1
```

Provide your publish identifier through setup:

- `ReRune.setup(otaPublishId: '...')`

If `otaPublishId` is empty, setup fails with a `StateError`.

## Seamless AppLocalizations integration

The SDK can overlay OTA translations on top of your generated
`AppLocalizations` API, so your widgets keep using:

```dart
Text(AppLocalizations.of(context)!.helloWorld)
```

1. Generate Flutter localizations (`flutter gen-l10n`).

2. Generate the Rerune wrapper:

```bash
flutter pub run rerune
```

`rerune` auto-detects Flutter localization settings from `l10n.yaml`
(`arb-dir`, `output-dir`, `output-localization-file`, `output-class`) and
falls back to Flutter defaults when `l10n.yaml` is not present.

If OTA fetch fails (offline/server error), the generated wrapper always falls
back to bundled `AppLocalizations` values from your app artifact.

3. Wire the generated delegate in your app root:

```dart
import 'l10n/rerune_app_localizations.dart';

void main() {
  ReRune.setup(
    otaPublishId: 'your-ota-publish-id',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: ReRune.localizationsDelegates,
      supportedLocales: ReRune.supportedLocales,
      home: MyHomePage(),
    );
  }
}
```

This is the complete app-side integration surface.

`ReRune.setup(...)` automatically uses `AppLocalizations.supportedLocales`.

`ReRuneUpdatePolicy` defaults to `checkOnStart: true`.

The runtime always uses `https://rerune.io/api` for manifest and translation requests.

## Optional immediate refresh for fetched OTA changes

This behavior is opt-in. Existing integrations keep the current behavior unless
you explicitly use the new APIs.

- `ReRuneBuilder`
- `ReRune.onFetchedTextsApplied`
- `ReRune.fetchedRevisionListenable`

Use `ReRuneBuilder` when you want simple rebuilds after fetched OTA text updates:

```dart
ReRuneBuilder(
  builder: (context) {
    final t = AppLocalizations.of(context)!;
    return Text(t.title);
  },
)
```

`ReRuneBuilder` defaults to fetched-updates-only refresh. You can opt into any
controller change with `refreshMode: ReRuneRefreshMode.anyControllerChange`.

You can also subscribe directly:

```dart
final sub = ReRune.onFetchedTextsApplied.listen((event) {
  debugPrint('Applied OTA text revision ${event.revision}: ${event.updatedLocales}');
});
```

## Manifest format

```json
{
  "version": 7,
  "locales": {
    "en": {
      "version": 3,
      "url": "https://rerune.io/api/sdk/translations/flutter/en",
      "sha256": "..."
    },
    "es": {
      "version": 2,
      "url": "https://rerune.io/api/sdk/translations/flutter/es"
    }
  }
}
```

Manifest URL is fixed to:
`https://rerune.io/api/sdk/translations/manifest?platform=flutter`.

If a locale entry omits `url`, the SDK constructs it using:
`https://rerune.io/api/sdk/translations/flutter/{locale}`.

## Links
- Homepage: https://rerune.io/
- Repository: https://github.com/BasalBit/rerune-flutter-ota
- Issues: https://github.com/BasalBit/rerune-flutter-ota/issues
