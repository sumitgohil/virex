# Virex

Deterministic, signal-first reactive runtime for Flutter and Dart.

Virex is optimized for predictable execution, fine-grained updates, and production observability. It is a runtime, not a framework.

## Why Virex

- Fine-grained reactivity (`Signal`, `Computed`, `Effect`)
- Deterministic flush scheduler (computed fixed-point before effects)
- Strict runtime safety defaults in V2 (`hardFail` write policy during `COMPUTING`)
- Debuggability: inspector events, trace ring buffer, invariant checks, metrics
- Scales to stress workloads with dedicated scale tests (`500k/50k`)

## Install

```bash
flutter pub add virex
```

For pure Dart or server-side use:

```dart
import 'package:virex/virex_core.dart';
```

For Flutter UI bindings:

```dart
import 'package:virex/virex.dart';
```

## Quick Start

```dart
import 'package:virex/virex.dart';

final count = signal<int>(0, name: 'count');
final doubled = computed<int>(() => count.value * 2, name: 'doubled');

final EffectHandle logEffect = effect(() {
  print('count=${count.value}, doubled=${doubled.value}');
});

batch(() {
  count.value = 1;
  count.value = 2;
});

logEffect.dispose();
count.dispose();
doubled.dispose();
```

## Flutter Usage

`SignalBuilder` subscribes only to values read inside its `builder`:

```dart
class CounterText extends StatelessWidget {
  const CounterText({super.key, required this.count});

  final Signal<int> count;

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(
      builder: () => Text('Count: ${count.value}'),
    );
  }
}
```

## Core Primitives

### `Signal<T>`

```dart
final price = signal<double>(99.0, name: 'price');
price.value = 109.0;
```

### `Computed<T>`

```dart
final qty = signal<int>(2);
final total = computed<double>(() => price.value * qty.value);
```

### `Effect`

```dart
final EffectHandle handle = effect(
  () => print(total.value),
  debounce: const Duration(milliseconds: 16),
);
```

### `AsyncSignal<T>`

```dart
final user = asyncSignal<Map<String, Object?>>(
  () async => {'name': 'Virex'},
  autoStart: true,
  maxRetries: 2,
);
```

### `batch`

```dart
batch(() {
  price.value = 100;
  qty.value = 3;
});
```

## Runtime Semantics (V2)

- Phases: `IDLE`, `TRACKING`, `FLUSHING`, `COMPUTING`, `EFFECT_RUNNING`
- Default write policy: writes during `COMPUTING` throw (`hardFail`)
- Strict ordering: computed queue reaches fixed point before effect queue runs
- Epoch versioning: deterministic dedupe and replay-friendly traces
- Loop containment: effect loop thresholds prevent scheduler hangs
- Debug invariants: graph reciprocity, queue integrity, dirty-node checks

Configure runtime:

```dart
configureVirexRuntime(
  const VirexRuntimeConfig(
    writeViolationPolicy: VirexWriteViolationPolicy.hardFail,
    effectLoopThreshold: 100,
    maxNodesPerFlushSlice: 0,
    enableInvariantAuditInDebug: true,
  ),
);
```

## Inspector, Trace, and Metrics

```dart
final inspector = VirexInspector.instance;

inspector.registerVmServiceExtensions();
inspector.configureSampling(maxEventsPerSecond: 120);
inspector.enableTimeline(enabled: true);
inspector.configureTrace(
  const VirexTraceConfig(
    mode: VirexTraceMode.ringBuffer,
    capacity: 20000,
    sampleEveryN: 1,
  ),
);

final snapshot = inspector.snapshot();
final metrics = VirexScheduler.instance.metricsSnapshot();
print('epoch=${snapshot.flushEpoch}, p95=${metrics.p95FlushDurationWindow}');
```

Service extensions:

- `ext.virex.snapshot`
- `ext.virex.auto_snapshots`
- `ext.virex.invariants`

## Benchmarks

Run benchmark suite:

```bash
dart run benchmark/virex_benchmark.dart
```

Update/check baselines:

```bash
dart run tool/update_benchmark_baseline.dart benchmark/baseline.json
dart run tool/check_benchmark_regression.dart benchmark/baseline.json
dart run tool/check_performance_budget.dart benchmark/performance_budget.json -
```

Scale test tiers:

- Fast suite: `flutter test --exclude-tags scale`
- Extreme suite: `flutter test --tags scale`
- Nightly soak: `dart run tool/scale_soak.dart --duration-hours=8`

More benchmark details: [`benchmark/README.md`](benchmark/README.md)

## Testing

Core tests:

```bash
flutter test --exclude-tags scale
```

Scale tests:

```bash
flutter test --tags scale
```

## Example App

`/example` includes production-style modules:

- authentication
- dashboard
- todo (500+ items)
- cart
- theme switching
- profile editor
- infinite list
- performance lab

## Packages in This Monorepo

- [`packages/virex_devtools`](packages/virex_devtools/README.md)
- [`packages/virex_persist`](packages/virex_persist/README.md)
- [`packages/virex_riverpod_bridge`](packages/virex_riverpod_bridge/README.md)
- [`packages/virex_bloc_bridge`](packages/virex_bloc_bridge/README.md)
- [`packages/virex_observability`](packages/virex_observability/README.md)
- [`packages/virex_testkit`](packages/virex_testkit/README.md)
- [`packages/virex_router_bridge`](packages/virex_router_bridge/README.md)
- [`packages/virex_forms`](packages/virex_forms/README.md)

## Documentation

- [Docs Index](docs/README.md)
- [Architecture](ARCHITECTURE.md)
- [Migration](MIGRATION.md)
- [V2 Notes](V2.md)
- [API Stability](API_STABILITY.md)
- [12-Month Roadmap](ROADMAP_12_MONTHS.md)

Adoption and governance docs:

- [`docs/adoption`](docs/adoption)
- [`docs/governance`](docs/governance)
- [`docs/ecosystem`](docs/ecosystem)
- [`docs/metrics`](docs/metrics)

## FAQ

### Is Virex a full app architecture?
No. Virex is a reactive runtime. Use it with your existing architecture.

### Can I use it without Flutter?
Yes. Import `package:virex/virex_core.dart`.

### How do I compare it with `setState` or other libraries?
Use the benchmark suite in `/benchmark` and the performance module in `/example`.

## License

MIT
