# Generated ReRuneBuilder Wrapper - 2026-02-18

## Why this was added
- Example `BuilderPage` did not reliably refresh when wired manually with `ValueListenableBuilder` + static child usage.
- We want a consumer-facing wrapper that hides notifier wiring and triggers redraws when OTA text updates are applied.

## Decision
- Add a generated `ReRuneBuilder` widget in `rerune_app_localizations.dart`.
- API shape is intentionally minimal:
  - `ReRuneBuilder(builder: (context) => ...)`
  - optional `refreshMode` with default fetched-updates-only behavior.

## Generated API
- `enum ReRuneRefreshMode { fetchedUpdatesOnly, anyControllerChange }`
- `class ReRuneBuilder extends StatelessWidget`
  - `builder` type: `Widget Function(BuildContext context)`
  - default `refreshMode`: `ReRuneRefreshMode.fetchedUpdatesOnly`

## Important implementation detail
- `builder` is a callback (not a prebuilt `Widget`) so localized strings are re-evaluated on each ReRune-triggered rebuild.
- This avoids stale text when callsites use `AppLocalizations.of(context)!...`.

## Files touched
- `bin/generate.dart`
- `example/lib/l10n/gen/rerune_app_localizations.dart` (regenerated)
- `example/lib/pages/builder_page.dart`
- `README.md`
- `REFERENCE.md`
- `CHANGELOG.md`

## Verification
- `flutter test` (root) passed.
- `flutter test` in `example/` passed.
