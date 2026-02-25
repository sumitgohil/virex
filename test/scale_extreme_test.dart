@Tags(<String>['scale'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:virex/virex.dart';

import '_test_utils.dart';

void main() {
  setUp(resetRuntime);

  test('500k signal mutation wave', () {
    const int total = 500000;
    final List<Signal<int>> signals = List<Signal<int>>.generate(
      total,
      (int i) => signal<int>(i),
      growable: false,
    );

    for (int i = 0; i < total; i++) {
      signals[i].value = i + 1;
    }
    VirexScheduler.instance.flush();

    expect(signals[0].value, 1);
    expect(signals[total - 1].value, total);

    for (final Signal<int> node in signals) {
      node.dispose();
    }
  }, timeout: const Timeout(Duration(minutes: 10)));

  test('50k effect invalidation wave', () {
    const int totalEffects = 50000;
    final Signal<int> source = signal<int>(0);
    final List<EffectHandle> effects = <EffectHandle>[];
    int observed = 0;

    for (int i = 0; i < totalEffects; i++) {
      effects.add(
        effect(() {
          observed += source.value;
        }),
      );
    }

    source.value = 1;
    VirexScheduler.instance.flush();

    expect(observed, greaterThanOrEqualTo(totalEffects));

    for (final EffectHandle handle in effects) {
      handle.dispose();
    }
    source.dispose();
  }, timeout: const Timeout(Duration(minutes: 10)));

  test(
    '1M cumulative create/dispose operations recover registry baseline',
    () {
      const int rounds = 100;
      const int perRound = 10000;

      for (int r = 0; r < rounds; r++) {
        final List<Signal<int>> signals = List<Signal<int>>.generate(
          perRound,
          (int i) => signal<int>(i),
          growable: false,
        );
        for (final Signal<int> node in signals) {
          node.dispose();
        }
      }

      final VirexGraphSnapshot snapshot = VirexInspector.instance.snapshot();
      expect(snapshot.nodes, isEmpty);
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );
}
