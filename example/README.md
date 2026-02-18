# Rerune Flutter OTA Example

This app demonstrates integrating `rerune` with OTA updates from the Rerune
API.

## Integration notes

- The SDK uses `https://rerune.io/api` automatically.
- Provide publish identifier via `ReRune.setup(otaPublishId: ...)`.
- `ReRune.localizationsDelegates` and `ReRune.supportedLocales` are ready to use in `MaterialApp`.
- `otaPublishId` is required for update checks; empty values throw `StateError`.
- `ReRuneUpdatePolicy` defaults to `checkOnStart: true`.
- The UI keeps using generated `AppLocalizations` getters.

## Run

```bash
flutter pub get
flutter gen-l10n
flutter run
```
