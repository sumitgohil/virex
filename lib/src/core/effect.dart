import 'dart:async';

import 'dependency_graph.dart';
import 'runtime.dart';

typedef EffectCallback = void Function();
typedef EffectErrorHandler = void Function(Object error, StackTrace stackTrace);

/// Disposable handle for a reactive effect.
final class EffectHandle {
  EffectHandle._(this._node);

  final _EffectNode _node;

  /// Whether the effect has already been disposed.
  bool get disposed => _node.disposed;

  /// Cancels the effect and detaches all subscriptions.
  void dispose() => _node.dispose();
}

final class _EffectNode {
  _EffectNode({
    required EffectCallback callback,
    this.name,
    this.debounce,
    this.throttle,
    this.onError,
    required this.immediate,
  }) : _callback = callback {
    _nodeId = ReactiveRuntime.instance.createNode(NodeKind.effect, name: name);
    ReactiveRuntime.instance.scheduler.registerEffectRunner(
      _nodeId,
      _runFromScheduler,
    );

    if (immediate) {
      _execute();
    } else {
      ReactiveRuntime.instance.scheduler.enqueueEffect(_nodeId);
    }
  }

  final EffectCallback _callback;
  final String? name;
  final Duration? debounce;
  final Duration? throttle;
  final EffectErrorHandler? onError;
  final bool immediate;

  late final int _nodeId;
  bool _disposed = false;
  bool _isRunning = false;

  Timer? _debounceTimer;
  Timer? _throttleTimer;
  DateTime? _lastRunAt;

  bool get disposed => _disposed;

  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _debounceTimer?.cancel();
    _throttleTimer?.cancel();
    ReactiveRuntime.instance.disposeNode(_nodeId);
  }

  void _runFromScheduler() {
    if (_disposed) {
      return;
    }

    if (debounce != null) {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(debounce!, () {
        if (_disposed) {
          return;
        }
        _debounceTimer = null;
        _execute();
      });
      return;
    }

    if (throttle != null && _lastRunAt != null) {
      final Duration elapsed = DateTime.now().difference(_lastRunAt!);
      if (elapsed < throttle!) {
        final Duration remaining = throttle! - elapsed;
        _throttleTimer ??= Timer(remaining, () {
          _throttleTimer = null;
          if (_disposed) {
            return;
          }
          _execute();
        });
        return;
      }
    }

    _execute();
  }

  void _execute() {
    if (_disposed || _isRunning) {
      return;
    }

    _isRunning = true;
    try {
      final Set<int> deps = ReactiveRuntime.instance.collectDependencies(
        _nodeId,
        _callback,
      );
      if (_disposed) {
        return;
      }
      ReactiveRuntime.instance.replaceDependencies(_nodeId, deps);
      ReactiveRuntime.instance.scheduler.markComputedInEpoch(_nodeId);
      _lastRunAt = DateTime.now();
    } catch (error, stackTrace) {
      if (onError != null) {
        onError!(error, stackTrace);
      } else {
        Zone.current.handleUncaughtError(error, stackTrace);
      }
      if (!_disposed) {
        ReactiveRuntime.instance.scheduler.markComputedInEpoch(_nodeId);
      }
    } finally {
      _isRunning = false;
    }
  }
}

/// Creates a reactive side-effect and returns its disposal handle.
///
/// The effect tracks all signals/computeds read during execution and reruns
/// when those dependencies change.
EffectHandle effect(
  EffectCallback run, {
  String? name,
  bool immediate = true,
  Duration? debounce,
  Duration? throttle,
  EffectErrorHandler? onError,
}) {
  final _EffectNode node = _EffectNode(
    callback: run,
    name: name,
    immediate: immediate,
    debounce: debounce,
    throttle: throttle,
    onError: onError,
  );
  return EffectHandle._(node);
}
