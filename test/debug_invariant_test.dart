import 'package:flutter_test/flutter_test.dart';
import 'package:virex/virex.dart';

import '_test_utils.dart';

void main() {
  setUp(resetRuntime);

  test('graph invariants hold after flush', () {
    final Signal<int> value = signal<int>(0);
    final Computed<int> doubled = computed<int>(() => value.value * 2);
    final EffectHandle handle = effect(() {
      doubled.value;
    });

    value.value = 2;
    VirexScheduler.instance.flush();

    expect(VirexInspector.instance.debugCheckInvariants(), isTrue);

    handle.dispose();
  });
}
