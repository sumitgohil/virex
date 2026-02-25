import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:virex/virex.dart';

import '_test_utils.dart';

void main() {
  setUp(resetRuntime);

  test('10,000 signal updates remain stable', () {
    final Signal<int> counter = signal<int>(0);
    int effectRuns = 0;

    final EffectHandle handle = effect(() {
      counter.value;
      effectRuns += 1;
    });

    batch(() {
      for (int i = 1; i <= 10000; i++) {
        counter.value = i;
      }
    });

    VirexScheduler.instance.flush();

    expect(counter.value, 10000);
    expect(effectRuns, 2);

    handle.dispose();
  });

  test('deep computed chain resolves deterministically', () {
    const int depth = 200;
    final Signal<int> root = signal<int>(1);

    Computed<int> current = computed<int>(() => root.value + 1);
    for (int i = 0; i < depth; i++) {
      final Computed<int> previous = current;
      current = computed<int>(() => previous.value + 1);
    }

    expect(current.value, depth + 2);
    root.value = 2;
    expect(current.value, depth + 3);
  });

  testWidgets('signal builder survives rapid mount and unmount cycles', (
    WidgetTester tester,
  ) async {
    final Signal<bool> show = signal<bool>(true);
    final Signal<int> count = signal<int>(0);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SignalBuilder(
          builder: () {
            if (!show.value) {
              return const SizedBox.shrink();
            }
            return SignalBuilder(builder: () => Text('${count.value}'));
          },
        ),
      ),
    );

    for (int i = 0; i < 1000; i++) {
      show.value = i.isEven;
      count.value = i;
      VirexScheduler.instance.flush();
      await tester.pump();
    }

    expect(find.byType(SignalBuilder), findsAtLeastNWidgets(1));
  });
}
