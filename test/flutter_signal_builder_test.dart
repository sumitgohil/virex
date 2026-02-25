import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:virex/virex.dart';

import '_test_utils.dart';

void main() {
  setUp(resetRuntime);

  testWidgets('SignalBuilder rebuilds only on subscribed signal updates', (
    WidgetTester tester,
  ) async {
    final Signal<int> count = signal<int>(0);
    final Signal<int> other = signal<int>(0);
    int builds = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: SignalBuilder(
          builder: () {
            builds += 1;
            return Text('count=${count.value}');
          },
        ),
      ),
    );

    expect(builds, 1);

    other.value = 99;
    VirexScheduler.instance.flush();
    await tester.pump();
    expect(builds, 1);

    count.value = 1;
    VirexScheduler.instance.flush();
    await tester.pump();
    expect(builds, 2);
  });

  testWidgets('nested SignalBuilders update independently', (
    WidgetTester tester,
  ) async {
    final Signal<int> outer = signal<int>(0);
    final Signal<int> inner = signal<int>(0);

    int outerBuilds = 0;
    int innerBuilds = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: SignalBuilder(
          builder: () {
            outerBuilds += 1;
            outer.value;
            return Column(
              children: <Widget>[
                const Text('outer'),
                SignalBuilder(
                  builder: () {
                    innerBuilds += 1;
                    return Text('inner=${inner.value}');
                  },
                ),
              ],
            );
          },
        ),
      ),
    );

    inner.value = 1;
    VirexScheduler.instance.flush();
    await tester.pump();

    expect(outerBuilds, 1);
    expect(innerBuilds, 2);
  });
}
