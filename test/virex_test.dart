import 'package:flutter_test/flutter_test.dart';
import 'package:virex/virex.dart';

import '_test_utils.dart';

void main() {
  setUp(resetRuntime);

  test('public API smoke test', () {
    final Signal<int> count = signal<int>(1);
    final Computed<int> doubleCount = computed<int>(() => count.value * 2);

    expect(doubleCount.value, 2);
  });
}
