## Unreleased

- No changes yet.

## 0.1.0

- BREAKING: removed all `rerune.json` runtime config support.
- BREAKING: removed `projectId`, `apiKey`, and `manifestUrl` setup/constructor inputs.
- BREAKING: `ReRuneLocalizationController` now requires `otaPublishId` and sends it as `X-OTA-Publish-Id`.
- BREAKING: `ReRuneLocalizationController` and typed builder APIs are no longer exported publicly; use generated `ReRune.setup(...)` and `ReRune` static APIs.
- Manifest endpoint is now fixed to `https://rerune.io/api/sdk/translations/manifest?platform=flutter`.
- ARB fallback endpoint is now `https://rerune.io/api/sdk/translations/flutter/{locale}` when manifest locale URL is omitted.
- Example app now uses setup-only integration (no direct controller construction).

## 0.0.4

- BREAKING: removed seed ARB support (`seedBundles` and `translations_path`).
- Fallback now follows Flutter defaults only: OTA/cache first, then bundled `AppLocalizations` strings.
- BREAKING: runtime config now uses strict precedence `rerune.json` asset -> constructor (`projectId`, `apiKey`).
- BREAKING: removed runtime `--dart-define` fallback for config resolution.
- `platform` is fixed to `flutter` and is no longer configurable in controller/runtime config.
- Added explicit `StateError` with debug log when required credentials are missing.
- Docs/examples now use `ReRune.setup(...)`, `ReRune.localizationsDelegates`, and `ReRune.supportedLocales`.
- Clarified that `ReRuneUpdatePolicy` defaults to `checkOnStart: true`.
- Generated `ReRune.setup(...)` helper now auto-wires supported locales and initializes OTA.
- BREAKING: removed deprecated generated compatibility aliases (`Rerune...Setup`, `createRerune...Controller`).
- BREAKING: removed CLI executable alias `generate`; use `flutter pub run rerune` only.
- BREAKING: renamed `OtaLocalizationController` to `ReRuneLocalizationController`.
- BREAKING: renamed `OtaUpdatePolicy` to `ReRuneUpdatePolicy`.
- BREAKING: renamed `OtaUpdateResult` to `ReRuneUpdateResult`.
- BREAKING: renamed `OtaErrorType`/`OtaError` to `ReRuneErrorType`/`ReRuneError`.
- BREAKING: renamed `Manifest`/`ManifestLocale` to `ReRuneManifest`/`ReRuneManifestLocale`.
- BREAKING: renamed `CachedManifest`/`CachedArb` to `ReRuneCachedManifest`/`ReRuneCachedArb`.
- BREAKING: renamed `CacheStore` to `ReRuneCacheStore` and `createDefaultCacheStore()` to `reRuneCreateDefaultCacheStore()`.
- BREAKING: renamed `OtaTypedLocalizationBuilder` to `ReRuneBuilder`.
- BREAKING: renamed typed builder typedefs to `ReRuneDelegateFactory<T>` and `ReRuneLocalizationWidgetBuilder<T>`.
- Added `ReRuneTextUpdateEvent` and exported it from `package:rerune/rerune.dart`.
- Added optional fetched-only refresh APIs for immediate UI updates after applied OTA text changes:
  `reRuneFetchedRevision`, `reRuneFetchedRevisionListenable`, and `onReRuneFetchedTextsApplied`.
- Added `ReRuneLocalizationRefreshMode.fetchedUpdatesOnly` to `ReRuneBuilder`.
- Existing refresh behavior remains default; fetched-only refresh is opt-in.
- Updated generator output (`rerune_app_localizations.dart`) to use renamed `ReRune*` public APIs.
- Expanded tests:
  - controller tests for fetched-only revision/event behavior,
  - new `test/ota_typed_localization_builder_test.dart` for builder refresh modes,
  - updated example widget test coverage for menu navigation.
- Example app now has a 3-page demo menu:
  - manual refresh page,
  - event-listener (`onReRuneFetchedTextsApplied`) page,
  - `ReRuneBuilder` page with fetched-updates-only mode.
- Example manual refresh flow now separates update check from UI refresh and shows update-check results via `SnackBar`.
- Example pages are split into dedicated files under `example/lib/pages/`.
- Updated README and example README for renamed APIs and fetched-only refresh usage.
- Updated `AGENTS.md` naming rules and applied them across the codebase.
- Updated license copyright holder to `BasalBit GmbH`.

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
