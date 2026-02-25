import 'dart:async';

import 'package:riverpod/riverpod.dart';
import 'package:virex/virex_core.dart';

/// StateNotifier wrapper that mirrors a [Signal] value into Riverpod state.
final class SignalNotifier<T> extends StateNotifier<T> {
  SignalNotifier(this.signal)
    : _disposeEffect = effect(() {}),
      super(signal.value) {
    _disposeEffect.dispose();
    _disposeEffect = effect(() {
      state = signal.value;
    });
  }

  final Signal<T> signal;
  EffectHandle _disposeEffect;

  @override
  void dispose() {
    _disposeEffect.dispose();
    super.dispose();
  }
}

/// Creates a Riverpod provider backed by a Virex [Signal].
StateNotifierProvider<SignalNotifier<T>, T> riverpodSignalProvider<T>(
  Signal<T> signal,
) {
  return StateNotifierProvider<SignalNotifier<T>, T>((Ref ref) {
    return SignalNotifier<T>(signal);
  });
}

/// Creates a Virex signal that follows a Riverpod [StateNotifier].
Signal<T> signalFromStateNotifier<T>(
  StateNotifier<T> notifier, {
  String? name,
}) {
  Signal<T>? bridge;
  bool detached = false;
  late final void Function() removeListener;
  void detachListener() {
    if (detached) {
      return;
    }
    detached = true;
    removeListener();
  }

  removeListener = notifier.addListener((T state) {
    final Signal<T>? node = bridge;
    if (node == null) {
      bridge = signal<T>(state, name: name);
      return;
    }
    if (node.disposed) {
      scheduleMicrotask(detachListener);
      return;
    }
    node.value = state;
  }, fireImmediately: true);

  final Signal<T>? node = bridge;
  if (node == null) {
    detachListener();
    throw StateError('StateNotifier did not emit an initial state.');
  }
  return node;
}

/// Builds a structured migration report for Riverpod-to-Virex transitions.
VirexMigrationReport riverpodMigrationReport({
  required String feature,
  List<String> riskFlags = const <String>[],
  List<String> rollbackSteps = const <String>[],
  double estimatedDevDays = 1.5,
  String? notes,
}) {
  return VirexMigrationReport(
    sourceFramework: 'riverpod',
    feature: feature,
    estimatedDevDays: estimatedDevDays,
    riskFlags: riskFlags,
    rollbackSteps: rollbackSteps,
    notes: notes,
  );
}
