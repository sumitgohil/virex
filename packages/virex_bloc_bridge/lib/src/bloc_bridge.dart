import 'package:bloc/bloc.dart';
import 'package:virex/virex_core.dart';

/// Creates a Virex signal that mirrors the latest Cubit state.
Signal<S> signalFromCubit<S>(Cubit<S> cubit, {String? name}) {
  final Signal<S> node = signal<S>(cubit.state, name: name);

  cubit.stream.listen((S state) {
    if (!node.disposed) {
      node.value = state;
    }
  });

  return node;
}

/// Converts an event emitter into an effect-friendly function.
void Function(E event) effectToBlocEvent<E>(void Function(E event) emit) {
  return (E event) {
    emit(event);
  };
}

/// Builds a structured migration report for BLoC-to-Virex transitions.
VirexMigrationReport blocMigrationReport({
  required String feature,
  List<String> riskFlags = const <String>[],
  List<String> rollbackSteps = const <String>[],
  double estimatedDevDays = 1.8,
  String? notes,
}) {
  return VirexMigrationReport(
    sourceFramework: 'bloc',
    feature: feature,
    estimatedDevDays: estimatedDevDays,
    riskFlags: riskFlags,
    rollbackSteps: rollbackSteps,
    notes: notes,
  );
}
