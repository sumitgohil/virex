import 'dependency_graph.dart';
import 'runtime.dart';

/// Thrown when a computed value recursively depends on itself.
final class CircularDependencyError extends Error {
  CircularDependencyError(this.message);

  final String message;

  @override
  String toString() => 'CircularDependencyError: $message';
}

/// Lazily evaluated derived value with cached recomputation.
final class Computed<T> {
  Computed._(this._compute, {this.name}) {
    _nodeId = ReactiveRuntime.instance.createNode(
      NodeKind.computed,
      name: name,
    );
    ReactiveRuntime.instance.graph.setDirty(_nodeId, true);
    ReactiveRuntime.instance.scheduler.registerComputedRunner(
      _nodeId,
      _runFromScheduler,
    );
  }

  final T Function() _compute;
  final String? name;

  late final int _nodeId;
  bool _disposed = false;
  bool _hasValue = false;
  bool _isComputing = false;

  T? _cached;
  Object? _error;
  StackTrace? _stackTrace;

  /// Internal node id used by the dependency graph registry.
  int get nodeId => _nodeId;

  /// Returns the computed value, evaluating lazily when needed.
  ///
  /// If the last compute failed, this getter rethrows the stored error until
  /// dependencies change and a successful recomputation occurs.
  T get value {
    assert(!_disposed, 'Computed ${name ?? _nodeId} read after dispose.');
    ReactiveRuntime.instance.trackRead(_nodeId);

    if (_disposed) {
      throw StateError('Computed ${name ?? _nodeId} is disposed.');
    }

    final bool dirty = ReactiveRuntime.instance.graph.isDirty(_nodeId);
    if (dirty || !_hasValue || _error != null) {
      _recompute(rethrowError: true);
    }

    if (_error != null) {
      Error.throwWithStackTrace(_error!, _stackTrace ?? StackTrace.current);
    }

    return _cached as T;
  }

  bool get disposed => _disposed;

  /// Releases this computed node and all graph links.
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    ReactiveRuntime.instance.disposeNode(_nodeId);
  }

  void _runFromScheduler() {
    if (_disposed) {
      return;
    }

    if (!ReactiveRuntime.instance.graph.isDirty(_nodeId)) {
      return;
    }

    _recompute(rethrowError: false);
  }

  void _recompute({required bool rethrowError}) {
    if (_disposed) {
      return;
    }

    if (_isComputing ||
        ReactiveRuntime.instance.graph.isOnComputeStack(_nodeId)) {
      final CircularDependencyError error = CircularDependencyError(
        'Circular computed dependency detected for ${name ?? _nodeId}.',
      );
      _error = error;
      _stackTrace = StackTrace.current;
      ReactiveRuntime.instance.graph.markError(
        _nodeId,
        error,
        StackTrace.current,
      );
      ReactiveRuntime.instance.graph.setDirty(_nodeId, false);
      ReactiveRuntime.instance.scheduler.markComputedInEpoch(_nodeId);
      if (rethrowError) {
        throw error;
      }
      return;
    }

    _isComputing = true;
    ReactiveRuntime.instance.graph.pushCompute(_nodeId);
    ReactiveRuntime.instance.graph.setDirty(_nodeId, false);

    Object? nextError;
    StackTrace? nextStack;
    T? nextValue;
    bool success = false;

    try {
      nextValue = ReactiveRuntime.instance.collectDependenciesWithResult<T>(
        _nodeId,
        _compute,
      );
      success = true;
    } catch (error, stackTrace) {
      nextError = error;
      nextStack = stackTrace;
    } finally {
      ReactiveRuntime.instance.graph.popCompute(_nodeId);
      _isComputing = false;
      ReactiveRuntime.instance.scheduler.markComputedInEpoch(_nodeId);
    }

    if (_disposed) {
      return;
    }

    if (success) {
      final bool changed = !_hasValue || _error != null || _cached != nextValue;
      _cached = nextValue;
      _hasValue = true;
      _error = null;
      _stackTrace = null;
      ReactiveRuntime.instance.graph.clearError(_nodeId);

      if (changed) {
        ReactiveRuntime.instance.markSourceChanged(_nodeId);
      }
      return;
    }

    final bool changed = _error != nextError;
    _error = nextError;
    _stackTrace = nextStack;
    ReactiveRuntime.instance.graph.markError(
      _nodeId,
      nextError ?? StateError('Unknown compute error.'),
      nextStack ?? StackTrace.current,
    );

    if (changed && nextError is! CircularDependencyError) {
      ReactiveRuntime.instance.markSourceChanged(_nodeId);
    }

    if (rethrowError && nextError != null) {
      Error.throwWithStackTrace(nextError, nextStack ?? StackTrace.current);
    }
  }
}

/// Creates a lazily computed reactive value.
Computed<T> computed<T>(T Function() compute, {String? name}) {
  return Computed<T>._(compute, name: name);
}
