import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import '../core/dependency_graph.dart';
import '../core/scheduler.dart';
import 'logger.dart';

abstract interface class DevToolsBridge {
  void onSnapshot(VirexGraphSnapshot snapshot);
}

/// Base event emitted by [VirexInspector.events].
sealed class VirexInspectorEvent {
  const VirexInspectorEvent({required this.name, required this.timestamp});

  final String name;
  final DateTime timestamp;

  Map<String, Object?> toJson();
}

/// Emitted after each completed flush epoch.
final class VirexFlushEvent extends VirexInspectorEvent {
  const VirexFlushEvent({required this.epoch, required super.timestamp})
    : super(name: 'flush_epoch');

  final int epoch;

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'name': name,
      'timestamp': timestamp.toIso8601String(),
      'epoch': epoch,
    };
  }
}

/// Emitted when scheduler metrics are sampled after a flush.
final class VirexMetricsEvent extends VirexInspectorEvent {
  const VirexMetricsEvent({required this.metrics, required super.timestamp})
    : super(name: 'scheduler_metrics');

  final VirexSchedulerMetrics metrics;

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'name': name,
      'timestamp': timestamp.toIso8601String(),
      'flushEpoch': metrics.flushEpoch,
      'pendingComputed': metrics.pendingComputed,
      'pendingEffects': metrics.pendingEffects,
      'deferredWriteCount': metrics.deferredWriteCount,
      'lastFlushMicros': metrics.lastFlushDuration.inMicroseconds,
      'p95FlushMicros': metrics.p95FlushDurationWindow.inMicroseconds,
    };
  }
}

/// Emitted when a snapshot is produced.
final class VirexSnapshotEvent extends VirexInspectorEvent {
  const VirexSnapshotEvent({
    required this.epoch,
    required this.nodeCount,
    required this.phase,
    required super.timestamp,
  }) : super(name: 'snapshot');

  final int epoch;
  final int nodeCount;
  final ExecutionPhase phase;

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'name': name,
      'timestamp': timestamp.toIso8601String(),
      'epoch': epoch,
      'nodeCount': nodeCount,
      'phase': phase.name,
    };
  }
}

/// Emitted when invariants are checked.
final class VirexInvariantEvent extends VirexInspectorEvent {
  const VirexInvariantEvent({required this.ok, required super.timestamp})
    : super(name: 'invariant_check');

  final bool ok;

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'name': name,
      'timestamp': timestamp.toIso8601String(),
      'ok': ok,
    };
  }
}

/// Emitted when invariant verification fails with details.
final class VirexInvariantFailureEvent extends VirexInspectorEvent {
  const VirexInvariantFailureEvent({
    required this.issues,
    required super.timestamp,
  }) : super(name: 'invariant_failure');

  final List<GraphInvariantIssue> issues;

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'name': name,
      'timestamp': timestamp.toIso8601String(),
      'issues': issues
          .map(
            (GraphInvariantIssue issue) => <String, Object?>{
              'invariantName': issue.invariantName,
              'offenderNodeIds': issue.offenderNodeIds,
              'message': issue.message,
            },
          )
          .toList(growable: false),
    };
  }
}

enum VirexTraceMode { off, ringBuffer }

final class VirexTraceConfig {
  const VirexTraceConfig({
    this.mode = VirexTraceMode.off,
    this.capacity = 20000,
    this.sampleEveryN = 1,
  });

  final VirexTraceMode mode;
  final int capacity;
  final int sampleEveryN;
}

sealed class VirexTraceEvent {
  const VirexTraceEvent({
    required this.epoch,
    required this.timestamp,
    this.nodeId,
    this.message,
  });

  final int epoch;
  final DateTime timestamp;
  final int? nodeId;
  final String? message;
}

final class VirexTraceEpochStartEvent extends VirexTraceEvent {
  const VirexTraceEpochStartEvent({
    required super.epoch,
    required super.timestamp,
    super.message,
  });
}

final class VirexTraceEnqueueEvent extends VirexTraceEvent {
  const VirexTraceEnqueueEvent({
    required this.queue,
    required super.epoch,
    required super.timestamp,
    super.nodeId,
    super.message,
  });

  final String queue;
}

final class VirexTraceRunEvent extends VirexTraceEvent {
  const VirexTraceRunEvent({
    required this.phase,
    required super.epoch,
    required super.timestamp,
    super.nodeId,
    super.message,
  });

  final String phase;
}

