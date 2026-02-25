# Virex Benchmarks

Run all benchmark scenarios:

```bash
dart run benchmark/virex_benchmark.dart
```

## Scenarios
- Signal write throughput
- Batch flush latency and epoch behavior
- Deep computed-chain propagation
- Effect-loop guard overhead
- Rebuild count simulation (`setState` vs Virex)

## Baselines

Update baseline after an intentional optimization change:

```bash
dart run tool/update_benchmark_baseline.dart benchmark/baseline.json
```

Check current run against baseline (default max regression 25%):

```bash
dart run tool/check_benchmark_regression.dart benchmark/baseline.json
```

Custom regression threshold:

```bash
dart run tool/check_benchmark_regression.dart benchmark/baseline.json 15
```

Performance budget enforcement:

```bash
dart run tool/check_performance_budget.dart benchmark/performance_budget.json -
```
