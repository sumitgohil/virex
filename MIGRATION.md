# Migration to Virex

## V2 breaking note

V2 defaults to strict runtime safety:
- `Signal` writes during `COMPUTING` now `hardFail` (throw in release, assert in debug).
- Use runtime config to opt into transition policies if needed:

```dart
configureVirexRuntime(
  const VirexRuntimeConfig(
    writeViolationPolicy: VirexWriteViolationPolicy.deferNextEpoch,
  ),
);
```

## From setState

### Before

```dart
setState(() {
  count += 1;
});
```

### After

```dart
final count = signal<int>(0);
count.value += 1;
```

Use `SignalBuilder` to rebuild only where needed.

## From Riverpod

### Before
Provider declarations and `ref.watch(...)` in widgets.

### After
Use direct primitives:
- `signal` for mutable state
- `computed` for derived values
- `effect` for side effects

```dart
final items = signal<List<Item>>(<Item>[]);
final total = computed(() => items.value.length);
```

## From BLoC

### Before
Events + states + stream transforms.

### After
Model local/stateful domains with signals and computeds. Keep BLoC-like boundaries where needed, but internal updates can be direct and deterministic.

## Incremental Strategy

1. Start with leaf widgets using `SignalBuilder`.
2. Replace local `setState` with `signal`.
3. Move derived values into `computed`.
4. Move side effects into `effect`.
5. Migrate async loading to `AsyncSignal`.
6. Add inspector snapshots and benchmark checks.

## V0 to V1

If you adopted early `0.x` builds:

1. Use stable entrypoints:
   - `package:virex/virex.dart` for Flutter apps
   - `package:virex/virex_core.dart` for pure Dart runtimes
2. Align to `1.x` API stability policy in `API_STABILITY.md`.
3. Add CI coverage and benchmark checks for runtime-sensitive PRs.

## V1 to V2

1. Audit all `computed(...)` callbacks and remove writes to any signal state.
2. If temporary compatibility is needed, use `deferNextEpoch` while refactoring.
3. Add tests for deterministic order and write-policy expectations.
4. Enable scale tier in nightly/release workflows.
