import 'package:flutter_test/flutter_test.dart';
import 'package:virex/virex.dart';

import '_test_utils.dart';

void main() {
  setUp(resetRuntime);

  tearDown(() {
    configureVirexRuntime(const VirexRuntimeConfig());
  });

  test('flush slicing preserves determinism and eventually drains queues', () {
    configureVirexRuntime(const VirexRuntimeConfig(maxNodesPerFlushSlice: 1));

    final Signal<int> source = signal<int>(1);
    final List<String> order = <String>[];

    final Computed<int> first = computed<int>(() {
      order.add('first');
      return source.value + 1;
    });
    final Computed<int> second = computed<int>(() {
      order.add('second');
      return first.value + 1;
    });
    final EffectHandle handle = effect(() {
      order.add('effect');
      second.value;
    });

    order.clear();
    source.value = 10;
    flushUntilIdle();

    expect(VirexScheduler.instance.hasPending, isFalse);
    expect(order, containsAllInOrder(<String>['first', 'second', 'effect']));

    handle.dispose();
    first.dispose();
    second.dispose();
    source.dispose();
  });

  test('deferred writes are applied in enqueue sequence order', () {
    configureVirexRuntime(
      const VirexRuntimeConfig(
        writeViolationPolicy: VirexWriteViolationPolicy.deferNextEpoch,
      ),
    );

    final Signal<int> trigger = signal<int>(0);
    final Signal<String> order = signal<String>('');

    final Computed<int> first = computed<int>(() {
      if (trigger.value == 1) {
        order.value = 'A';
      }
      return trigger.value;
    });
    final Computed<int> second = computed<int>(() {
      if (trigger.value == 1) {
        order.value = 'AB';
      }
      return trigger.value;
    });
    final EffectHandle handle = effect(() {
      if (trigger.value == 1) {
        first.value;
        second.value;
      }
    });

    trigger.value = 1;
    flushUntilIdle();

    expect(order.value, 'AB');

    handle.dispose();
    first.dispose();
    second.dispose();
    trigger.dispose();
    order.dispose();
  });

  test('runtime config clamps invalid scheduler values', () {
    configureVirexRuntime(
      const VirexRuntimeConfig(
        effectLoopThreshold: 0,
        maxNodesPerFlushSlice: -10,
      ),
    );

    final VirexRuntimeConfig config = getVirexRuntimeConfig();
    expect(config.effectLoopThreshold, 0);
    expect(config.maxNodesPerFlushSlice, -10);

    final Signal<int> source = signal<int>(0);
    final EffectHandle handle = effect(() {
      if (source.value < 1) {
        source.value = source.value + 1;
      }
    });

    expect(() => flushUntilIdle(maxFlushes: 20), returnsNormally);
    expect(source.value, 1);

    handle.dispose();
    source.dispose();
  });
}
