import 'dependency_graph.dart';
import 'runtime.dart';

typedef Equality<T> = bool Function(T a, T b);

/// Mutable reactive value with dependency tracking and deterministic updates.
final class Signal<T> {
  Signal._(this._value, {Equality<T>? equals, this.name})
    : _equals = equals ?? _defaultEquals {
    _nodeId = ReactiveRuntime.instance.createNode(NodeKind.signal, name: name);
  }

  late final int _nodeId;
  T _value;
  final Equality<T> _equals;

  final String? name;
  bool _disposed = false;

  /// Internal node id used by the dependency graph registry.
  int get nodeId => _nodeId;

  /// Returns the current value and tracks this signal in active reactive scopes.
  T get value {
    assert(!_disposed, 'Signal ${name ?? _nodeId} read after dispose.');
    ReactiveRuntime.instance.trackRead(_nodeId);
    return _value;
  }

  /// Updates the signal value and invalidates subscribers when the value changed.
  set value(T next) {
    assert(!_disposed, 'Signal ${name ?? _nodeId} updated after dispose.');
    if (_disposed) {
      return;
    }

    if (_equals(_value, next)) {
      return;
    }
    final ReactiveRuntime runtime = ReactiveRuntime.instance;
    runtime.handleSignalWrite(
      sourceId: _nodeId,
      sourceLabel: name ?? '$_nodeId',
      apply: () {
        _value = next;
        runtime.markSourceChanged(_nodeId);
      },
    );
  }

  bool get disposed => _disposed;

  /// Releases this signal from the graph and detaches all subscriptions.
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    ReactiveRuntime.instance.disposeNode(_nodeId);
  }
}

/// Creates a reactive mutable signal.
Signal<T> signal<T>(T initial, {Equality<T>? equals, String? name}) {
  return Signal<T>._(initial, equals: equals, name: name);
}

bool _defaultEquals<T>(T a, T b) => a == b;
