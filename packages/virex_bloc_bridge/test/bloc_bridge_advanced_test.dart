import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:test/test.dart';
import 'package:virex/virex_core.dart';
import 'package:virex_bloc_bridge/virex_bloc_bridge.dart';

final class _CounterCubit extends Cubit<int> {
  _CounterCubit() : super(0);

  void increment() => emit(state + 1);
}

void main() {
  setUp(debugResetVirexForTests);

  test('signalFromCubit handles rapid emissions deterministically', () async {
    final _CounterCubit cubit = _CounterCubit();
    final Signal<int> mirrored = signalFromCubit<int>(cubit, name: 'counter');

    for (int i = 0; i < 100; i++) {
      cubit.increment();
    }
    await Future<void>.delayed(Duration.zero);

    expect(mirrored.value, 100);

    mirrored.dispose();
    await cubit.close();
  });

  test('signalFromCubit ignores emissions after signal dispose', () async {
    final _CounterCubit cubit = _CounterCubit();
    final Signal<int> mirrored = signalFromCubit<int>(cubit);

    mirrored.dispose();
    expect(() => cubit.increment(), returnsNormally);
    await Future<void>.delayed(Duration.zero);

    expect(mirrored.disposed, isTrue);
    await cubit.close();
  });

  test('bloc migration report preserves supplied metadata', () {
    final VirexMigrationReport report = blocMigrationReport(
      feature: 'checkout',
      riskFlags: const <String>['event-ordering'],
      rollbackSteps: const <String>['re-enable cubit path'],
      estimatedDevDays: 2.25,
      notes: 'pilot migration',
    );

    expect(report.sourceFramework, 'bloc');
    expect(report.feature, 'checkout');
    expect(report.riskFlags, contains('event-ordering'));
    expect(report.rollbackSteps, contains('re-enable cubit path'));
    expect(report.estimatedDevDays, 2.25);
    expect(report.notes, 'pilot migration');
  });
}
