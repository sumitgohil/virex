import 'dart:async';

import 'package:virex/virex_core.dart';

/// Sink abstraction for structured Virex telemetry events.
abstract interface class VirexTelemetrySink {
  Future<void> record(VirexInspectorEvent event);
}

/// Observer that forwards inspector events into a telemetry sink.
final class VirexTelemetryBridge {
  VirexTelemetryBridge({
    required VirexInspector inspector,
    required VirexTelemetrySink sink,
  }) : _inspector = inspector,
       _sink = sink;

  final VirexInspector _inspector;
  final VirexTelemetrySink _sink;

  StreamSubscription<VirexInspectorEvent>? _subscription;

  bool get isStarted => _subscription != null;

  void start() {
    if (_subscription != null) {
      return;
    }

    _subscription = _inspector.events.listen((VirexInspectorEvent event) {
      unawaited(
        _sink.record(event).catchError((Object error, StackTrace stackTrace) {
          // Telemetry sinks must never break inspector event consumption.
        }),
      );
    });
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
