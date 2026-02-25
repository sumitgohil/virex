import 'dart:async';

import 'package:flutter/material.dart';
import 'package:virex/virex.dart';
import 'package:virex_observability/virex_observability.dart';

import '../../shared/rebuild_tracker.dart';

class PerformanceModule extends StatefulWidget {
  const PerformanceModule({super.key});

  @override
  State<PerformanceModule> createState() => _PerformanceModuleState();
}

final class _PerformanceModuleState extends State<PerformanceModule> {
  static const List<VirexWriteViolationPolicy> _policies =
      <VirexWriteViolationPolicy>[
        VirexWriteViolationPolicy.hardFail,
        VirexWriteViolationPolicy.deferNextEpoch,
        VirexWriteViolationPolicy.dropAndLog,
      ];

  late final List<Signal<int>> _signals = List<Signal<int>>.generate(
    2000,
    (int i) => signal<int>(i, name: 'perf_$i'),
  );

  final Signal<int> _batchSize = signal<int>(2000, name: 'perf_batch_size');
  final Signal<int> _setStateSimulatedRebuilds = signal<int>(
    0,
    name: 'perf_setstate',
  );
  final Signal<int> _virexFlushes = signal<int>(0, name: 'perf_virex');
  final Signal<double> _lastFrameMs = signal<double>(0, name: 'perf_frame_ms');
  final Signal<int> _policyIndex = signal<int>(0, name: 'perf_policy_index');
  final Signal<bool> _traceEnabled = signal<bool>(true, name: 'perf_trace');
  final Signal<bool> _autoStress = signal<bool>(
    false,
    name: 'perf_auto_stress',
  );

  final Signal<int> _traceEvents = signal<int>(0, name: 'perf_trace_events');
  final Signal<int> _flushEvents = signal<int>(0, name: 'perf_flush_events');
  final Signal<int> _metricEvents = signal<int>(0, name: 'perf_metric_events');
  final Signal<int> _errorEvents = signal<int>(0, name: 'perf_error_events');
  final Signal<int> _writeViolations = signal<int>(
    0,
    name: 'perf_write_violations',
  );
  final Signal<double> _p95FlushMs = signal<double>(0, name: 'perf_p95_flush');
  final Signal<int> _deferredWrites = signal<int>(
    0,
    name: 'perf_deferred_writes',
  );
  final Signal<int> _flushEpoch = signal<int>(0, name: 'perf_flush_epoch');

  Timer? _timer;
  VirexTelemetryBridge? _bridge;
  int _observedFlushEvents = 0;
  int _observedMetricEvents = 0;
  int _observedErrorEvents = 0;

  @override
  void initState() {
    super.initState();
    _applyRuntimeProfile();
    VirexInspector.instance.configureSampling(maxEventsPerSecond: 10000);
    _applyTraceMode();
    _bridge = VirexTelemetryBridge(
      inspector: VirexInspector.instance,
      sink: _PerfTelemetrySink(_onInspectorEvent),
    )..start();
  }

