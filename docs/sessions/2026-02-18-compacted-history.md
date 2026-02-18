# Compacted History - 2026-02-18

## Project
- Path: `/Users/rubinbasha/BasalBit/rerune-flutter-ota`

## Intent at checkpoint
1. Config/auth only via `otaPublishId`.
2. Consumers should only use `ReRune.setup(...)`.
3. No public direct controller API for consumers.
4. Example app should follow setup-only usage.
5. Tests and example compile.

## What changed

### A) Breaking config/auth model
- Removed runtime dependency on `rerune.json`.
- Removed `projectId`, `apiKey`, and `manifestUrl` from runtime setup paths.
- Added required `otaPublishId` in runtime controller constructor.
- Auth header switched from `X-API-Key` to `X-OTA-Publish-Id`.
- Manifest endpoint fixed to:
  `https://rerune.io/api/sdk/translations/manifest?platform=flutter`
- ARB fallback endpoint fixed to:
  `https://rerune.io/api/sdk/translations/flutter/{locale}`

Primary files:
- `lib/src/controller/ota_localization_controller.dart`
- `lib/src/network/manifest_client.dart`
- `lib/src/network/arb_client.dart`

### B) Public API exposure direction
- Reverted internal runtime type name to `OtaLocalizationController` (internal, in `src`).
- Removed exports of controller and builder from package public barrel.
- `lib/rerune.dart` now exports only cache/model/policy types (no controller/widget).
- Goal: app developers use generated `ReRune.setup(...)` and generated `ReRune` static accessors only.

### C) Generated API updates
- Updated generator template:
  - adds internal controller import from `package:rerune/src/controller/ota_localization_controller.dart`
  - `ReRune.setup({required otaPublishId, ...})` instantiates internal `OtaLocalizationController`
  - added static accessors:
    - `ReRune.checkForUpdates()`
    - `ReRune.onFetchedTextsApplied`
    - `ReRune.fetchedRevisionListenable`
  - removed `ReRune.resolveText(...)` public shim
- File:
  - `bin/generate.dart`

### D) Example app refactor to setup-only
- `example/lib/main.dart`:
  - calls `ReRune.setup(otaPublishId: ...)`
  - no direct controller creation
  - uses `ReRune.localizationsDelegates` and `ReRune.supportedLocales`
- Example pages now no longer accept/pass controller instances:
  - `example/lib/pages/menu_page.dart`
  - `example/lib/pages/manual_refresh_page.dart`
  - `example/lib/pages/event_listener_page.dart`
  - `example/lib/pages/builder_page.dart`
- Example generated wrapper updated to setup-only static API:
  - `example/lib/l10n/gen/rerune_app_localizations.dart`
- Example test updated:
  - `example/test/widget_test.dart`

### E) Tests updated
- Root tests use internal controller import where needed:
  - `test/rerune_test.dart`
  - `test/ota_typed_localization_builder_test.dart`
- Added header assertion test for `X-OTA-Publish-Id` in `test/rerune_test.dart`.

### F) Docs/changelog/reference
- README updated to setup-only guidance (`ReRune.setup(otaPublishId: ...)`).
- CHANGELOG Unreleased includes breaking notes for config/auth and setup-only direction.
- REFERENCE.md updated with migration notes.
- Files:
  - `README.md`
  - `CHANGELOG.md`
  - `REFERENCE.md`
  - `example/README.md`

### G) Validation status
- `flutter test` at repo root: PASS
- `flutter test` in `example/`: PASS

## Working tree at checkpoint
- `CHANGELOG.md`
- `README.md`
- `REFERENCE.md`
- `bin/generate.dart`
- `example/README.md`
- `example/lib/l10n/gen/rerune_app_localizations.dart`
- `example/lib/main.dart`
- `example/lib/pages/builder_page.dart`
- `example/lib/pages/event_listener_page.dart`
- `example/lib/pages/manual_refresh_page.dart`
- `example/lib/pages/menu_page.dart`
- `example/test/widget_test.dart`
- `lib/rerune.dart`
- `lib/src/controller/ota_localization_controller.dart`
- `lib/src/network/arb_client.dart`
- `lib/src/network/manifest_client.dart`
- `lib/src/widget/ota_typed_localization_builder.dart`
- `test/ota_typed_localization_builder_test.dart`
- `test/rerune_test.dart`

## Governance constraints from AGENTS.md
- Public consumer-facing classes/enums/typedefs should follow `ReRune*`.
- Exported top-level functions should follow `reRune*`.
- Static functions are exempt from `reRune` prefix.
- Internal/non-exposed symbols should not start with `ReRune`/`reRune`.
- Consumer intent currently overrides older naming work: controller should not be public; consumers should use `ReRune.setup` only.

## Recommended next checks
1. Sanity-check package public API surface:
   - verify `lib/rerune.dart` exports only intended symbols.
   - ensure no docs mention direct controller/builder usage.
2. Reconcile AGENTS naming vs internal symbol names if needed:
   - internal class currently `OtaLocalizationController` in `src`.
3. Optionally regenerate example wrapper from generator and diff against checked-in generated file to ensure they match exactly.
4. If requested, prepare commit(s) with clean message(s) and release follow-up.

## Quick re-verify commands
- `flutter test`
- `(cd example && flutter test)`
- `grep -R "ReRuneLocalizationController\\|ReRuneBuilder\\|ReRune.resolveText\\|projectId\\|apiKey\\|rerune.json\\|X-API-Key" -n .`
- `git status --short`
