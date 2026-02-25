import 'package:virex/src/core/runtime.dart';
import 'package:virex/virex_core.dart';

void resetRuntime() {
  ReactiveRuntime.instance.debugResetForTests();
  VirexInspector.instance.debugResetForTests();
  VirexInspector.instance.configureSampling(maxEventsPerSecond: 1000000);
}

void flushUntilIdle({int maxFlushes = 1000}) {
  for (int i = 0; i < maxFlushes; i++) {
    VirexScheduler.instance.flush();
    if (!VirexScheduler.instance.hasPending) {
      return;
    }
  }
  throw StateError('flushUntilIdle exceeded $maxFlushes iterations.');
}
