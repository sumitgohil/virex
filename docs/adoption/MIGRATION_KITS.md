# Feature Migration Kits

## Authentication kit
- Signalize form inputs and auth session flags.
- Use `AsyncSignal` for login and token refresh.

## List filtering kit
- Source list in `Signal<List<T>>`.
- Filter/sort/search in `Computed<List<T>>`.

## Forms kit
- Use `virex_forms` `FormSignalController`.
- Keep validation deterministic and testable.

## Async pagination kit
- Use `AsyncSignal` for page fetches.
- Preserve stale-response protection and cancel semantics.
