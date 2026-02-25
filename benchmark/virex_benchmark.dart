// ignore_for_file: avoid_print

import 'dart:math';

import 'package:virex/src/core/runtime.dart';
import 'package:virex/virex_core.dart';

void main() {
  ReactiveRuntime.instance.debugResetForTests();

  _run('signal write throughput', () {
    final Signal<int> counter = signal<int>(0);
    final Stopwatch watch = Stopwatch()..start();

    for (int i = 0; i < 100000; i++) {
      counter.value = i;
    }
    VirexScheduler.instance.flush();

    watch.stop();
    return _Result(
      operations: 100000,
      elapsedMs: watch.elapsedMicroseconds / 1000,
    );
  });

  _run('batch flush latency', () {
    final Signal<int> counter = signal<int>(0);
    final Stopwatch watch = Stopwatch()..start();

    batch(() {
      for (int i = 0; i < 10000; i++) {
        counter.value = i;
      }
    });
    VirexScheduler.instance.flush();

    watch.stop();
    return _Result(
      operations: 10000,
      elapsedMs: watch.elapsedMicroseconds / 1000,
    );
  });

  _run('computed chain propagation', () {
    final Signal<int> source = signal<int>(1);
    Computed<int> current = computed<int>(() => source.value + 1);
    for (int i = 0; i < 500; i++) {
      final Computed<int> prev = current;
      current = computed<int>(() => prev.value + 1);
    }

    final Stopwatch watch = Stopwatch()..start();
    source.value = 2;
    final int finalValue = current.value;
    watch.stop();

    if (finalValue < 0) {
      throw StateError('unreachable');
    }

    return _Result(
      operations: 500,
      elapsedMs: watch.elapsedMicroseconds / 1000,
    );
  });

  _run('effect loop guard overhead', () {
    final Signal<int> source = signal<int>(0);
    int runs = 0;

    final EffectHandle handle = effect(() {
      runs += 1;
      if (source.value < 20) {
        source.value = source.value + 1;
      }
    });

    final Stopwatch watch = Stopwatch()..start();
    VirexScheduler.instance.flush();
    watch.stop();

    handle.dispose();
    return _Result(
      operations: max(runs, 1),
      elapsedMs: watch.elapsedMicroseconds / 1000,
    );
  });

  _run('scheduler metrics snapshot', () {
    final Signal<int> source = signal<int>(0);
    final EffectHandle handle = effect(() {
      source.value;
    });
    source.value = 1;
    VirexScheduler.instance.flush();
    final Stopwatch watch = Stopwatch()..start();
    final VirexSchedulerMetrics metrics = VirexScheduler.instance
        .metricsSnapshot();
    watch.stop();
    handle.dispose();
    if (metrics.flushEpoch < 1) {
      throw StateError('metrics snapshot invalid');
    }
    return _Result(operations: 1, elapsedMs: watch.elapsedMicroseconds / 1000);
  });

  _run('rebuild count simulation', () {
    int setStateRebuilds = 0;
    int virexRebuilds = 0;

    for (int i = 0; i < 5000; i++) {
      setStateRebuilds += 1;
    }

    final Signal<int> state = signal<int>(0);
    final EffectHandle handle = effect(() {
      state.value;
      virexRebuilds += 1;
    });

    batch(() {
      for (int i = 0; i < 5000; i++) {
        state.value = i;
      }
    });
    VirexScheduler.instance.flush();

    handle.dispose();

    print('  setState simulated rebuilds: $setStateRebuilds');
    print('  Virex reactive rebuilds: $virexRebuilds');

    return _Result(operations: 5000, elapsedMs: 0);
  });
}

void _run(String label, _Result Function() body) {
  ReactiveRuntime.instance.debugResetForTests();
  final _Result result = body();
  final double usPerOp = result.operations == 0
      ? 0
      : (result.elapsedMs * 1000) / result.operations;

  print(label);
  print('  operations: ${result.operations}');
  print('  elapsed_ms: ${result.elapsedMs.toStringAsFixed(3)}');
  print('  us_per_op: ${usPerOp.toStringAsFixed(4)}');
}

final class _Result {
  const _Result({required this.operations, required this.elapsedMs});

  final int operations;
  final double elapsedMs;
}
