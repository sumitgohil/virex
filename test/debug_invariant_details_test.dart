import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:virex/src/core/runtime.dart';
import 'package:virex/virex.dart';

import '_test_utils.dart';

void main() {
  setUp(resetRuntime);

  test('inspector emits invariant failure details', () async {
    final List<VirexInspectorEvent> events = <VirexInspectorEvent>[];
    final StreamSubscription<VirexInspectorEvent> sub = VirexInspector
        .instance
        .events
        .listen(events.add);

    final Signal<int> count = signal<int>(0, name: 'count');
    ReactiveRuntime.instance.graph
        .recordOf(count.nodeId)
        .dependencies
        .add(999999);

    final bool ok = VirexInspector.instance.debugCheckInvariants();
    await Future<void>.delayed(Duration.zero);

    expect(ok, isFalse);
    expect(
      events.any((VirexInspectorEvent e) => e is VirexInvariantFailureEvent),
      isTrue,
    );

    await sub.cancel();
    count.dispose();
  });
}
