# API Stability Policy

Virex `2.x` follows semantic versioning.

## Stable public API

The following exports are considered stable for all `2.x` releases:
- `Signal<T>` and `signal<T>(...)`
- `Computed<T>` and `computed<T>(...)`
- `EffectHandle` and `effect(...)`
- `AsyncSignal<T>`, `asyncSignal<T>(...)`, and `AsyncState<T>`
- `batch(...)`
- `VirexScheduler` public control and metrics getters
- `VirexInspector` public inspector methods
- `SignalBuilder`
- `package:virex/virex.dart` and `package:virex/virex_core.dart` entrypoints

## Compatibility guarantees
- Public API signatures are not removed or changed in a breaking way within `2.x`.
- Behavioral changes that alter deterministic runtime semantics are treated as breaking changes.
- New APIs may be added in minor releases.
- Bug fixes and non-breaking performance improvements ship in patch releases.

## Breaking change process
- Breaking changes require a major version bump (`2.0.0`).
- Migration guidance is required in `MIGRATION.md`.
- Changelog entries must clearly identify breaking behavior.
