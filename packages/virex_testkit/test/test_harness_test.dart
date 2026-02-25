import 'package:test/test.dart';
import 'package:virex/virex_core.dart';
import 'package:virex_testkit/virex_testkit.dart';

void main() {
  test('harness flush applies reactive updates', () {
    final VirexTestHarness harness = VirexTestHarness();
    harness.resetRuntime();

    final Signal<int> counter = signal<int>(0);
    int runs = 0;

    final EffectHandle handle = effect(() {
      counter.value;
      runs += 1;
    });

    counter.value = 2;
    harness.flush();

    expect(runs, 2);

    handle.dispose();
    counter.dispose();
  });
}
