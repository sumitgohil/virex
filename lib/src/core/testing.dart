import 'runtime.dart';

/// Resets all runtime singletons and queues for deterministic test boundaries.
void debugResetVirexForTests() {
  ReactiveRuntime.instance.debugResetForTests();
}
