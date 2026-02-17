# Rerune Flutter OTA Example

This app demonstrates integrating `rerune_flutter_ota` with bundled ARB seed
translations and OTA updates from the Rerune API.

## Integration notes

- The SDK uses `https://rerune.io/api` automatically.
- You only need to provide `supportedLocales` and project credentials
  (`project_id`/`api_key`) via `rerune.json` or controller overrides.
- Seed translations are loaded from the path configured in `rerune.json`
  (`translations_path`).
- The UI keeps using generated `AppLocalizations` getters.

## Run

```bash
flutter pub get
flutter gen-l10n
flutter run
```
