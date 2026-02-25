import 'dart:async';

import 'package:virex/virex_core.dart';

/// Deterministic runtime control helper for tests.
final class VirexTestHarness {
  VirexTestHarness({VirexScheduler? scheduler})
    : _scheduler = scheduler ?? VirexScheduler.instance;

  final VirexScheduler _scheduler;

  /// Resets global runtime state for a clean deterministic test boundary.
  void resetRuntime() {
    debugResetVirexForTests();
  }

  /// Flushes pending reactive work immediately.
  bool flush() {
    final bool hadPending = _scheduler.hasPending;
    _scheduler.flush();
    return hadPending;
  }

  /// Pumps microtasks in deterministic test loops.
  Future<void> pumpMicrotasks([int times = 1]) async {
    final int loops = times < 1 ? 1 : times;
    for (int i = 0; i < loops; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }
}
