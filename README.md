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
  rerune: ^0.0.3
```

Provide credentials using one of these options:

- `rerune.json` asset (`project_id`, `api_key`) in app root
- `ReRune.setup(projectId: ..., apiKey: ...)`

Configuration precedence is strict: `rerune.json` (asset) takes priority over
constructor values.

If neither source is provided, `ReRuneLocalizationController` throws a
`StateError` and logs a debug message describing the required setup.

If you use `rerune.json`, include it in `flutter.assets`:

```yaml
flutter:
  assets:
    - rerune.json
```

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
    // Optional: override project_id from rerune.json
    // projectId: 'your-project-id',
    // Optional: override api_key from rerune.json
    // apiKey: 'your-api-key',
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

If you do not include `rerune.json` in assets, provide both `projectId` and
`apiKey` to `ReRune.setup(...)`.

`ReRuneUpdatePolicy` defaults to `checkOnStart: true`.

`ReRuneLocalizationController` always uses `https://rerune.io/api` for manifest and
translation requests.

## Optional immediate refresh for fetched OTA changes

This behavior is opt-in. Existing integrations keep the current behavior unless
you explicitly use the new APIs.

- `ReRuneLocalizationController.reRuneFetchedRevisionListenable`
- `ReRuneLocalizationController.onReRuneFetchedTextsApplied`
- `ReRuneBuilder(refreshMode: ReRuneLocalizationRefreshMode.fetchedUpdatesOnly)`

Use fetched-only refresh mode when you want rebuilds only after newly fetched
translations are applied (not when cached bundles are loaded at startup).

```dart
ReRuneBuilder<AppLocalizations>(
  controller: controller,
  refreshMode: ReRuneLocalizationRefreshMode.fetchedUpdatesOnly,
  delegateFactory: (context, controller, revision) {
    return ReruneAppLocalizationsDelegate(controller: controller);
  },
  builder: (context, delegate) {
    return Localizations.override(
      context: context,
      delegates: [delegate],
      child: const MyHomePage(),
    );
  },
);
```

You can also subscribe directly:

```dart
final sub = controller.onReRuneFetchedTextsApplied.listen((event) {
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
`/sdk/projects/{projectId}/translations/manifest?platform=flutter`.

If a locale entry omits `url`, the SDK constructs it using:
`/sdk/projects/{projectId}/translations/flutter/{locale}` with values
from controller values or optional `rerune.json`.

## Links
- Homepage: https://rerune.io/
- Repository: https://github.com/BasalBit/rerune-flutter-ota
- Issues: https://github.com/BasalBit/rerune-flutter-ota/issues
