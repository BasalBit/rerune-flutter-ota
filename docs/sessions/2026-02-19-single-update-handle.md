# Single Update Handle + Simple Builder - 2026-02-19

## Why
- The generated API exposed too many overlapping update hooks:
  - `ReRune.onFetchedTextsApplied`
  - `ReRune.fetchedRevisionListenable`
  - `ReRuneBuilder` with multiple refresh modes.
- Consumer direction is to keep one event handle and one straightforward builder callback.

## Decision
- Keep a single public fetched-update event handle:
  - `ReRune.onFetchedTextsApplied`
- Remove generated `ReRune.fetchedRevisionListenable`.
- Simplify generated `ReRuneBuilder`:
  - only `builder:` callback
  - no `ReRuneRefreshMode`
  - redraw triggered by the fetched-update stream.

## Implementation
- Updated generator template (`bin/generate.dart`) to:
  - remove `ValueListenable`-based API output,
  - remove refresh mode enum and options,
  - emit `ReRuneBuilder` backed by `StreamBuilder<ReRuneTextUpdateEvent>`.
- Regenerated example wrapper:
  - `example/lib/l10n/gen/rerune_app_localizations.dart`
- Updated example text/docs:
  - `example/lib/pages/event_listener_page.dart`
  - `README.md`
  - `REFERENCE.md`
  - `CHANGELOG.md`

## Resulting consumer model
- Event subscription path:
  - `ReRune.onFetchedTextsApplied.listen(...)`
- Builder path:
  - `ReRuneBuilder(builder: (context) => ...)`

Both paths are aligned to the same underlying fetched-update event flow.