final class VirexTraceInvalidateEvent extends VirexTraceEvent {
  const VirexTraceInvalidateEvent({
    required this.targetKind,
    required super.epoch,
    required super.timestamp,
    super.nodeId,
    super.message,
  });

  final String targetKind;
}

final class VirexTraceErrorEvent extends VirexTraceEvent {
  const VirexTraceErrorEvent({
    required super.epoch,
    required super.timestamp,
    super.nodeId,
    super.message,
  });
}

final class VirexTraceDeferredWriteEvent extends VirexTraceEvent {
  const VirexTraceDeferredWriteEvent({
    required this.applied,
    required super.epoch,
    required super.timestamp,
    super.nodeId,
    super.message,
  });

  final bool applied;
}

final class VirexNodeSnapshot {
  const VirexNodeSnapshot({
    required this.id,
    required this.kind,
    required this.name,
    required this.dependencies,
    required this.subscribers,
    required this.disposed,
    required this.dirty,
    required this.hasError,
    required this.lastEnqueuedEpoch,
    required this.lastComputedEpoch,
    required this.runCountInEpoch,
  });

  final int id;
  final NodeKind kind;
  final String? name;
  final List<int> dependencies;
  final List<int> subscribers;
  final bool disposed;
  final bool dirty;
  final bool hasError;
  final int lastEnqueuedEpoch;
  final int lastComputedEpoch;
  final int runCountInEpoch;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'kind': kind.name,
      'name': name,
      'dependencies': dependencies,
      'subscribers': subscribers,
      'disposed': disposed,
      'dirty': dirty,
      'hasError': hasError,
      'lastEnqueuedEpoch': lastEnqueuedEpoch,
      'lastComputedEpoch': lastComputedEpoch,
      'runCountInEpoch': runCountInEpoch,
    };
  }
}

final class VirexGraphSnapshot {
  const VirexGraphSnapshot({
    required this.phase,
    required this.flushEpoch,
    required this.pendingComputed,
    required this.pendingEffects,
    required this.nodes,
  });

  final ExecutionPhase phase;
  final int flushEpoch;
  final int pendingComputed;
  final int pendingEffects;
  final List<VirexNodeSnapshot> nodes;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'phase': phase.name,
      'flushEpoch': flushEpoch,
      'pendingComputed': pendingComputed,
      'pendingEffects': pendingEffects,
      'nodes': nodes.map((VirexNodeSnapshot node) => node.toJson()).toList(),
    };
  }
}

final class VirexInspector {
  VirexInspector._() {
    _scheduler.addFlushListener(_onFlushEpoch);
  }

  static final VirexInspector instance = VirexInspector._();

  final ReactiveGraph _graph = ReactiveGraph.instance;
  final VirexScheduler _scheduler = VirexScheduler.instance;
  final StreamController<VirexGraphSnapshot> _snapshotController =
      StreamController<VirexGraphSnapshot>.broadcast();
  final StreamController<VirexInspectorEvent> _eventController =
      StreamController<VirexInspectorEvent>.broadcast();

  DevToolsBridge? _bridge;
  bool _serviceExtensionsRegistered = false;
  bool _autoSnapshotsEnabled = false;
  bool _timelineEnabled = false;
  int _maxEventsPerSecond = 120;
  int _eventWindowSecond = -1;
  int _eventWindowCount = 0;
  VirexTraceConfig _traceConfig = const VirexTraceConfig();

  Stream<VirexGraphSnapshot> get snapshots => _snapshotController.stream;

  /// Typed runtime events for observability and DevTools streams.
  Stream<VirexInspectorEvent> get events => _eventController.stream;

  bool get autoSnapshotsEnabled => _autoSnapshotsEnabled;
  VirexTraceConfig get traceConfig => _traceConfig;

  /// Enables or disables automatic snapshots on flush completion.
  void setAutoSnapshots({required bool enabled}) {
    _autoSnapshotsEnabled = enabled;
  }

  /// Configures maximum emitted inspector events per second.
  void configureSampling({int maxEventsPerSecond = 120}) {
    _maxEventsPerSecond = maxEventsPerSecond < 1 ? 1 : maxEventsPerSecond;
  }

  /// Enables timeline markers for inspector events.
  void enableTimeline({bool enabled = true}) {
    _timelineEnabled = enabled;
  }

  /// Configures deterministic trace capture.
  void configureTrace(VirexTraceConfig config) {
    _traceConfig = config;
    _scheduler.configureTraceBuffer(
      enabled: config.mode == VirexTraceMode.ringBuffer,
      capacity: config.capacity,
      sampleEveryN: config.sampleEveryN,
    );
  }