  @override
  void dispose() {
    _timer?.cancel();
    unawaited(_bridge?.stop());
    for (final Signal<int> signalNode in _signals) {
      signalNode.dispose();
    }
    _batchSize.dispose();
    _setStateSimulatedRebuilds.dispose();
    _virexFlushes.dispose();
    _lastFrameMs.dispose();
    _policyIndex.dispose();
    _traceEnabled.dispose();
    _autoStress.dispose();
    _traceEvents.dispose();
    _flushEvents.dispose();
    _metricEvents.dispose();
    _errorEvents.dispose();
    _writeViolations.dispose();
    _p95FlushMs.dispose();
    _deferredWrites.dispose();
    _flushEpoch.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TrackedRebuild(
      name: 'PerformanceModule',
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'V2 Chaos Lab',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  FilledButton(
                    onPressed: _runStressTick,
                    child: const Text('Run stress tick'),
                  ),
                  FilledButton.tonal(
                    onPressed: _runBurst,
                    child: const Text('Run x10 burst'),
                  ),
                  SignalBuilder(
                    builder: () => OutlinedButton(
                      onPressed: () =>
                          _setAutoStressEnabled(!_autoStress.value),
                      child: Text(
                        _autoStress.value
                            ? 'Stop auto stress'
                            : 'Start auto stress',
                      ),
                    ),
                  ),
                  OutlinedButton(
                    onPressed: _triggerComputeViolation,
                    child: const Text('Trigger write violation'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SignalBuilder(
                builder: () => Row(
                  children: <Widget>[
                    const Text('Write policy:'),
                    const SizedBox(width: 8),
                    DropdownButton<int>(
                      value: _policyIndex.value,
                      items: const <DropdownMenuItem<int>>[
                        DropdownMenuItem<int>(
                          value: 0,
                          child: Text('hardFail'),
                        ),
                        DropdownMenuItem<int>(
                          value: 1,
                          child: Text('deferNextEpoch'),
                        ),
                        DropdownMenuItem<int>(
                          value: 2,
                          child: Text('dropAndLog'),
                        ),
                      ],
                      onChanged: (int? next) {
                        if (next == null) {
                          return;
                        }
                        _policyIndex.value = next;
                        _applyRuntimeProfile();
                      },
                    ),
                    const SizedBox(width: 16),
                    Switch(
                      value: _traceEnabled.value,
                      onChanged: (bool enabled) {
                        _traceEnabled.value = enabled;
                        _applyTraceMode();
                      },
                    ),
                    const Text('Trace'),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SignalBuilder(
                builder: () => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Batch size: ${_batchSize.value}'),
                    Slider(
                      value: _batchSize.value.toDouble(),
                      min: 500,
                      max: 10000,
                      divisions: 19,
                      label: '${_batchSize.value}',
                      onChanged: (double value) =>
                          _batchSize.value = value.round(),
                      onChangeEnd: (_) => _applyRuntimeProfile(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: SignalBuilder(
                  builder: () {
                    final int sample =
                        _signals[10].value +
                        _signals[500].value +
                        _signals[1500].value;
                    return ListView(
                      children: <Widget>[
                        Text(
                          'Signal sample sum: $sample',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Last stress tick: ${_lastFrameMs.value.toStringAsFixed(3)} ms',
                        ),
                        Text(
                          'setState simulated rebuilds: ${_setStateSimulatedRebuilds.value}',
                        ),
                        Text('Virex flush cycles: ${_virexFlushes.value}'),
                        const Divider(),
                        Text('Scheduler epoch: ${_flushEpoch.value}'),
                        Text(
                          'p95 flush window: ${_p95FlushMs.value.toStringAsFixed(3)} ms',
                        ),
                        Text('Deferred writes: ${_deferredWrites.value}'),
                        const Divider(),
                        Text('Inspector trace events: ${_traceEvents.value}'),
                        Text('Observed flush events: ${_flushEvents.value}'),
                        Text('Observed metrics events: ${_metricEvents.value}'),
                        Text('Observed error events: ${_errorEvents.value}'),
                        Text(
                          'Write violations caught: ${_writeViolations.value}',
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _applyRuntimeProfile() {
    final VirexWriteViolationPolicy policy = _policies[_policyIndex.value];
    configureVirexRuntime(
      VirexRuntimeConfig(
        writeViolationPolicy: policy,
        effectLoopThreshold: 100,
        maxNodesPerFlushSlice: _batchSize.value >= 4000 ? 2000 : 0,
        enableInvariantAuditInDebug: true,
      ),
    );
  }

  void _applyTraceMode() {
    VirexInspector.instance.configureTrace(
      VirexTraceConfig(
        mode: _traceEnabled.value
            ? VirexTraceMode.ringBuffer
            : VirexTraceMode.off,
        capacity: 20000,
        sampleEveryN: 1,
      ),
    );
  }

  void _runBurst() {
    for (int i = 0; i < 10; i++) {
      _runStressTick();
    }
  }

  void _runStressTick() {
    final Stopwatch watch = Stopwatch()..start();
    final int updates = _batchSize.value;
    batch(() {
      for (int i = 0; i < updates; i++) {
        final int index = i % _signals.length;
        _signals[index].value = _signals[index].value + 1;
      }
    });
    VirexScheduler.instance.flush();
    watch.stop();

    final VirexSchedulerMetrics metrics = VirexScheduler.instance
        .metricsSnapshot();
    final int traceCount = VirexInspector.instance.getTraceSnapshot().length;
    batch(() {
      _setStateSimulatedRebuilds.value =
          _setStateSimulatedRebuilds.value + updates;
      _virexFlushes.value = _virexFlushes.value + 1;
      _lastFrameMs.value = watch.elapsedMicroseconds / 1000;
      _flushEpoch.value = metrics.flushEpoch;
      _p95FlushMs.value = metrics.p95FlushDurationWindow.inMicroseconds / 1000;
      _deferredWrites.value = metrics.deferredWriteCount;
      _traceEvents.value = traceCount;
      _flushEvents.value = _observedFlushEvents;
      _metricEvents.value = _observedMetricEvents;
      _errorEvents.value = _observedErrorEvents;
    });
  }

  void _setAutoStressEnabled(bool enabled) {
    _autoStress.value = enabled;
    _timer?.cancel();
    if (!enabled) {
      return;
    }
    _timer = Timer.periodic(
      const Duration(milliseconds: 450),
      (_) => _runStressTick(),
    );
  }

  void _triggerComputeViolation() {
    final Signal<int> guard = signal<int>(0, name: 'perf_violation_guard');
    final Computed<int> bad = computed<int>(() {
      if (guard.value == 0) {
        guard.value = 1;
      }
      return guard.value;
    }, name: 'perf_bad_compute');

    try {
      bad.value;
      if (_policies[_policyIndex.value] ==
          VirexWriteViolationPolicy.deferNextEpoch) {
        VirexScheduler.instance.flush();
      }
    } catch (_) {
      _writeViolations.value = _writeViolations.value + 1;
    } finally {
      guard.dispose();
      bad.dispose();
    }
  }

  void _onInspectorEvent(VirexInspectorEvent event) {
    if (!mounted) {
      return;
    }
    if (event is VirexFlushEvent) {
      _observedFlushEvents += 1;
      return;
    }
    if (event is VirexMetricsEvent) {
      _observedMetricEvents += 1;
      return;
    }
    if (event is VirexInvariantFailureEvent) {
      _observedErrorEvents += 1;
    }
  }
}

final class _PerfTelemetrySink implements VirexTelemetrySink {
  _PerfTelemetrySink(this._onEvent);

  final void Function(VirexInspectorEvent event) _onEvent;

  @override
  Future<void> record(VirexInspectorEvent event) async {
    _onEvent(event);
  }
}
