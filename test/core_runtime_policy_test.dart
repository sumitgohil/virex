import 'package:flutter_test/flutter_test.dart';
import 'package:virex/virex.dart';

import '_test_utils.dart';

void main() {
  setUp(resetRuntime);

  tearDown(() {
    configureVirexRuntime(const VirexRuntimeConfig());
  });

  test('hardFail policy throws on signal write during compute', () {
    final Signal<int> count = signal<int>(0, name: 'count');
    final Computed<int> invalid = computed<int>(() {
      if (count.value == 0) {
        count.value = 1;
      }
      return count.value;
    }, name: 'invalid');

    expect(
      () => invalid.value,
      throwsA(anyOf(isA<StateError>(), isA<AssertionError>())),
    );
  });

  test('deferNextEpoch policy applies write deterministically next epoch', () {
    configureVirexRuntime(
      const VirexRuntimeConfig(
        writeViolationPolicy: VirexWriteViolationPolicy.deferNextEpoch,
      ),
    );

    final Signal<int> count = signal<int>(0, name: 'count');
    final Computed<int> invalid = computed<int>(() {
      if (count.value == 0) {
        count.value = 1;
      }
      return count.value;
    }, name: 'invalid');

    expect(invalid.value, 0);
    expect(count.value, 0);

    VirexScheduler.instance.flush();
    expect(count.value, 1);

    invalid.dispose();
    count.dispose();
  });

  test('dropAndLog policy suppresses mutation and reports warning', () {
    configureVirexRuntime(
      const VirexRuntimeConfig(
        writeViolationPolicy: VirexWriteViolationPolicy.dropAndLog,
      ),
    );

    final List<Object> warnings = <Object>[];
    VirexScheduler.instance.onError = (Object error, StackTrace _) {
      warnings.add(error);
    };

    final Signal<int> count = signal<int>(0, name: 'count');
    final Computed<int> invalid = computed<int>(() {
      if (count.value == 0) {
        count.value = 1;
      }
      return count.value;
    }, name: 'invalid');

    expect(invalid.value, 0);
    expect(count.value, 0);
    expect(warnings, isNotEmpty);
  });

  test('metrics snapshot contains flush and p95 windows', () async {
    final Signal<int> count = signal<int>(0);
    final EffectHandle handle = effect(() {
      count.value;
    });

    for (int i = 0; i < 5; i++) {
      count.value = i + 1;
      VirexScheduler.instance.flush();
      await Future<void>.delayed(Duration.zero);
    }

    final VirexSchedulerMetrics metrics = VirexScheduler.instance
        .metricsSnapshot();
    expect(metrics.flushEpoch, greaterThanOrEqualTo(1));
    expect(metrics.lastFlushDuration, isNot(Duration.zero));
    expect(metrics.p95FlushDurationWindow, isNot(Duration.zero));

    handle.dispose();
    count.dispose();
  });
}
