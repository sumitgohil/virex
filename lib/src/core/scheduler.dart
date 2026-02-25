import 'dart:async';
import 'dart:collection';

import 'dependency_graph.dart';

enum ExecutionPhase { idle, tracking, flushing, computing, effectRunning }

extension ExecutionPhaseX on ExecutionPhase {
  bool get isComputing => this == ExecutionPhase.computing;
  bool get isEffectRunning => this == ExecutionPhase.effectRunning;
}

typedef NodeRunner = void Function();
typedef ErrorReporter = void Function(Object error, StackTrace stackTrace);
typedef FlushEpochListener = void Function(int epoch);

enum SchedulerTraceKind {
  epochStart,
  enqueueComputed,
  enqueueEffect,
  runComputed,
  runEffect,
  invalidateComputed,
  invalidateEffect,
  deferredWriteQueued,
  deferredWriteApplied,
  error,
  warning,
}

final class VirexSchedulerTraceRecord {
  const VirexSchedulerTraceRecord({
    required this.kind,
    required this.epoch,
    required this.timestamp,
    this.nodeId,
    this.message,
  });

  final SchedulerTraceKind kind;
  final int epoch;
  final DateTime timestamp;
  final int? nodeId;
  final String? message;
}

final class VirexSchedulerMetrics {
  const VirexSchedulerMetrics({
    required this.flushEpoch,
    required this.pendingComputed,
    required this.pendingEffects,
    required this.deferredWriteCount,
    required this.lastFlushDuration,
    required this.p95FlushDurationWindow,
  });

  final int flushEpoch;
  final int pendingComputed;
  final int pendingEffects;
  final int deferredWriteCount;
  final Duration lastFlushDuration;
  final Duration p95FlushDurationWindow;
}

final class _DeferredWrite {
  const _DeferredWrite({
    required this.targetEpoch,
    required this.nodeId,
    required this.sequence,
    required this.apply,
  });

  final int targetEpoch;
  final int nodeId;
  final int sequence;
  final void Function() apply;
}

final class VirexScheduler {
  VirexScheduler._();

  static final VirexScheduler instance = VirexScheduler._();

  final ReactiveGraph _graph = ReactiveGraph.instance;

  final ListQueue<int> _pendingComputed = ListQueue<int>();
  final ListQueue<int> _pendingEffects = ListQueue<int>();
  final ListQueue<int> _activeComputed = ListQueue<int>();
  final ListQueue<int> _activeEffects = ListQueue<int>();
  final ListQueue<_DeferredWrite> _deferredWrites = ListQueue<_DeferredWrite>();

  final Map<int, NodeRunner> _computedRunners = <int, NodeRunner>{};
  final Map<int, NodeRunner> _effectRunners = <int, NodeRunner>{};
  final Set<FlushEpochListener> _flushListeners = <FlushEpochListener>{};
  final Set<int> _touchedEffects = <int>{};
  final ListQueue<int> _flushWindowMicros = ListQueue<int>();
  final List<ExecutionPhase> _phaseStack = <ExecutionPhase>[];
  final ListQueue<VirexSchedulerTraceRecord> _traceBuffer =
      ListQueue<VirexSchedulerTraceRecord>();

  static const int _flushWindowSize = 128;

  ExecutionPhase _phase = ExecutionPhase.idle;
  bool _flushScheduled = false;
  bool _isFlushing = false;
  bool _applyingDeferredWrites = false;
  bool _epochInProgress = false;
  int _batchDepth = 0;
  int _flushEpoch = 0;
  int _deferredWriteSequence = 0;
  int _deferredWriteCount = 0;

  int effectLoopThreshold = 100;
  int _maxNodesPerFlushSlice = 0;
  bool _enableInvariantAuditInDebug = true;
  ErrorReporter? onError;

  Duration _lastFlushDuration = Duration.zero;

  bool _traceEnabled = false;
  int _traceCapacity = 20000;
  int _traceSampleEveryN = 1;
  int _traceCounter = 0;

  ExecutionPhase get phase => _phase;
  bool get isComputingContext {
    if (_phase == ExecutionPhase.computing) {
      return true;
    }
    return _phase == ExecutionPhase.tracking &&
        _phaseStack.isNotEmpty &&
        _phaseStack.last == ExecutionPhase.computing;
  }

