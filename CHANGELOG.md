## Unreleased

- BREAKING: removed seed ARB support (`seedBundles` and `translations_path`).
- Fallback now follows Flutter defaults only: OTA/cache first, then bundled `AppLocalizations` strings.
- BREAKING: runtime config now uses strict precedence `rerune.json` asset -> constructor (`projectId`, `apiKey`).
- BREAKING: removed runtime `--dart-define` fallback for config resolution.
- `platform` is fixed to `flutter` and is no longer configurable in controller/runtime config.
- Added explicit `StateError` with debug log when required credentials are missing.
- Docs/examples now use `ReRune.setup(...)`, `ReRune.localizationsDelegates`, and `ReRune.supportedLocales`.
- Clarified that `OtaUpdatePolicy` defaults to `checkOnStart: true`.
- Generated `ReRune.setup(...)` helper now auto-wires supported locales and initializes OTA.
- BREAKING: removed deprecated generated compatibility aliases (`Rerune...Setup`, `createRerune...Controller`).
- BREAKING: removed CLI executable alias `generate`; use `flutter pub run rerune` only.

## 0.0.3

- BREAKING: package identity is now `rerune`.
- BREAKING: public import changed to `package:rerune/rerune.dart`.
- Added canonical CLI command `flutter pub run rerune` for localization wrapper generation.
- Added standard Flutter localization auto-detect from `l10n.yaml` and default `gen-l10n` paths.
- Added `--dart-define` config fallback (`RERUNE_PROJECT_ID`, `RERUNE_API_KEY`, `RERUNE_PLATFORM`) so `rerune.json` asset setup is optional.

## 0.0.2

- BREAKING: removed legacy key-based APIs (`OtaLocalizations`,
  `OtaLocalizationsDelegate`, `OtaLocalizationBuilder`).
- BREAKING: `OtaLocalizationController` no longer accepts `baseUrl`; API host is
  fixed to `https://rerune.io/api`.
- Added typed `AppLocalizations` overlay flow with
  `OtaTypedLocalizationBuilder<T>`.
- Added generator entrypoint for
  producing typed OTA wrappers.

## 0.0.1

- Initial release of the OTA localization SDK.
- Manifest-based ARB updates with ETag support and local caching.
- Hot-swap localization delegate with Rerune-hosted manifest URLs.
