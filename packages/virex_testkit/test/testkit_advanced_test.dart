import 'dart:async';

import 'package:test/test.dart';
import 'package:virex/virex_core.dart';
import 'package:virex_testkit/virex_testkit.dart';

void main() {
  setUp(debugResetVirexForTests);

  test('parseBenchmarkOutput extracts us_per_op metrics', () {
    const String raw = '''
signal write throughput
  samples: 120000
  us_per_op: 0.1210

computed chain
  samples: 50000
  us_per_op: 0.3340

ignored:
  value: 10
''';

    final Map<String, double> metrics = VirexPerfBudget.parseBenchmarkOutput(
      raw,
    );
    expect(metrics['signal write throughput'], 0.121);
    expect(metrics['computed chain'], 0.334);
    expect(metrics.containsKey('ignored'), isFalse);
  });

  test('validate reports missing and exceeded metrics', () {
    const VirexPerfBudget budget = VirexPerfBudget(
      maxUsPerOp: <String, double>{
        'signal write throughput': 0.2,
        'computed chain': 0.4,
      },
    );

    final List<String> violations = budget.validate(<String, double>{
      'signal write throughput': 0.25,
    });

    expect(violations.length, 2);
    expect(violations.join('\n'), contains('exceeded budget'));
    expect(violations.join('\n'), contains('Missing metric: computed chain'));
  });

  test('harness flush reports false when no pending work exists', () {
    final VirexTestHarness harness = VirexTestHarness();
    harness.resetRuntime();

    expect(harness.flush(), isFalse);
  });

  test('pumpMicrotasks with non-positive value still pumps once', () async {
    final VirexTestHarness harness = VirexTestHarness();
    harness.resetRuntime();

    int ticks = 0;
    scheduleMicrotask(() {
      ticks += 1;
    });

    await harness.pumpMicrotasks(0);
    expect(ticks, 1);
  });

  test('resetRuntime clears graph state created before harness boundary', () {
    final VirexTestHarness harness = VirexTestHarness();

    final Signal<int> source = signal<int>(0);
    final EffectHandle handle = effect(() {
      source.value;
    });
    VirexScheduler.instance.flush();

    expect(VirexInspector.instance.snapshot().nodes, isNotEmpty);
    harness.resetRuntime();
    expect(VirexInspector.instance.snapshot().nodes, isEmpty);

    handle.dispose();
    source.dispose();
  });
}
