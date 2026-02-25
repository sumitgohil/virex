import 'dart:async';

import 'package:virex/virex_core.dart';

import 'persisted_policy.dart';
import 'store.dart';

typedef SignalEncoder<T> = String Function(T value);
typedef SignalDecoder<T> = T Function(String raw);
typedef PersistErrorHandler =
    void Function(Object error, StackTrace stackTrace);

/// A signal with automatic persistence to an external [VirexStore].
final class PersistedSignal<T> {
  PersistedSignal._({
    required this.key,
    required this.node,
    required VirexStore store,
    required EffectHandle writerEffect,
    this.onError,
  }) : _store = store,
       _writerEffect = writerEffect;

  /// Storage key used for persisted data.
  final String key;

  /// Backing reactive signal.
  final Signal<T> node;

  final VirexStore _store;
  final EffectHandle _writerEffect;

  /// Optional callback for persistence errors.
  final PersistErrorHandler? onError;

  bool _disposed = false;

  /// Creates a persisted signal and hydrates it from storage if present.
  static Future<PersistedSignal<T>> create<T>({
    required String key,
    required T initial,
    required VirexStore store,
    required SignalEncoder<T> toStorage,
    required SignalDecoder<T> fromStorage,
    String? name,
    Duration? writeDebounce,
    PersistedSignalPolicy policy = const PersistedSignalPolicy(),
    PersistErrorHandler? onError,
  }) async {
    final Signal<T> node = signal<T>(initial, name: name ?? key);

    try {
      final String? saved = await store.read(key);
      if (saved != null) {
        node.value = fromStorage(saved);
      }
    } catch (error, stackTrace) {
      onError?.call(error, stackTrace);
    }

    final Duration? debounce =
        policy.flushPolicy == PersistFlushPolicy.immediate
        ? null
        : writeDebounce;

    final EffectHandle writer = effect(() {
      final String encoded = toStorage(node.value);
      unawaited(_safeWrite(store, key, encoded, onError));
    }, debounce: debounce);

    return PersistedSignal<T>._(
      key: key,
      node: node,
      store: store,
      writerEffect: writer,
      onError: onError,
    );
  }

  bool get disposed => _disposed;

  /// Deletes persisted value from backing store.
  Future<void> clearPersistedValue() {
    return _store.delete(key);
  }

  /// Releases signal and persistence effect resources.
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _writerEffect.dispose();
    node.dispose();
  }

  static Future<void> _safeWrite(
    VirexStore store,
    String key,
    String value,
    PersistErrorHandler? onError,
  ) async {
    try {
      await store.write(key, value);
    } catch (error, stackTrace) {
      onError?.call(error, stackTrace);
    }
  }
}
