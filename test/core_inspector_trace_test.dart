import 'package:flutter_test/flutter_test.dart';
import 'package:virex/virex.dart';

import '_test_utils.dart';

void main() {
  setUp(resetRuntime);

  tearDown(() {
    VirexInspector.instance.configureTrace(
      const VirexTraceConfig(mode: VirexTraceMode.off),
    );
  });

  test('trace ring buffer honors capacity and can be cleared', () {
    final VirexInspector inspector = VirexInspector.instance;
    inspector.configureTrace(
      const VirexTraceConfig(
        mode: VirexTraceMode.ringBuffer,
        capacity: 5,
        sampleEveryN: 1,
      ),
    );
    inspector.clearTrace();

    final Signal<int> source = signal<int>(0);
    final EffectHandle handle = effect(() {
      source.value;
    });

    for (int i = 0; i < 12; i++) {
      source.value = i;
      VirexScheduler.instance.flush();
    }

    final List<VirexTraceEvent> events = inspector.getTraceSnapshot();
    expect(events, isNotEmpty);
    expect(events.length, lessThanOrEqualTo(5));

    inspector.clearTrace();
    expect(inspector.getTraceSnapshot(), isEmpty);

    handle.dispose();
    source.dispose();
  });

  test('trace sampling reduces captured records', () {
    final int full = _captureTraceLength(sampleEveryN: 1);
    resetRuntime();
    final int sampled = _captureTraceLength(sampleEveryN: 3);

    expect(sampled, lessThan(full));
  });

  test('inspector emits metrics event after flush', () async {
    final VirexInspector inspector = VirexInspector.instance;
    inspector.configureSampling(maxEventsPerSecond: 1000000);

    final List<VirexInspectorEvent> events = <VirexInspectorEvent>[];
    final sub = inspector.events.listen(events.add);

    final Signal<int> source = signal<int>(0);
    final EffectHandle handle = effect(() {
      source.value;
    });

    source.value = 1;
    VirexScheduler.instance.flush();

    await Future<void>.delayed(Duration.zero);
    expect(
      events.any((VirexInspectorEvent e) => e is VirexMetricsEvent),
      isTrue,
    );

    await sub.cancel();
    handle.dispose();
    source.dispose();
  });
}

int _captureTraceLength({required int sampleEveryN}) {
  final VirexInspector inspector = VirexInspector.instance;
  inspector.configureTrace(
    VirexTraceConfig(
      mode: VirexTraceMode.ringBuffer,
      capacity: 1000,
      sampleEveryN: sampleEveryN,
    ),
  );
  inspector.clearTrace();

  final Signal<int> source = signal<int>(0);
  final EffectHandle handle = effect(() {
    source.value;
  });

  for (int i = 0; i < 40; i++) {
    source.value = i;
    VirexScheduler.instance.flush();
  }

  final int length = inspector.getTraceSnapshot().length;
  handle.dispose();
  source.dispose();
  return length;
}
