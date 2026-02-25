import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:virex/virex.dart';

import '_test_utils.dart';

void main() {
  setUp(resetRuntime);

  test('inspector emits typed events', () async {
    final List<VirexInspectorEvent> events = <VirexInspectorEvent>[];
    final StreamSubscription<VirexInspectorEvent> sub = VirexInspector
        .instance
        .events
        .listen(events.add);

    VirexInspector.instance.configureSampling(maxEventsPerSecond: 500);
    VirexInspector.instance.setAutoSnapshots(enabled: true);

    final Signal<int> value = signal<int>(0);
    final EffectHandle handle = effect(() {
      value.value;
    });

    value.value = 1;
    VirexScheduler.instance.flush();
    VirexInspector.instance.debugCheckInvariants();

    await Future<void>.delayed(Duration.zero);

    expect(events.any((VirexInspectorEvent e) => e is VirexFlushEvent), isTrue);
    expect(
      events.any((VirexInspectorEvent e) => e is VirexSnapshotEvent),
      isTrue,
    );
    expect(
      events.any((VirexInspectorEvent e) => e is VirexInvariantEvent),
      isTrue,
    );

    handle.dispose();
    value.dispose();
    await sub.cancel();
    VirexInspector.instance.setAutoSnapshots(enabled: false);
  });
}
