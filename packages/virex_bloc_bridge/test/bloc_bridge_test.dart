import 'package:bloc/bloc.dart';
import 'package:test/test.dart';
import 'package:virex/virex_core.dart';
import 'package:virex_bloc_bridge/virex_bloc_bridge.dart';

final class CounterCubit extends Cubit<int> {
  CounterCubit() : super(0);

  void increment() => emit(state + 1);
}

void main() {
  test('signalFromCubit mirrors cubit stream', () async {
    final CounterCubit cubit = CounterCubit();
    final Signal<int> mirrored = signalFromCubit<int>(cubit);

    cubit.increment();
    await Future<void>.delayed(Duration.zero);

    expect(mirrored.value, 1);

    cubit.close();
    mirrored.dispose();
  });

  test('effectToBlocEvent forwards payload', () {
    int? observed;
    final void Function(int event) emit = effectToBlocEvent<int>((int event) {
      observed = event;
    });

    emit(7);
    expect(observed, 7);
  });
}
