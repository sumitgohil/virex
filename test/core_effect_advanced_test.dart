import 'package:flutter_test/flutter_test.dart';
import 'package:virex/virex.dart';

import '_test_utils.dart';

void main() {
  setUp(resetRuntime);

  test('immediate false effect runs only after scheduler flush', () {
    final Signal<int> source = signal<int>(0);
    int runs = 0;

    final EffectHandle handle = effect(() {
      source.value;
      runs += 1;
    }, immediate: false);

    expect(runs, 0);
    VirexScheduler.instance.flush();
    expect(runs, 1);

    handle.dispose();
    source.dispose();
  });

  test('throttle effect coalesces rapid updates', () async {
    final Signal<int> source = signal<int>(0);
    int runs = 0;

    final EffectHandle handle = effect(() {
      source.value;
      runs += 1;
    }, throttle: const Duration(milliseconds: 40));

    expect(runs, 1);
    source.value = 1;
    VirexScheduler.instance.flush();
    source.value = 2;
    VirexScheduler.instance.flush();
    source.value = 3;
    VirexScheduler.instance.flush();

    await Future<void>.delayed(const Duration(milliseconds: 60));
    VirexScheduler.instance.flush();

    expect(runs, 2);
    handle.dispose();
    source.dispose();
  });

  test('debounced effect does not run after dispose', () async {
    final Signal<int> source = signal<int>(0);
    int runs = 0;

    final EffectHandle handle = effect(
      () {
        source.value;
        runs += 1;
      },
      immediate: false,
      debounce: const Duration(milliseconds: 20),
    );

    source.value = 1;
    VirexScheduler.instance.flush();
    handle.dispose();

    await Future<void>.delayed(const Duration(milliseconds: 35));
    VirexScheduler.instance.flush();

    expect(runs, 0);
    source.dispose();
  });

  test('disposing effect inside callback is safe', () {
    final Signal<int> source = signal<int>(0);
    late final EffectHandle handle;
    int runs = 0;

    handle = effect(() {
      source.value;
      runs += 1;
      if (runs == 1) {
        handle.dispose();
      }
    }, immediate: false);

    VirexScheduler.instance.flush();
    source.value = 1;
    VirexScheduler.instance.flush();
    source.value = 2;
    VirexScheduler.instance.flush();

    expect(runs, 1);
    source.dispose();
  });
}
