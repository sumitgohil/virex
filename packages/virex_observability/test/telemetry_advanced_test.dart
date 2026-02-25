import 'package:test/test.dart';
import 'package:virex/virex_core.dart';
import 'package:virex_observability/virex_observability.dart';

final class _MemorySink implements VirexTelemetrySink {
  final List<VirexInspectorEvent> events = <VirexInspectorEvent>[];

  @override
  Future<void> record(VirexInspectorEvent event) async {
    events.add(event);
  }
}

final class _ThrowingSink implements VirexTelemetrySink {
  int calls = 0;

  @override
  Future<void> record(VirexInspectorEvent event) async {
    calls += 1;
    throw StateError('sink failed');
  }
}

void main() {
  setUp(() {
    debugResetVirexForTests();
    VirexInspector.instance.debugResetForTests();
  });

  test('start is idempotent and does not duplicate subscriptions', () async {
    final _MemorySink sink = _MemorySink();
    final VirexTelemetryBridge bridge = VirexTelemetryBridge(
      inspector: VirexInspector.instance,
      sink: sink,
    );

    bridge.start();
    bridge.start();

    VirexInspector.instance.snapshot();
    await Future<void>.delayed(Duration.zero);

    expect(bridge.isStarted, isTrue);
    expect(sink.events.length, 1);
    await bridge.stop();
  });

  test('stop before start is a safe no-op', () async {
    final VirexTelemetryBridge bridge = VirexTelemetryBridge(
      inspector: VirexInspector.instance,
      sink: _MemorySink(),
    );

    await expectLater(bridge.stop(), completes);
    expect(bridge.isStarted, isFalse);
  });

  test('stop detaches event forwarding', () async {
    final _MemorySink sink = _MemorySink();
    final VirexTelemetryBridge bridge = VirexTelemetryBridge(
      inspector: VirexInspector.instance,
      sink: sink,
    );

    bridge.start();
    VirexInspector.instance.snapshot();
    await Future<void>.delayed(Duration.zero);
    expect(sink.events.length, 1);

    await bridge.stop();
    VirexInspector.instance.snapshot();
    await Future<void>.delayed(Duration.zero);
    expect(sink.events.length, 1);
  });

  test(
    'sink failures are contained and bridge keeps consuming events',
    () async {
      final _ThrowingSink sink = _ThrowingSink();
      final VirexTelemetryBridge bridge = VirexTelemetryBridge(
        inspector: VirexInspector.instance,
        sink: sink,
      );

      bridge.start();
      VirexInspector.instance.snapshot();
      VirexInspector.instance.snapshot();
      await Future<void>.delayed(Duration.zero);

      expect(sink.calls, 2);
      await bridge.stop();
    },
  );
}
