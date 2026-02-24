# SDK Floor Alignment - 2026-02-24

## Why
- A consumer CI pipeline failed on Dart `3.7.2` because package `rerune 0.1.2` declared `sdk: ^3.9.0`.
- The library does not require Dart 3.9-specific language/runtime features.
- We want constraints to reflect real minimum requirements, not latest local toolchain.

## Decision
- Lower package environment constraints to the practical minimum based on current dependency floors:
  - Dart: `>=3.4.0 <4.0.0`
  - Flutter: `>=3.22.0`

## Rationale
- Direct dependency minimums currently imply Dart/Flutter floors at or above these versions:
  - `shared_preferences ^2.3.2` requires Dart `^3.4.0` and Flutter `>=3.22.0`.
  - Other direct dependencies are compatible at or below that floor.
- This keeps compatibility broad (including Dart 3.7.x) without weakening dependency requirements.

## Files updated
- `pubspec.yaml`
- `CHANGELOG.md`
