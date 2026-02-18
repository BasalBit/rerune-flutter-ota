# Rerune Flutter OTA Example

This app demonstrates integrating `rerune` with OTA updates from the Rerune
API.

## Integration notes

- The SDK uses `https://rerune.io/api` automatically.
- Provide project credentials via `ReRune.setup(projectId: ..., apiKey: ...)`.
- `ReRune.localizationsDelegates` and `ReRune.supportedLocales` are ready to use in `MaterialApp`.
- If `rerune.json` is used, add it to `flutter.assets`; it overrides constructor values.
- If neither constructor credentials nor asset config is present, controller throws a `StateError`.
- `ReRuneUpdatePolicy` defaults to `checkOnStart: true`.
- The UI keeps using generated `AppLocalizations` getters.

## Run

```bash
flutter pub get
flutter gen-l10n
flutter run
```