  int get flushEpoch => _flushEpoch;
  int get pendingComputedCount =>
      _pendingComputed.length + _activeComputed.length;
  int get pendingEffectCount => _pendingEffects.length + _activeEffects.length;
  bool get hasPending =>
      pendingComputedCount > 0 ||
      pendingEffectCount > 0 ||
      _deferredWrites.isNotEmpty;

  /// Registers a callback invoked after each completed flush epoch.
  void addFlushListener(FlushEpochListener listener) {
    _flushListeners.add(listener);
  }

  void removeFlushListener(FlushEpochListener listener) {
    _flushListeners.remove(listener);
  }

  void registerComputedRunner(int id, NodeRunner runner) {
    _computedRunners[id] = runner;
  }

  void registerEffectRunner(int id, NodeRunner runner) {
    _effectRunners[id] = runner;
  }

  void unregisterNode(int id) {
    _computedRunners.remove(id);
    _effectRunners.remove(id);
    _touchedEffects.remove(id);
  }

  void configureTraceBuffer({
    required bool enabled,
    int capacity = 20000,
    int sampleEveryN = 1,
  }) {
    _traceEnabled = enabled;
    _traceCapacity = capacity < 1 ? 1 : capacity;
    _traceSampleEveryN = sampleEveryN < 1 ? 1 : sampleEveryN;
    if (!_traceEnabled) {
      _traceBuffer.clear();
      _traceCounter = 0;
    } else if (_traceBuffer.length > _traceCapacity) {
      while (_traceBuffer.length > _traceCapacity) {
        _traceBuffer.removeFirst();
      }
    }
  }

  List<VirexSchedulerTraceRecord> traceSnapshot() {
    return _traceBuffer.toList(growable: false);
  }

  void clearTrace() {
    _traceBuffer.clear();
    _traceCounter = 0;
  }

  VirexSchedulerMetrics metricsSnapshot() {
    return VirexSchedulerMetrics(
      flushEpoch: _flushEpoch,
      pendingComputed: pendingComputedCount,
      pendingEffects: pendingEffectCount,
      deferredWriteCount: _deferredWriteCount,
      lastFlushDuration: _lastFlushDuration,
      p95FlushDurationWindow: _p95Window(),
    );
  }

  void applyRuntimeConfig({
    required int effectLoopThreshold,
    required int maxNodesPerFlushSlice,
    required bool enableInvariantAuditInDebug,
  }) {
    this.effectLoopThreshold = effectLoopThreshold < 1
        ? 1
        : effectLoopThreshold;
    _maxNodesPerFlushSlice = maxNodesPerFlushSlice < 0
        ? 0
        : maxNodesPerFlushSlice;
    _enableInvariantAuditInDebug = enableInvariantAuditInDebug;
  }

  void markTrackingStart() {
    _phaseStack.add(_phase);
    _phase = ExecutionPhase.tracking;
  }

  void markTrackingEnd() {
    if (_phase != ExecutionPhase.tracking) {
      return;
    }
    if (_phaseStack.isEmpty) {
      _phase = ExecutionPhase.idle;
      return;
    }
    _phase = _phaseStack.removeLast();
  }

  void beginBatch() {
    _batchDepth++;
  }

  void endBatch() {
    if (_batchDepth == 0) {
      throw StateError('Unbalanced batch end.');
    }
    _batchDepth--;
    if (_batchDepth == 0) {
      _ensureFlushScheduled();
    }
  }

  void batch(void Function() action) {
    beginBatch();
    try {
      action();
    } finally {
      endBatch();
    }
  }

  void recordInvalidation(int nodeId, NodeKind kind) {
    _trace(
      kind == NodeKind.computed
          ? SchedulerTraceKind.invalidateComputed
          : SchedulerTraceKind.invalidateEffect,
      nodeId: nodeId,
    );
  }

  void reportRuntimeWarning(String message, {int? nodeId}) {
    _trace(SchedulerTraceKind.warning, nodeId: nodeId, message: message);
    if (onError != null) {
      onError!(StateError(message), StackTrace.current);
    }
  }

