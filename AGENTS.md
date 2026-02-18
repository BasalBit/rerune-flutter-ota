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

## Session continuity rule
- Always read `docs/sessions/README.md` and the latest files in `docs/sessions/*.md` before starting implementation.
- Treat `docs/sessions/*.md` as historical context for what was done and why; use that context to preserve standards and direction.
- For significant decisions or migrations, add/update a session note in `docs/sessions/` so future sessions can continue consistently.