  List<VirexTraceEvent> getTraceSnapshot() {
    final List<VirexSchedulerTraceRecord> raw = _scheduler.traceSnapshot();
    return raw
        .map((VirexSchedulerTraceRecord item) => _mapTraceEvent(item))
        .whereType<VirexTraceEvent>()
        .toList(growable: false);
  }

  void clearTrace() {
    _scheduler.clearTrace();
  }

  void enableLogging(VirexLogListener listener) {
    VirexLogger.instance
      ..enabled = true
      ..listener = listener;
  }

  void disableLogging() {
    VirexLogger.instance
      ..enabled = false
      ..listener = null;
  }

  /// Resets mutable inspector state for deterministic test isolation.
  void debugResetForTests() {
    _scheduler.removeFlushListener(_onFlushEpoch);
    _scheduler.addFlushListener(_onFlushEpoch);
    _autoSnapshotsEnabled = false;
    _timelineEnabled = false;
    _maxEventsPerSecond = 120;
    _eventWindowSecond = -1;
    _eventWindowCount = 0;
    _traceConfig = const VirexTraceConfig();
    _scheduler.configureTraceBuffer(
      enabled: false,
      capacity: _traceConfig.capacity,
      sampleEveryN: _traceConfig.sampleEveryN,
    );
    _scheduler.clearTrace();
  }

  void registerDevToolsExtension(DevToolsBridge bridge) {
    _bridge = bridge;
    registerVmServiceExtensions();
  }

  /// Registers VM service extensions for external tooling integration.
  void registerVmServiceExtensions() {
    if (_serviceExtensionsRegistered) {
      return;
    }

    try {
      developer.registerExtension('ext.virex.snapshot', (
        String method,
        Map<String, String> parameters,
      ) async {
        final VirexGraphSnapshot current = snapshot();
        return developer.ServiceExtensionResponse.result(
          jsonEncode(current.toJson()),
        );
      });

      developer.registerExtension('ext.virex.auto_snapshots', (
        String method,
        Map<String, String> parameters,
      ) async {
        final String enabled = parameters['enabled'] ?? 'false';
        _autoSnapshotsEnabled = enabled == 'true';
        return developer.ServiceExtensionResponse.result(
          jsonEncode(<String, Object?>{
            'autoSnapshotsEnabled': _autoSnapshotsEnabled,
          }),
        );
      });

      developer.registerExtension('ext.virex.invariants', (
        String method,
        Map<String, String> parameters,
      ) async {
        final bool ok = debugCheckInvariants();
        return developer.ServiceExtensionResponse.result(
          jsonEncode(<String, Object?>{'ok': ok}),
        );
      });

      _serviceExtensionsRegistered = true;
    } catch (_) {
      // Service extensions are not supported on all runtimes.
    }
  }

  VirexGraphSnapshot snapshot() {
    final List<VirexNodeSnapshot> nodes =
        _graph.nodes.values
            .map(
              (NodeRecord record) => VirexNodeSnapshot(
                id: record.id,
                kind: record.kind,
                name: record.name,
                dependencies: record.dependencies.toList(growable: false),
                subscribers: record.subscribers.toList(growable: false),
                disposed: record.disposed,
                dirty: record.dirty,
                hasError: record.hasError,
                lastEnqueuedEpoch: record.lastEnqueuedEpoch,
                lastComputedEpoch: record.lastComputedEpoch,
                runCountInEpoch: record.runCountInEpoch,
              ),
            )
            .toList(growable: false)
          ..sort(
            (VirexNodeSnapshot a, VirexNodeSnapshot b) => a.id.compareTo(b.id),
          );

    final VirexGraphSnapshot current = VirexGraphSnapshot(
      phase: _scheduler.phase,
      flushEpoch: _scheduler.flushEpoch,
      pendingComputed: _scheduler.pendingComputedCount,
      pendingEffects: _scheduler.pendingEffectCount,
      nodes: nodes,
    );

    if (!_snapshotController.isClosed) {
      _snapshotController.add(current);
    }
    _bridge?.onSnapshot(current);

    final VirexSnapshotEvent event = VirexSnapshotEvent(
      epoch: current.flushEpoch,
      nodeCount: current.nodes.length,
      phase: current.phase,
      timestamp: DateTime.now().toUtc(),
    );
    _emitEvent(event);

    VirexLogger.instance.log(
      'inspector.snapshot',
      data: <String, Object?>{
        'phase': current.phase.name,
        'flushEpoch': current.flushEpoch,
        'nodeCount': current.nodes.length,
      },
    );

    return current;
  }

