import 'package:flutter_test/flutter_test.dart';
import 'package:virex/virex.dart';

import '_test_utils.dart';

void main() {
  setUp(resetRuntime);

  test('signal reads and writes values', () {
    final Signal<int> count = signal<int>(0);
    expect(count.value, 0);

    count.value = 1;
    expect(count.value, 1);
  });

  test('setting same value does not notify effects', () {
    final Signal<int> count = signal<int>(0);
    int runs = 0;

    final EffectHandle handle = effect(() {
      count.value;
      runs += 1;
    });

    expect(runs, 1);
    count.value = 0;
    VirexScheduler.instance.flush();
    expect(runs, 1);

    handle.dispose();
  });

  test('custom equality skips updates', () {
    final Signal<List<int>> list = signal<List<int>>(<int>[
      1,
    ], equals: (List<int> a, List<int> b) => a.length == b.length);
    int runs = 0;

    final EffectHandle handle = effect(() {
      list.value;
      runs += 1;
    });

    list.value = <int>[2];
    VirexScheduler.instance.flush();
    expect(runs, 1);

    list.value = <int>[2, 3];
    VirexScheduler.instance.flush();
    expect(runs, 2);

    handle.dispose();
  });

  test('nested batch coalesces effect runs', () {
    final Signal<int> count = signal<int>(0);
    int runs = 0;

    final EffectHandle handle = effect(() {
      count.value;
      runs += 1;
    });

    batch(() {
      count.value = 1;
      batch(() {
        count.value = 2;
      });
      count.value = 3;
    });

    VirexScheduler.instance.flush();
    expect(runs, 2);

    handle.dispose();
  });

  test('disposed signal rejects writes in debug mode', () {
    final Signal<int> count = signal<int>(0);
    count.dispose();
    expect(() => count.value = 10, throwsA(isA<AssertionError>()));

    expect(count.disposed, isTrue);
  });
}
