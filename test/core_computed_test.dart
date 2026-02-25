import 'package:flutter_test/flutter_test.dart';
import 'package:virex/virex.dart';

import '_test_utils.dart';

void main() {
  setUp(resetRuntime);

  test('computed is lazy and cached until dependency changes', () {
    final Signal<int> a = signal<int>(2);
    int computeRuns = 0;

    final Computed<int> doubled = computed<int>(() {
      computeRuns += 1;
      return a.value * 2;
    });

    expect(computeRuns, 0);
    expect(doubled.value, 4);
    expect(computeRuns, 1);
    expect(doubled.value, 4);
    expect(computeRuns, 1);

    a.value = 4;
    expect(doubled.value, 8);
    expect(computeRuns, 2);
  });

  test('computed chains recompute in topological order', () {
    final Signal<int> a = signal<int>(1);
    final List<String> order = <String>[];

    final Computed<int> b = computed<int>(() {
      order.add('b');
      return a.value + 1;
    });

    final Computed<int> c = computed<int>(() {
      order.add('c');
      return b.value + 1;
    });

    final EffectHandle handle = effect(() {
      order.add('effect');
      c.value;
    });

    order.clear();
    a.value = 5;
    VirexScheduler.instance.flush();

    expect(order, containsAllInOrder(<String>['b', 'c', 'effect']));
    handle.dispose();
  });

  test('circular dependency throws circular error', () {
    late final Computed<int> first;
    late final Computed<int> second;

    first = computed<int>(() => second.value + 1);
    second = computed<int>(() => first.value + 1);

    expect(() => first.value, throwsA(isA<CircularDependencyError>()));
  });

  test('computed error rethrows until dependency changes', () {
    final Signal<int> source = signal<int>(0);
    final Computed<int> value = computed<int>(() {
      if (source.value == 0) {
        throw StateError('boom');
      }
      return source.value;
    });

    expect(() => value.value, throwsStateError);
    expect(() => value.value, throwsStateError);

    source.value = 2;
    expect(value.value, 2);
  });
}