  bool debugCheckInvariants() {
    final GraphInvariantResult result = _graph.debugVerifyInvariantDetails(
      queuesAreEmpty:
          _scheduler.pendingComputedCount == 0 &&
          _scheduler.pendingEffectCount == 0,
    );
    _emitEvent(
      VirexInvariantEvent(ok: result.ok, timestamp: DateTime.now().toUtc()),
    );
    if (!result.ok) {
      _emitEvent(
        VirexInvariantFailureEvent(
          issues: result.issues,
          timestamp: DateTime.now().toUtc(),
        ),
      );
    }
    return result.ok;
  }

  void _onFlushEpoch(int epoch) {
    _emitEvent(
      VirexFlushEvent(epoch: epoch, timestamp: DateTime.now().toUtc()),
    );
    _emitEvent(
      VirexMetricsEvent(
        metrics: _scheduler.metricsSnapshot(),
        timestamp: DateTime.now().toUtc(),
      ),
    );

    if (!_autoSnapshotsEnabled &&
        !_snapshotController.hasListener &&
        !_eventController.hasListener &&
        _bridge == null) {
      return;
    }
    snapshot();
  }

  VirexTraceEvent? _mapTraceEvent(VirexSchedulerTraceRecord record) {
    return switch (record.kind) {
      SchedulerTraceKind.epochStart => VirexTraceEpochStartEvent(
        epoch: record.epoch,
        timestamp: record.timestamp,
        message: record.message,
      ),
      SchedulerTraceKind.enqueueComputed => VirexTraceEnqueueEvent(
        queue: 'computed',
        epoch: record.epoch,
        timestamp: record.timestamp,
        nodeId: record.nodeId,
        message: record.message,
      ),
      SchedulerTraceKind.enqueueEffect => VirexTraceEnqueueEvent(
        queue: 'effect',
        epoch: record.epoch,
        timestamp: record.timestamp,
        nodeId: record.nodeId,
        message: record.message,
      ),
      SchedulerTraceKind.runComputed => VirexTraceRunEvent(
        phase: 'computing',
        epoch: record.epoch,
        timestamp: record.timestamp,
        nodeId: record.nodeId,
        message: record.message,
      ),
      SchedulerTraceKind.runEffect => VirexTraceRunEvent(
        phase: 'effect',
        epoch: record.epoch,
        timestamp: record.timestamp,
        nodeId: record.nodeId,
        message: record.message,
      ),
      SchedulerTraceKind.invalidateComputed => VirexTraceInvalidateEvent(
        targetKind: 'computed',
        epoch: record.epoch,
        timestamp: record.timestamp,
        nodeId: record.nodeId,
        message: record.message,
      ),
      SchedulerTraceKind.invalidateEffect => VirexTraceInvalidateEvent(
        targetKind: 'effect',
        epoch: record.epoch,
        timestamp: record.timestamp,
        nodeId: record.nodeId,
        message: record.message,
      ),
      SchedulerTraceKind.deferredWriteQueued => VirexTraceDeferredWriteEvent(
        applied: false,
        epoch: record.epoch,
        timestamp: record.timestamp,
        nodeId: record.nodeId,
        message: record.message,
      ),
      SchedulerTraceKind.deferredWriteApplied => VirexTraceDeferredWriteEvent(
        applied: true,
        epoch: record.epoch,
        timestamp: record.timestamp,
        nodeId: record.nodeId,
        message: record.message,
      ),
      SchedulerTraceKind.error => VirexTraceErrorEvent(
        epoch: record.epoch,
        timestamp: record.timestamp,
        nodeId: record.nodeId,
        message: record.message,
      ),
      SchedulerTraceKind.warning => VirexTraceErrorEvent(
        epoch: record.epoch,
        timestamp: record.timestamp,
        nodeId: record.nodeId,
        message: record.message,
      ),
    };
  }

  void _emitEvent(VirexInspectorEvent event) {
    if (_eventController.isClosed) {
      return;
    }

    final int nowSecond = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    if (nowSecond != _eventWindowSecond) {
      _eventWindowSecond = nowSecond;
      _eventWindowCount = 0;
    }

    if (_eventWindowCount >= _maxEventsPerSecond) {
      return;
    }

    _eventWindowCount += 1;
    _eventController.add(event);

    if (_timelineEnabled) {
      try {
        developer.Timeline.instantSync(event.name, arguments: event.toJson());
      } catch (_) {
        // Timeline events can be unavailable on some runtimes.
      }
    }
  }
}
