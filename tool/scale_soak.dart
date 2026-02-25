import 'dart:math';
import 'dart:io';

import 'package:virex/src/core/runtime.dart';
import 'package:virex/virex_core.dart';

void main(List<String> args) {
  int durationHours = 8;
  for (final String arg in args) {
    if (arg.startsWith('--duration-hours=')) {
      durationHours = int.tryParse(arg.split('=').last) ?? 8;
    }
  }

  final Duration duration = Duration(hours: durationHours);
  final DateTime endAt = DateTime.now().toUtc().add(duration);
  final Random random = Random(42);

  ReactiveRuntime.instance.debugResetForTests();
  final List<Signal<int>> signals = List<Signal<int>>.generate(
    1000,
    (int i) => signal<int>(i),
    growable: false,
  );

  int iterations = 0;
  while (DateTime.now().toUtc().isBefore(endAt)) {
    for (int i = 0; i < 2000; i++) {
      final int idx = random.nextInt(signals.length);
      signals[idx].value = random.nextInt(1000000);
    }
    VirexScheduler.instance.flush();
    iterations += 1;
  }

  final int retained = ReactiveRuntime.instance.graph.nodes.length;
  if (retained > signals.length + 5) {
    throw StateError('Unexpected retained node count after soak: $retained');
  }

  for (final Signal<int> signalNode in signals) {
    signalNode.dispose();
  }

  stdout.writeln(
    'Scale soak completed iterations=$iterations retained=$retained',
  );
}