  void deferWrite({required int sourceId, required void Function() apply}) {
    final int targetEpoch = _flushEpoch + 1;
    final _DeferredWrite entry = _DeferredWrite(
      targetEpoch: targetEpoch,
      nodeId: sourceId,
      sequence: _deferredWriteSequence++,
      apply: apply,
    );
    _deferredWrites.add(entry);
    _deferredWriteCount += 1;
    _trace(
      SchedulerTraceKind.deferredWriteQueued,
      nodeId: sourceId,
      message: 'targetEpoch=$targetEpoch seq=${entry.sequence}',
    );
    _ensureFlushScheduled();
  }

  void enqueueComputed(int id) {
    final NodeRecord? record = _graph.maybeRecordOf(id);
    if (record == null || record.disposed) {
      return;
    }

    final bool sameCycle =
        _phase == ExecutionPhase.computing ||
        (_phase == ExecutionPhase.flushing && _applyingDeferredWrites);
    final int targetEpoch = sameCycle ? _flushEpoch : _flushEpoch + 1;

    if (record.lastEnqueuedEpoch == targetEpoch) {
      return;
    }

    record.lastEnqueuedEpoch = targetEpoch;

    if (sameCycle) {
      _activeComputed.add(id);
    } else {
      _pendingComputed.add(id);
    }

    _trace(
      SchedulerTraceKind.enqueueComputed,
      nodeId: id,
      message: 'targetEpoch=$targetEpoch',
    );

    _ensureFlushScheduled();
  }

  void enqueueEffect(int id) {
    final NodeRecord? record = _graph.maybeRecordOf(id);
    if (record == null || record.disposed) {
      return;
    }

    final bool currentCycle =
        (_phase == ExecutionPhase.computing) ||
        (_phase == ExecutionPhase.flushing && _applyingDeferredWrites);
    final int targetEpoch = currentCycle ? _flushEpoch : _flushEpoch + 1;

    if (record.lastEnqueuedEpoch == targetEpoch) {
      return;
    }

    record.lastEnqueuedEpoch = targetEpoch;

    if (currentCycle) {
      _activeEffects.add(id);
    } else {
      _pendingEffects.add(id);
    }

    _trace(
      SchedulerTraceKind.enqueueEffect,
      nodeId: id,
      message: 'targetEpoch=$targetEpoch',
    );

    _ensureFlushScheduled();
  }

  void markComputedInEpoch(int id) {
    final NodeRecord? record = _graph.maybeRecordOf(id);
    if (record == null || record.disposed) {
      return;
    }
    record.lastComputedEpoch = _flushEpoch;
  }

  bool flush() {
    if (_isFlushing) {
      return false;
    }
    _drainNow();
    return true;
  }

  void _ensureFlushScheduled() {
    if (_isFlushing || _flushScheduled || _batchDepth > 0) {
      return;
    }
    _flushScheduled = true;
    scheduleMicrotask(_drainNow);
  }

  void _drainNow() {
    if (_isFlushing) {
      return;
    }

    _flushScheduled = false;
    if (!hasPending) {
      return;
    }

    _isFlushing = true;
    final Stopwatch stopwatch = Stopwatch()..start();
    try {
      int remainingBudget = _maxNodesPerFlushSlice > 0
          ? _maxNodesPerFlushSlice
          : 1 << 30;

      while (hasPending && remainingBudget > 0) {
        if (!_epochInProgress) {
          _startEpoch();
        } else if (_phase == ExecutionPhase.idle) {
          // Flush slicing can pause with an active epoch and resume in a later
          // microtask; restore phase before draining nodes.
          _setPhase(ExecutionPhase.flushing);
        }

        _setPhase(ExecutionPhase.computing);
        remainingBudget = _drainComputedPhase(remainingBudget);
        if (remainingBudget <= 0) {
          break;
        }

        _setPhase(ExecutionPhase.effectRunning);
        remainingBudget = _drainEffectPhase(remainingBudget);
        if (remainingBudget <= 0) {
          break;
        }

        if (_activeComputed.isEmpty && _activeEffects.isEmpty) {
          _completeEpoch();
        }
      }
    } finally {
      stopwatch.stop();
      _lastFlushDuration = stopwatch.elapsed;
      _flushWindowMicros.add(_lastFlushDuration.inMicroseconds);
      while (_flushWindowMicros.length > _flushWindowSize) {
        _flushWindowMicros.removeFirst();
      }

      _setPhase(ExecutionPhase.idle);
      _isFlushing = false;
      if (hasPending) {
        _ensureFlushScheduled();
      }
    }
  }

