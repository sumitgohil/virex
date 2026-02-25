# Performance Checklist

- [ ] `SignalBuilder` wraps only leaf UI, not entire screens.
- [ ] Derived logic is in `Computed`, not widget `build` methods.
- [ ] Batched write paths use `batch(...)`.
- [ ] Async race-prone calls use `AsyncSignal`.
- [ ] No signal writes from computed callbacks.
- [ ] Benchmark output checked against `benchmark/performance_budget.json`.
- [ ] Fast and scale test tiers are both green.

## Commands

```bash
flutter test --exclude-tags scale
flutter test --tags scale
dart run benchmark/virex_benchmark.dart
dart run tool/check_performance_budget.dart benchmark/performance_budget.json -
```
