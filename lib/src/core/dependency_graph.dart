import 'dart:collection';

enum NodeKind { signal, computed, effect }

final class NodeRecord {
  NodeRecord({required this.id, required this.kind, this.name});

  final int id;
  final NodeKind kind;
  final String? name;

  final Set<int> dependencies = <int>{};
  final Set<int> subscribers = <int>{};

  bool disposed = false;
  bool dirty = false;
  bool hasError = false;

  int lastEnqueuedEpoch = -1;
  int lastComputedEpoch = -1;
  int runCountInEpoch = 0;
  int consecutiveLoopBreaches = 0;
  int coolOffUntilEpoch = -1;

  Object? lastError;
  StackTrace? lastStackTrace;
}

final class GraphInvariantIssue {
  const GraphInvariantIssue({
    required this.invariantName,
    required this.offenderNodeIds,
    required this.message,
  });

  final String invariantName;
  final List<int> offenderNodeIds;
  final String message;

  @override
  String toString() {
    return '$invariantName offenders=$offenderNodeIds message=$message';
  }
}

final class GraphInvariantResult {
  const GraphInvariantResult._(this.issues);

  final List<GraphInvariantIssue> issues;

  bool get ok => issues.isEmpty;
}

final class TrackingScope {
  TrackingScope(this.ownerId);

  final int ownerId;
  final Set<int> reads = <int>{};
}

final class ReactiveGraph {
  ReactiveGraph._();

  static final ReactiveGraph instance = ReactiveGraph._();

  final Map<int, NodeRecord> _nodes = <int, NodeRecord>{};
  final List<TrackingScope> _trackingStack = <TrackingScope>[];
  final List<int> _computeStack = <int>[];

  int _nextNodeId = 1;

  UnmodifiableMapView<int, NodeRecord> get nodes =>
      UnmodifiableMapView<int, NodeRecord>(_nodes);

  NodeRecord recordOf(int id) {
    final NodeRecord? record = _nodes[id];
    if (record == null || record.disposed) {
      throw StateError('Node $id is not active.');
    }
    return record;
  }

  NodeRecord? maybeRecordOf(int id) => _nodes[id];

  int registerNode(NodeKind kind, {String? name}) {
    final int id = _nextNodeId++;
    _nodes[id] = NodeRecord(id: id, kind: kind, name: name);
    return id;
  }

  void markError(int id, Object error, StackTrace stackTrace) {
    final NodeRecord record = recordOf(id);
    record.hasError = true;
    record.lastError = error;
    record.lastStackTrace = stackTrace;
  }

  void clearError(int id) {
    final NodeRecord record = recordOf(id);
    record.hasError = false;
    record.lastError = null;
    record.lastStackTrace = null;
  }

  void setDirty(int id, bool dirty) {
    final NodeRecord record = recordOf(id);
    record.dirty = dirty;
  }

  bool isDirty(int id) {
    final NodeRecord record = recordOf(id);
    return record.dirty;
  }

  void disposeNode(int id) {
    final NodeRecord? record = _nodes[id];
    if (record == null || record.disposed) {
      return;
    }

    final List<int> deps = record.dependencies.toList(growable: false);
    final List<int> subs = record.subscribers.toList(growable: false);

    for (final int dep in deps) {
      _nodes[dep]?.subscribers.remove(id);
    }
    for (final int sub in subs) {
      _nodes[sub]?.dependencies.remove(id);
    }

    record.dependencies.clear();
    record.subscribers.clear();
    record.disposed = true;
    _nodes.remove(id);
  }

  void beginTracking(int ownerId) {
    _trackingStack.add(TrackingScope(ownerId));
  }

  Set<int> endTracking() {
    if (_trackingStack.isEmpty) {
      throw StateError('Tracking stack underflow.');
    }
    final TrackingScope scope = _trackingStack.removeLast();
    return scope.reads;
  }

  int? get currentTrackingOwnerId =>
      _trackingStack.isEmpty ? null : _trackingStack.last.ownerId;

