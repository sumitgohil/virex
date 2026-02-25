import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:virex/virex.dart';

import '_test_utils.dart';

void main() {
  setUp(resetRuntime);

  test('trace ring buffer captures deterministic event sequence', () {
    final List<String> first = _runSeededScenario(42);
    resetRuntime();
    final List<String> second = _runSeededScenario(42);

    expect(second, first);
    expect(first, isNotEmpty);
  });
}

List<String> _runSeededScenario(int seed) {
  final Random random = Random(seed);
  final VirexInspector inspector = VirexInspector.instance;
  inspector.configureTrace(
    const VirexTraceConfig(
      mode: VirexTraceMode.ringBuffer,
      capacity: 2000,
      sampleEveryN: 1,
    ),
  );
  inspector.clearTrace();

  final List<Signal<int>> signals = List<Signal<int>>.generate(
    24,
    (int i) => signal<int>(i, name: 's$i'),
  );
  final List<Computed<int>> computeds = <Computed<int>>[
    computed<int>(() => signals[0].value + signals[1].value, name: 'c0'),
    computed<int>(() => signals[2].value * signals[3].value, name: 'c1'),
    computed<int>(() => signals[4].value - signals[5].value, name: 'c2'),
  ];
  final EffectHandle handle = effect(() {
    int total = 0;
    for (final Computed<int> node in computeds) {
      total += node.value;
    }
    if (total.isNegative) {
      signals[0].value = 0;
    }
  });

  for (int i = 0; i < 80; i++) {
    final int idx = random.nextInt(signals.length);
    final int next = random.nextInt(1000);
    signals[idx].value = next;
    if (i.isEven) {
      VirexScheduler.instance.flush();
    }
  }
  VirexScheduler.instance.flush();

  final List<String> normalized = inspector
      .getTraceSnapshot()
      .map((VirexTraceEvent event) {
        final String type = event.runtimeType.toString();
        final int nodeId = event.nodeId ?? -1;
        return '$type|${event.epoch}|$nodeId|${event.message ?? ''}';
      })
      .toList(growable: false);

  handle.dispose();
  for (final Computed<int> node in computeds) {
    node.dispose();
  }
  for (final Signal<int> node in signals) {
    node.dispose();
  }
  inspector.configureTrace(const VirexTraceConfig(mode: VirexTraceMode.off));
  return normalized;
}
