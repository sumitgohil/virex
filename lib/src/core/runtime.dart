import 'dependency_graph.dart';
import 'runtime_config.dart';
import 'scheduler.dart';

final class ReactiveRuntime {
  ReactiveRuntime._();

  static final ReactiveRuntime instance = ReactiveRuntime._();

  final ReactiveGraph graph = ReactiveGraph.instance;
  final VirexScheduler scheduler = VirexScheduler.instance;

  int createNode(NodeKind kind, {String? name}) {
    return graph.registerNode(kind, name: name);
  }

  void disposeNode(int id) {
    scheduler.unregisterNode(id);
    graph.disposeNode(id);
  }

  void trackRead(int sourceId) {
    graph.trackRead(sourceId);
  }

  Set<int> collectDependencies(int ownerId, void Function() action) {
    scheduler.markTrackingStart();
    graph.beginTracking(ownerId);
    bool trackingEnded = false;
    try {
      action();
      final Set<int> deps = graph.endTracking();
      trackingEnded = true;
      return deps;
    } catch (_) {
      if (!trackingEnded) {
        final Set<int> deps = graph.endTracking();
        trackingEnded = true;
        graph.replaceDependencies(ownerId, deps);
      }
      rethrow;
    } finally {
      if (!trackingEnded) {
        graph.endTracking();
      }
      scheduler.markTrackingEnd();
    }
  }

  T collectDependenciesWithResult<T>(int ownerId, T Function() action) {
    scheduler.markTrackingStart();
    graph.beginTracking(ownerId);
    bool trackingEnded = false;
    try {
      final T value = action();
      final Set<int> deps = graph.endTracking();
      trackingEnded = true;
      graph.replaceDependencies(ownerId, deps);
      return value;
    } catch (_) {
      if (!trackingEnded) {
        final Set<int> deps = graph.endTracking();
        trackingEnded = true;
        graph.replaceDependencies(ownerId, deps);
      }
      rethrow;
    } finally {
      if (!trackingEnded) {
        graph.endTracking();
      }
      scheduler.markTrackingEnd();
    }
  }

  void replaceDependencies(int ownerId, Set<int> dependencies) {
    graph.replaceDependencies(ownerId, dependencies);
  }

  void handleSignalWrite({
    required int sourceId,
    required String sourceLabel,
    required void Function() apply,
  }) {
    if (!scheduler.isComputingContext && !graph.hasActiveCompute) {
      apply();
      return;
    }

    final VirexWriteViolationPolicy policy =
        getVirexRuntimeConfig().writeViolationPolicy;
    final String message =
        'Signal $sourceLabel mutated during computed execution.';

    switch (policy) {
      case VirexWriteViolationPolicy.hardFail:
        assert(false, message);
        throw StateError(message);
      case VirexWriteViolationPolicy.deferNextEpoch:
        scheduler.deferWrite(sourceId: sourceId, apply: apply);
        return;
      case VirexWriteViolationPolicy.dropAndLog:
        scheduler.reportRuntimeWarning(message, nodeId: sourceId);
        return;
    }
  }

  void markSourceChanged(int sourceId) {
    final List<int> subscribers = graph.subscribersOf(sourceId);
    final Set<int> visitedComputed = <int>{};
    for (final int subId in subscribers) {
      final NodeRecord? subscriber = graph.maybeRecordOf(subId);
      if (subscriber == null || subscriber.disposed) {
        continue;
      }

      if (subscriber.kind == NodeKind.computed) {
        scheduler.recordInvalidation(subId, NodeKind.computed);
        _invalidateComputed(subId, visitedComputed);
      } else if (subscriber.kind == NodeKind.effect) {
        scheduler.recordInvalidation(subId, NodeKind.effect);
        scheduler.enqueueEffect(subId);
      }
    }
  }

  void _invalidateComputed(int computedId, Set<int> visitedComputed) {
    if (visitedComputed.contains(computedId)) {
      return;
    }
    visitedComputed.add(computedId);

    final NodeRecord? computed = graph.maybeRecordOf(computedId);
    if (computed == null ||
        computed.disposed ||
        computed.kind != NodeKind.computed) {
      return;
    }

    computed.dirty = true;
    if (computed.subscribers.isNotEmpty) {
      scheduler.enqueueComputed(computedId);
    }

    for (final int subId in computed.subscribers) {
      final NodeRecord? subscriber = graph.maybeRecordOf(subId);
      if (subscriber == null || subscriber.disposed) {
        continue;
      }

      if (subscriber.kind == NodeKind.computed) {
        scheduler.recordInvalidation(subId, NodeKind.computed);
        _invalidateComputed(subId, visitedComputed);
      } else if (subscriber.kind == NodeKind.effect) {
        scheduler.recordInvalidation(subId, NodeKind.effect);
        scheduler.enqueueEffect(subId);
      }
    }
  }

  void debugResetForTests() {
    scheduler.debugResetForTests();
    graph.debugResetForTests();
    debugResetVirexRuntimeConfig();
  }
}
