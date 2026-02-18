# ReRune Migration & Feature Reference

This document is a compact reference of all completed changes in the current working version.

## 1) What was added

- Optional immediate text refresh support after OTA fetch/apply.
- New fetched-update signal APIs in `ReRuneLocalizationController`:
  - `reRuneFetchedRevision`
  - `reRuneFetchedRevisionListenable`
  - `onReRuneFetchedTextsApplied`
- New event model: `ReRuneTextUpdateEvent`.
- Builder-level opt-in refresh mode: `ReRuneLocalizationRefreshMode.fetchedUpdatesOnly`.

Important behavior: immediate refresh is optional. Existing consumers are not forced into fetched-only refresh.

## 2) Public API naming migration (ReRune)

All consumer-facing APIs were aligned to `ReRune*` / `reRune*` naming rules.

- `OtaLocalizationController` -> `ReRuneLocalizationController`
- `OtaUpdatePolicy` -> `ReRuneUpdatePolicy`
- `OtaUpdateResult` -> `ReRuneUpdateResult`
- `OtaErrorType` -> `ReRuneErrorType`
- `OtaError` -> `ReRuneError`
- `Manifest` -> `ReRuneManifest`
- `ManifestLocale` -> `ReRuneManifestLocale`
- `CachedManifest` -> `ReRuneCachedManifest`
- `CachedArb` -> `ReRuneCachedArb`
- `CacheStore` -> `ReRuneCacheStore`
- `createDefaultCacheStore()` -> `reRuneCreateDefaultCacheStore()`
- `OtaTypedLocalizationBuilder<T>` -> `ReRuneBuilder<T>`
- `OtaTypedDelegateFactory<T>` -> `ReRuneDelegateFactory<T>`
- `OtaTypedLocalizationWidgetBuilder<T>` -> `ReRuneLocalizationWidgetBuilder<T>`

## 3) Example app changes

Example now demonstrates three refresh strategies from a menu:

1. Manual refresh page (`ManualRefreshPage`)
   - "Check for updates" only checks and shows result in `SnackBar`.
   - "Refresh page" explicitly re-reads and redraws text.
2. Event listener page (`EventListenerPage`)
   - Listens to `onReRuneFetchedTextsApplied` and updates with `setState`.
3. Builder page (`BuilderPage`)
   - Uses `ReRuneBuilder` with `fetchedUpdatesOnly` mode.

Pages were split into separate files under `example/lib/pages/`.

## 4) Generator and integration updates

- `bin/generate.dart` updated to emit renamed `ReRune*` API types.
- Generated sample wrapper updated accordingly:
  - `example/lib/l10n/gen/rerune_app_localizations.dart`
- Public export updated for event model:
  - `lib/rerune.dart` exports `rerune_text_update_event.dart`.

## 5) Documentation and governance updates

- `README.md` updated with:
  - renamed API references,
  - fetched-only optional integration examples.
- `example/README.md` updated for renamed policy type.
- `AGENTS.md` updated with active naming rules:
  - public classes/enums/typedefs: `ReRune*`
  - exported top-level functions: `reRune*`
  - static functions: no `reRune` requirement
  - internal non-public symbols: must not start with `ReRune` or `reRune`

## 6) Legal update

- `LICENSE` updated to: `Copyright (c) 2026 BasalBit GmbH`.

## 7) Test coverage added/updated

- `test/rerune_test.dart` expanded with fetched-only revision/event behavior checks.
- New `test/ota_typed_localization_builder_test.dart` for builder mode semantics.
- `example/test/widget_test.dart` updated for new menu/page navigation.

Validated with:

- `flutter test` (package root)
- `flutter test` (example)

## 8) Files of primary interest

- `lib/src/controller/ota_localization_controller.dart`
- `lib/src/widget/ota_typed_localization_builder.dart`
- `lib/src/model/rerune_text_update_event.dart`
- `lib/src/model/manifest.dart`
- `lib/src/model/ota_error.dart`
- `lib/src/model/update_result.dart`
- `lib/src/policy/update_policy.dart`
- `lib/src/cache/cache_store*.dart`
- `bin/generate.dart`
- `example/lib/main.dart`
- `example/lib/pages/menu_page.dart`
- `example/lib/pages/manual_refresh_page.dart`
- `example/lib/pages/event_listener_page.dart`
- `example/lib/pages/builder_page.dart`
- `README.md`
- `CHANGELOG.md`
- `AGENTS.md`
- `LICENSE`