  void trackRead(int sourceId) {
    if (_trackingStack.isEmpty) {
      return;
    }
    _trackingStack.last.reads.add(sourceId);
  }

  void replaceDependencies(int ownerId, Set<int> nextDependencies) {
    final NodeRecord owner = recordOf(ownerId);

    final Set<int> previous = Set<int>.from(owner.dependencies);

    for (final int oldDep in previous) {
      if (!nextDependencies.contains(oldDep)) {
        _nodes[oldDep]?.subscribers.remove(ownerId);
        owner.dependencies.remove(oldDep);
      }
    }

    for (final int newDep in nextDependencies) {
      if (newDep == ownerId) {
        continue;
      }
      final NodeRecord dep = recordOf(newDep);
      owner.dependencies.add(newDep);
      dep.subscribers.add(ownerId);
    }
  }

  List<int> subscribersOf(int id) {
    final NodeRecord record = recordOf(id);
    return record.subscribers.toList(growable: false);
  }

  bool isOnComputeStack(int id) => _computeStack.contains(id);
  bool get hasActiveCompute => _computeStack.isNotEmpty;

  void pushCompute(int id) {
    _computeStack.add(id);
  }

  void popCompute(int id) {
    if (_computeStack.isEmpty || _computeStack.last != id) {
      throw StateError('Compute stack corruption for node $id.');
    }
    _computeStack.removeLast();
  }

  GraphInvariantResult debugVerifyInvariantDetails({
    required bool queuesAreEmpty,
  }) {
    final List<GraphInvariantIssue> issues = <GraphInvariantIssue>[];

    for (final NodeRecord record in _nodes.values) {
      if (record.disposed) {
        issues.add(
          GraphInvariantIssue(
            invariantName: 'record_not_disposed_in_registry',
            offenderNodeIds: <int>[record.id],
            message: 'Disposed node should not remain in registry.',
          ),
        );
      }

      for (final int depId in record.dependencies) {
        final NodeRecord? dep = _nodes[depId];
        if (dep == null) {
          issues.add(
            GraphInvariantIssue(
              invariantName: 'dependency_exists',
              offenderNodeIds: <int>[record.id, depId],
              message: 'Dependency $depId missing from registry.',
            ),
          );
          continue;
        }
        if (!dep.subscribers.contains(record.id)) {
          issues.add(
            GraphInvariantIssue(
              invariantName: 'dependency_reciprocity',
              offenderNodeIds: <int>[record.id, depId],
              message: 'Dependency/subscriber edge mismatch.',
            ),
          );
        }
      }

      for (final int subId in record.subscribers) {
        final NodeRecord? sub = _nodes[subId];
        if (sub == null) {
          issues.add(
            GraphInvariantIssue(
              invariantName: 'subscriber_exists',
              offenderNodeIds: <int>[record.id, subId],
              message: 'Subscriber $subId missing from registry.',
            ),
          );
          continue;
        }
        if (!sub.dependencies.contains(record.id)) {
          issues.add(
            GraphInvariantIssue(
              invariantName: 'subscriber_reciprocity',
              offenderNodeIds: <int>[record.id, subId],
              message: 'Subscriber/dependency edge mismatch.',
            ),
          );
        }
      }

      if (record.kind == NodeKind.computed &&
          record.dirty &&
          record.subscribers.isNotEmpty &&
          queuesAreEmpty) {
        issues.add(
          GraphInvariantIssue(
            invariantName: 'no_dirty_computed_after_flush',
            offenderNodeIds: <int>[record.id],
            message: 'Dirty computed remained after queues emptied.',
          ),
        );
      }
    }

    return GraphInvariantResult._(issues);
  }

  bool debugVerifyInvariants({required bool queuesAreEmpty}) {
    return debugVerifyInvariantDetails(queuesAreEmpty: queuesAreEmpty).ok;
  }

  void debugResetForTests() {
    _nodes.clear();
    _trackingStack.clear();
    _computeStack.clear();
    _nextNodeId = 1;
  }
}
