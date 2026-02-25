# virex_router_bridge

Router synchronization adapter for Virex.

Use this package to keep URL/router state and signal state in sync with deterministic updates.

## Install

```bash
flutter pub add virex_router_bridge
```

## Import

```dart
import 'package:virex_router_bridge/virex_router_bridge.dart';
```

## Usage

Implement `RouterDriver` for your routing layer:

```dart
final class AppRouterDriver implements RouterDriver {
  @override
  String get location => router.currentLocation;

  @override
  Stream<String> get onLocationChanged => router.locationStream;

  @override
  void go(String location) => router.go(location);
}
```

Bind it to Virex:

```dart
final adapter = RouterSignalAdapter(driver: AppRouterDriver());

effect(() {
  print('route=${adapter.route.value}');
});
```

Update route through signal:

```dart
adapter.route.value = '/settings';
```

## API

- `abstract interface class RouterDriver`
- `final class RouterSignalAdapter`

## Disposal

Always call `dispose()`:

```dart
adapter.dispose();
```

## Testing

```bash
cd packages/virex_router_bridge
dart test
```

## Benchmarking Notes

Track navigation transition and rebuild cost in your app and compare with core benchmarks:

```bash
dart run benchmark/virex_benchmark.dart
```

## Related

- Core runtime: [`../../README.md`](../../README.md)