  void _startEpoch() {
    for (final int nodeId in _touchedEffects.toList(growable: false)) {
      final NodeRecord? record = _graph.maybeRecordOf(nodeId);
      if (record != null && !record.disposed) {
        record.runCountInEpoch = 0;
      }
    }
    _touchedEffects.clear();

    _flushEpoch++;
    _setPhase(ExecutionPhase.flushing);
    _epochInProgress = true;
    _trace(SchedulerTraceKind.epochStart, message: 'epoch=$_flushEpoch');

    _applyDeferredWritesForCurrentEpoch();
    _movePendingToActive();
  }

  void _completeEpoch() {
    _notifyFlushListeners();
    _setPhase(ExecutionPhase.flushing);
    _epochInProgress = false;

    assert(() {
      if (!_enableInvariantAuditInDebug) {
        return true;
      }
      final GraphInvariantResult result = _graph.debugVerifyInvariantDetails(
        queuesAreEmpty:
            _activeComputed.isEmpty &&
            _activeEffects.isEmpty &&
            _pendingComputed.isEmpty &&
            _pendingEffects.isEmpty,
      );
      if (!result.ok) {
        _trace(
          SchedulerTraceKind.error,
          message: 'Invariant failure: ${result.issues.join('; ')}',
        );
        throw StateError(
          'Virex graph invariant failure after epoch $_flushEpoch: '
          '${result.issues.join('; ')}',
        );
      }
      return true;
    }());
  }

  void _applyDeferredWritesForCurrentEpoch() {
    if (_deferredWrites.isEmpty) {
      return;
    }

    _applyingDeferredWrites = true;
    try {
      while (_deferredWrites.isNotEmpty) {
        final _DeferredWrite next = _deferredWrites.first;
        if (next.targetEpoch > _flushEpoch) {
          break;
        }
        _deferredWrites.removeFirst();
        _trace(
          SchedulerTraceKind.deferredWriteApplied,
          nodeId: next.nodeId,
          message: 'targetEpoch=${next.targetEpoch} seq=${next.sequence}',
        );
        try {
          next.apply();
        } catch (error, stackTrace) {
          _reportError(error, stackTrace, nodeId: next.nodeId);
        }
      }
    } finally {
      _applyingDeferredWrites = false;
    }
  }

  void _movePendingToActive() {
    while (_pendingComputed.isNotEmpty) {
      _activeComputed.add(_pendingComputed.removeFirst());
    }
    while (_pendingEffects.isNotEmpty) {
      _activeEffects.add(_pendingEffects.removeFirst());
    }
  }

  int _drainComputedPhase(int remainingBudget) {
    while (_activeComputed.isNotEmpty && remainingBudget > 0) {
      final int nodeId = _activeComputed.removeFirst();
      final NodeRecord? record = _graph.maybeRecordOf(nodeId);
      if (record == null || record.disposed || !record.dirty) {
        continue;
      }

      final NodeRunner? runner = _computedRunners[nodeId];
      if (runner == null) {
        continue;
      }

      _trace(SchedulerTraceKind.runComputed, nodeId: nodeId);
      try {
        runner();
      } catch (error, stackTrace) {
        _reportError(error, stackTrace, nodeId: nodeId);
      }
      remainingBudget -= 1;
    }
    return remainingBudget;
  }

  int _drainEffectPhase(int remainingBudget) {
    while (_activeEffects.isNotEmpty && remainingBudget > 0) {
      final int nodeId = _activeEffects.removeFirst();
      final NodeRecord? record = _graph.maybeRecordOf(nodeId);
      if (record == null || record.disposed) {
        continue;
      }

      if (record.coolOffUntilEpoch >= _flushEpoch) {
        continue;
      }

      _touchedEffects.add(nodeId);
      record.runCountInEpoch += 1;
      if (record.runCountInEpoch > effectLoopThreshold) {
        record.consecutiveLoopBreaches += 1;
        final int coolOffEpochs = record.consecutiveLoopBreaches >= 3 ? 2 : 1;
        record.coolOffUntilEpoch = _flushEpoch + coolOffEpochs - 1;
        assert(
          false,
          'Potential infinite effect loop detected for node $nodeId in epoch $_flushEpoch.',
        );
        _reportError(
          StateError(
            'Potential infinite effect loop detected for node $nodeId.',
          ),
          StackTrace.current,
          nodeId: nodeId,
        );
        continue;
      }

      final NodeRunner? runner = _effectRunners[nodeId];
      if (runner == null) {
        continue;
      }

      _trace(SchedulerTraceKind.runEffect, nodeId: nodeId);
      try {
        runner();
        markComputedInEpoch(nodeId);
        record.consecutiveLoopBreaches = 0;
      } catch (error, stackTrace) {
        _reportError(error, stackTrace, nodeId: nodeId);
      }
      remainingBudget -= 1;
    }
    return remainingBudget;
  }

