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

void main() {
  test('bridge records inspector events', () async {
    final _MemorySink sink = _MemorySink();
    final VirexTelemetryBridge bridge = VirexTelemetryBridge(
      inspector: VirexInspector.instance,
      sink: sink,
    );

    bridge.start();
    VirexInspector.instance.snapshot();
    await Future<void>.delayed(Duration.zero);

    expect(sink.events, isNotEmpty);

    await bridge.stop();
  });
}
