# virex_riverpod_bridge

Riverpod interoperability bridge for Virex.

This package helps teams migrate incrementally between Riverpod and Virex.

## Install

```bash
flutter pub add virex_riverpod_bridge
```

## Import

```dart
import 'package:virex_riverpod_bridge/virex_riverpod_bridge.dart';
```

## Usage

Expose a Virex signal as a Riverpod provider:

```dart
final counterSignal = signal<int>(0, name: 'counter');
final counterProvider = riverpodSignalProvider<int>(counterSignal);
```

Mirror Riverpod `StateNotifier` state into Virex:

```dart
final Signal<AppState> appState = signalFromStateNotifier<AppState>(
  notifier,
  name: 'app_state',
);
```

Create migration metadata:

```dart
final report = riverpodMigrationReport(
  feature: 'feed',
  riskFlags: ['provider-scope'],
);
```

## API

- `riverpodSignalProvider<T>(Signal<T> signal)`
- `signalFromStateNotifier<T>(StateNotifier<T> notifier, {String? name})`
- `SignalNotifier<T>`
- `riverpodMigrationReport(...)`

## Testing

```bash
cd packages/virex_riverpod_bridge
dart test
```

## Benchmarking Notes

Measure feature-level rebuild and flush metrics in your app, then compare against Virex core benchmark output:

```bash
dart run benchmark/virex_benchmark.dart
```

## Related

- Core runtime: [`../../README.md`](../../README.md)
- BLoC bridge: [`../virex_bloc_bridge/README.md`](../virex_bloc_bridge/README.md)
