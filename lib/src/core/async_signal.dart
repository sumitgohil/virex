import 'dart:async';

import 'signal.dart';

typedef RetryDelayBuilder = Duration Function(int attempt);
typedef AsyncErrorHandler = void Function(Object error, StackTrace stackTrace);

/// State container used by [AsyncSignal] to represent async progression.
final class AsyncState<T> {
  const AsyncState({
    this.data,
    this.error,
    this.stackTrace,
    required this.isLoading,
  });

  factory AsyncState.idle([T? data]) =>
      AsyncState<T>(data: data, isLoading: false);

  factory AsyncState.loading([T? data]) =>
      AsyncState<T>(data: data, isLoading: true);

  factory AsyncState.data(T data) =>
      AsyncState<T>(data: data, isLoading: false);

  factory AsyncState.error(Object error, {StackTrace? stackTrace, T? data}) =>
      AsyncState<T>(
        data: data,
        error: error,
        stackTrace: stackTrace,
        isLoading: false,
      );

  final T? data;
  final Object? error;
  final StackTrace? stackTrace;
  final bool isLoading;

  @override
  bool operator ==(Object other) {
    return other is AsyncState<T> &&
        other.data == data &&
        other.error == error &&
        other.stackTrace == stackTrace &&
        other.isLoading == isLoading;
  }

  @override
  int get hashCode => Object.hash(data, error, stackTrace, isLoading);
}

/// Async reactive primitive with cancellation-by-version semantics.
final class AsyncSignal<T> {
  AsyncSignal._(
    this._loader, {
    this.name,
    required this.autoStart,
    this.debounce,
    required this.maxRetries,
    this.retryDelay,
    this.onError,
  }) : _state = signal<AsyncState<T>>(AsyncState<T>.idle(), name: name) {
    if (autoStart) {
      unawaited(refresh());
    }
  }

  final Future<T> Function() _loader;
  final Signal<AsyncState<T>> _state;
  final String? name;
  final bool autoStart;
  final Duration? debounce;
  final int maxRetries;
  final RetryDelayBuilder? retryDelay;
  final AsyncErrorHandler? onError;

  bool _disposed = false;
  int _requestVersion = 0;
  Timer? _debounceTimer;
  Completer<void>? _pendingDebounceCompleter;

  /// Current async state value.
  AsyncState<T> get value => _state.value;

  /// Last successful data payload.
  T? get data => _state.value.data;

  /// Last error captured in state, if any.
  Object? get error => _state.value.error;

  /// Whether a request is currently in-flight.
  bool get isLoading => _state.value.isLoading;

  /// Whether the async signal has been disposed.
  bool get disposed => _disposed;

  /// Starts a new request and cancels older responses logically by versioning.
  Future<void> refresh() {
    if (_disposed) {
      return Future<void>.value();
    }

    _requestVersion += 1;
    final int version = _requestVersion;

    if (debounce == null) {
      return _execute(version);
    }

    final Completer<void> completer = Completer<void>();
    if (_pendingDebounceCompleter != null &&
        !_pendingDebounceCompleter!.isCompleted) {
      _pendingDebounceCompleter!.complete();
    }
    _pendingDebounceCompleter = completer;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounce!, () async {
      try {
        await _execute(version);
        if (!completer.isCompleted && identical(_pendingDebounceCompleter, completer)) {
          completer.complete();
        }
      } catch (error, stackTrace) {
        if (!completer.isCompleted && identical(_pendingDebounceCompleter, completer)) {
          completer.completeError(error, stackTrace);
        }
      } finally {
        if (identical(_pendingDebounceCompleter, completer)) {
          _pendingDebounceCompleter = null;
        }
      }
    });
    return completer.future;
  }

  /// Releases signal resources and ignores future request completions.
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _requestVersion += 1;
    _debounceTimer?.cancel();
    if (_pendingDebounceCompleter != null &&
        !_pendingDebounceCompleter!.isCompleted) {
      _pendingDebounceCompleter!.complete();
    }
    _pendingDebounceCompleter = null;
    _state.dispose();
  }

  Future<void> _execute(int version) async {
    if (_disposed || version != _requestVersion) {
      return;
    }

    final AsyncState<T> previous = _state.value;
    _state.value = AsyncState<T>.loading(previous.data);

    int attempt = 0;

    while (!_disposed && version == _requestVersion) {
      try {
        final Future<T> task = _loader();
        final T result = await task;

        if (_disposed || version != _requestVersion) {
          return;
        }

        _state.value = AsyncState<T>.data(result);
        return;
      } catch (error, stackTrace) {
        if (_disposed || version != _requestVersion) {
          return;
        }

        if (attempt < maxRetries) {
          attempt += 1;
          final Duration delay =
              retryDelay?.call(attempt) ??
              Duration(milliseconds: attempt * 100);
          if (delay > Duration.zero) {
            await Future<void>.delayed(delay);
          }
          continue;
        }

        _state.value = AsyncState<T>.error(
          error,
          stackTrace: stackTrace,
          data: previous.data,
        );
        onError?.call(error, stackTrace);
        return;
      }
    }
  }
}

/// Creates an [AsyncSignal] bound to [loader].
AsyncSignal<T> asyncSignal<T>(
  Future<T> Function() loader, {
  String? name,
  bool autoStart = true,
  Duration? debounce,
  int maxRetries = 0,
  RetryDelayBuilder? retryDelay,
  AsyncErrorHandler? onError,
}) {
  return AsyncSignal<T>._(
    loader,
    name: name,
    autoStart: autoStart,
    debounce: debounce,
    maxRetries: maxRetries,
    retryDelay: retryDelay,
    onError: onError,
  );
}
