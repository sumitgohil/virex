# virex_observability

Observability bridge for Virex inspector events.

Use this package to pipe Virex runtime events into your telemetry backend.

## Install

```bash
flutter pub add virex_observability
```

## Import

```dart
import 'package:virex_observability/virex_observability.dart';
```

## Usage

Implement a sink:

```dart
final class LoggingSink implements VirexTelemetrySink {
  @override
  Future<void> record(VirexInspectorEvent event) async {
    print(event.toJson());
  }
}
```

Start bridge:

```dart
final bridge = VirexTelemetryBridge(
  inspector: VirexInspector.instance,
  sink: LoggingSink(),
);

bridge.start();
```

Stop bridge:

```dart
await bridge.stop();
```

## API

- `abstract interface class VirexTelemetrySink`
- `final class VirexTelemetryBridge`

## Behavior Notes

- `start()` is idempotent.
- sink failures are contained and do not break inspector consumption.
- call `stop()` on shutdown.

## Testing

```bash
cd packages/virex_observability
dart test
```

## Benchmarking Notes

Track event throughput and sink latency in your telemetry pipeline. For runtime metrics baseline, use core benchmarks:

```bash
dart run benchmark/virex_benchmark.dart
```

## Related

- Core runtime: [`../../README.md`](../../README.md)
