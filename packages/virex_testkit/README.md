# virex_testkit

Deterministic test and performance utilities for Virex.

Use `virex_testkit` to simplify runtime reset/flush control and benchmark budget validation in CI.

## Install

```bash
flutter pub add virex_testkit
```

## Import

```dart
import 'package:virex_testkit/virex_testkit.dart';
```

## Usage

Deterministic test harness:

```dart
final harness = VirexTestHarness();
harness.resetRuntime();

final counter = signal<int>(0);
effect(() => print(counter.value));

counter.value = 1;
harness.flush();
```

Performance budget checks:

```dart
const budget = VirexPerfBudget(
  maxUsPerOp: {'signal write throughput': 0.20},
);

final metrics = VirexPerfBudget.parseBenchmarkOutput(rawBenchmarkText);
final violations = budget.validate(metrics);
```

## API

- `final class VirexTestHarness`
- `final class VirexPerfBudget`
- `VirexPerfBudget.parseBenchmarkOutput(...)`
- `VirexPerfBudget.validate(...)`

## CI Integration

Typical flow:

1. Run benchmark suite.
2. Parse output.
3. Validate against `VirexPerfBudget`.
4. Fail pipeline on violations.

## Testing

```bash
cd packages/virex_testkit
dart test
```

## Benchmarking Notes

Run project benchmarks:

```bash
dart run benchmark/virex_benchmark.dart
```

Update/check baselines:

```bash
dart run tool/update_benchmark_baseline.dart benchmark/baseline.json
dart run tool/check_benchmark_regression.dart benchmark/baseline.json
```

## Related

- Core runtime: [`../../README.md`](../../README.md)
