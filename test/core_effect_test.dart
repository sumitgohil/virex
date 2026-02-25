import 'package:flutter_test/flutter_test.dart';
import 'package:virex/virex.dart';

import '_test_utils.dart';

void main() {
  setUp(resetRuntime);

  test('effect runs immediately and tracks dependencies', () {
    final Signal<int> count = signal<int>(0);
    int runs = 0;

    final EffectHandle handle = effect(() {
      count.value;
      runs += 1;
    });

    expect(runs, 1);
    count.value = 1;
    VirexScheduler.instance.flush();
    expect(runs, 2);

    handle.dispose();
  });

  test('effect errors are reported and effect stays subscribed', () {
    final Signal<int> count = signal<int>(0);
    int errors = 0;
    int runs = 0;

    final EffectHandle handle = effect(
      () {
        runs += 1;
        if (count.value == 1) {
          throw StateError('fail once');
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        errors += 1;
      },
    );

    count.value = 1;
    VirexScheduler.instance.flush();
    count.value = 2;
    VirexScheduler.instance.flush();

    expect(errors, 1);
    expect(runs, 3);

    handle.dispose();
  });

  test('effect can write signals and remains loop guarded', () {
    final Signal<int> count = signal<int>(0);
    int runs = 0;

    final EffectHandle handle = effect(() {
      runs += 1;
      if (count.value > 0 && count.value < 3) {
        count.value = count.value + 1;
      }
    });

    count.value = 1;
    VirexScheduler.instance.flush();
    expect(count.value, 3);
    expect(runs, greaterThanOrEqualTo(1));

    handle.dispose();
  });

  test('debounced effect runs once for burst updates', () async {
    final Signal<int> count = signal<int>(0);
    int runs = 0;

    final EffectHandle handle = effect(
      () {
        count.value;
        runs += 1;
      },
      immediate: false,
      debounce: const Duration(milliseconds: 20),
    );

    count.value = 1;
    count.value = 2;
    count.value = 3;
    VirexScheduler.instance.flush();

    await Future<void>.delayed(const Duration(milliseconds: 40));
    VirexScheduler.instance.flush();

    expect(runs, 1);
    handle.dispose();
  });
}
