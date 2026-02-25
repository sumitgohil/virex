# virex_persist

Persistence primitives for Virex signals.

`virex_persist` lets you hydrate and persist signal state with pluggable stores and adapters.

## Install

```bash
flutter pub add virex_persist
```

## Import

```dart
import 'package:virex_persist/virex_persist.dart';
```

## Quick Start

```dart
final store = MemoryVirexStore();

final persisted = await PersistedSignal<int>.create(
  key: 'counter',
  initial: 0,
  store: store,
  toStorage: (value) => value.toString(),
  fromStorage: int.parse,
);

persisted.node.value = 10;
VirexScheduler.instance.flush();
```

## Flush Policy

```dart
const policy = PersistedSignalPolicy(
  flushPolicy: PersistFlushPolicy.debounced,
  conflictResolution: PersistConflictResolution.preferMemory,
  migrationVersion: 1,
);
```

Use in `create(...)`:

```dart
final persisted = await PersistedSignal<String>.create(
  key: 'token',
  initial: '',
  store: store,
  toStorage: (value) => value,
  fromStorage: (raw) => raw,
  policy: policy,
  writeDebounce: const Duration(milliseconds: 120),
);
```

## Built-In Adapters

- `SharedPreferencesVirexStore` (`SharedPreferencesLike`)
- `HiveVirexStore` (`KeyValueBoxLike`)
- `EncryptedVirexStore` (`EncryptedStoreLike`)
- `MemoryVirexStore` (in-memory/testing)

## API

- `PersistedSignal<T>.create(...)`
- `PersistedSignal<T>.clearPersistedValue()`
- `PersistedSignal<T>.dispose()`
- `PersistedSignalPolicy`
- `VirexStore` and adapter interfaces

## Testing

```bash
cd packages/virex_persist
dart test
```

## Benchmarking Notes

`virex_persist` performance depends on store I/O and write debounce policy. Benchmark end-to-end in app context, and pair with core scheduler benchmarks:

```bash
dart run benchmark/virex_benchmark.dart
```

## Related

- Core runtime: [`../../README.md`](../../README.md)
