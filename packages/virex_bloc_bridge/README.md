# virex_bloc_bridge

BLoC/Cubit interoperability bridge for Virex.

Use this package when migrating feature-by-feature from BLoC/Cubit to Virex without rewriting your full app at once.

## Install

```bash
flutter pub add virex_bloc_bridge
```

## Import

```dart
import 'package:virex_bloc_bridge/virex_bloc_bridge.dart';
```

## Usage

Mirror a Cubit state into a Virex signal:

```dart
final Signal<int> counter = signalFromCubit<int>(counterCubit, name: 'counter');
```

Bridge Virex effects to BLoC event emitters:

```dart
final emitLogin = effectToBlocEvent<LoginEvent>((event) {
  bloc.add(event);
});

effect(() {
  if (shouldLogin.value) {
    emitLogin(LoginRequested(username.value));
  }
});
```

Generate migration diagnostics metadata:

```dart
final report = blocMigrationReport(
  feature: 'checkout',
  riskFlags: ['event-ordering'],
  rollbackSteps: ['re-enable bloc path'],
);
```

## API

- `signalFromCubit<S>(Cubit<S> cubit, {String? name})`
- `effectToBlocEvent<E>(void Function(E event) emit)`
- `blocMigrationReport(...)`

## Testing

```bash
cd packages/virex_bloc_bridge
dart test
```

## Benchmarking Notes

This bridge is intentionally thin. Benchmark your migrated feature with core tools:

```bash
dart run benchmark/virex_benchmark.dart
```

## Related

- Core runtime: [`../../README.md`](../../README.md)
- Riverpod bridge: [`../virex_riverpod_bridge/README.md`](../virex_riverpod_bridge/README.md)
