# AGENTS

## Public API naming rule
- Any API exposed to library consumers must follow `ReRune` naming.
- Exported classes, enums, typedefs, and public helper types must start with `ReRune`.
- Exported top-level functions must start with `reRune`.
- Static functions do not need a `reRune` prefix.
- Internal classes and functions that are not exposed to library consumers must not start with `ReRune` or `reRune`.
- Do not introduce new consumer-facing names with `Ota` or other prefixes.
- Private/internal implementation symbols are exempt from the public prefix requirement.

## Migration rule
- If a touched public API does not follow these naming rules, rename it and document the change in `CHANGELOG.md`.
