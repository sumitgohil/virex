import 'package:flutter_test/flutter_test.dart';
import 'package:virex/virex.dart';

import '_test_utils.dart';

void main() {
  setUp(resetRuntime);

  test('epoch increments once per flush cycle', () {
    final Signal<int> count = signal<int>(0);
    final EffectHandle handle = effect(() {
      count.value;
    });

    final int before = VirexScheduler.instance.flushEpoch;
    count.value = 1;
    VirexScheduler.instance.flush();
    final int afterFirst = VirexScheduler.instance.flushEpoch;

    count.value = 2;
    VirexScheduler.instance.flush();
    final int afterSecond = VirexScheduler.instance.flushEpoch;

    expect(afterFirst, before + 1);
    expect(afterSecond, afterFirst + 1);
    handle.dispose();
  });

  test('node is not enqueued twice in same epoch', () {
    final Signal<int> count = signal<int>(0);
    int runs = 0;

    final EffectHandle handle = effect(() {
      count.value;
      runs += 1;
    });

    count.value = 1;
    count.value = 2;
    count.value = 3;

    VirexScheduler.instance.flush();

    expect(runs, 2);

    handle.dispose();
  });

  test('inspector exposes epoch metadata', () {
    final Signal<int> count = signal<int>(0, name: 'count');
    final EffectHandle handle = effect(() {
      count.value;
    });

    count.value = 1;
    VirexScheduler.instance.flush();

    final VirexGraphSnapshot snapshot = VirexInspector.instance.snapshot();
    expect(snapshot.flushEpoch, greaterThanOrEqualTo(1));
    expect(
      snapshot.nodes.any((VirexNodeSnapshot n) => n.lastEnqueuedEpoch >= 0),
      isTrue,
    );

    handle.dispose();
  });

  test('deferred write callback errors do not stall scheduler', () {
    final Signal<int> source = signal<int>(0);
    final Signal<int> target = signal<int>(0);
    final List<Object> errors = <Object>[];

    VirexScheduler.instance.onError = (Object error, StackTrace _) {
      errors.add(error);
    };

    VirexScheduler.instance.deferWrite(
      sourceId: source.nodeId,
      apply: () => throw StateError('deferred write failure'),
    );

    expect(() => VirexScheduler.instance.flush(), returnsNormally);

    final EffectHandle handle = effect(() {
      target.value;
    });
    target.value = 1;
    expect(() => VirexScheduler.instance.flush(), returnsNormally);
    expect(target.value, 1);
    expect(errors, isNotEmpty);

    handle.dispose();
    source.dispose();
    target.dispose();
    VirexScheduler.instance.onError = null;
  });
}