  void _reportError(Object error, StackTrace stackTrace, {int? nodeId}) {
    _trace(SchedulerTraceKind.error, nodeId: nodeId, message: '$error');
    if (onError != null) {
      onError!(error, stackTrace);
      return;
    }
    Zone.current.handleUncaughtError(error, stackTrace);
  }

  void _notifyFlushListeners() {
    if (_flushListeners.isEmpty) {
      return;
    }

    for (final FlushEpochListener listener in _flushListeners.toList(
      growable: false,
    )) {
      try {
        listener(_flushEpoch);
      } catch (error, stackTrace) {
        _reportError(error, stackTrace);
      }
    }
  }

  void _setPhase(ExecutionPhase next) {
    if (_phase == next) {
      return;
    }

    final bool valid = switch (_phase) {
      ExecutionPhase.idle =>
        next == ExecutionPhase.flushing || next == ExecutionPhase.idle,
      ExecutionPhase.tracking =>
        next == ExecutionPhase.idle ||
            next == ExecutionPhase.flushing ||
            next == ExecutionPhase.computing ||
            next == ExecutionPhase.effectRunning,
      ExecutionPhase.flushing =>
        next == ExecutionPhase.computing ||
            next == ExecutionPhase.idle ||
            next == ExecutionPhase.effectRunning,
      ExecutionPhase.computing =>
        next == ExecutionPhase.effectRunning ||
            next == ExecutionPhase.flushing ||
            next == ExecutionPhase.idle,
      ExecutionPhase.effectRunning =>
        next == ExecutionPhase.flushing || next == ExecutionPhase.idle,
    };

    assert(valid, 'Invalid phase transition: $_phase -> $next');
    if (!valid) {
      throw StateError('Invalid phase transition: $_phase -> $next');
    }
    _phase = next;
  }

  void _trace(SchedulerTraceKind kind, {int? nodeId, String? message}) {
    if (!_traceEnabled) {
      return;
    }
    _traceCounter += 1;
    if (_traceCounter % _traceSampleEveryN != 0) {
      return;
    }
    _traceBuffer.add(
      VirexSchedulerTraceRecord(
        kind: kind,
        epoch: _flushEpoch,
        timestamp: DateTime.now().toUtc(),
        nodeId: nodeId,
        message: message,
      ),
    );
    while (_traceBuffer.length > _traceCapacity) {
      _traceBuffer.removeFirst();
    }
  }

  Duration _p95Window() {
    if (_flushWindowMicros.isEmpty) {
      return Duration.zero;
    }
    final List<int> sorted = _flushWindowMicros.toList(growable: false)..sort();
    final int index = ((sorted.length - 1) * 0.95).round();
    return Duration(microseconds: sorted[index]);
  }

  void debugResetForTests() {
    _pendingComputed.clear();
    _pendingEffects.clear();
    _activeComputed.clear();
    _activeEffects.clear();
    _deferredWrites.clear();
    _computedRunners.clear();
    _effectRunners.clear();
    _flushListeners.clear();
    _touchedEffects.clear();
    _flushWindowMicros.clear();
    _phaseStack.clear();
    _traceBuffer.clear();
    _phase = ExecutionPhase.idle;
    _flushScheduled = false;
    _isFlushing = false;
    _applyingDeferredWrites = false;
    _epochInProgress = false;
    _batchDepth = 0;
    _flushEpoch = 0;
    _deferredWriteSequence = 0;
    _deferredWriteCount = 0;
    effectLoopThreshold = 100;
    _maxNodesPerFlushSlice = 0;
    _enableInvariantAuditInDebug = true;
    _lastFlushDuration = Duration.zero;
    _traceEnabled = false;
    _traceCapacity = 20000;
    _traceSampleEveryN = 1;
    _traceCounter = 0;
    onError = null;
  }
}
