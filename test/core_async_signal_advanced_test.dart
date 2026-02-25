import 'package:flutter_test/flutter_test.dart';
import 'package:virex/virex.dart';

import '_test_utils.dart';

void main() {
  setUp(resetRuntime);

  test(
    'synchronous throw is captured as AsyncState.error and reported',
    () async {
      Object? reported;
      final AsyncSignal<int> value = asyncSignal<int>(
        () {
          throw StateError('sync failure');
        },
        autoStart: false,
        onError: (Object error, StackTrace stackTrace) {
          reported = error;
        },
      );

      await value.refresh();

      expect(value.value.error, isA<StateError>());
      expect(reported, isA<StateError>());
      value.dispose();
    },
  );

  test('debounced refresh supersedes older future without hanging', () async {
    int calls = 0;
    final AsyncSignal<int> value = asyncSignal<int>(
      () async {
        calls += 1;
        return calls;
      },
      autoStart: false,
      debounce: const Duration(milliseconds: 20),
    );

    final Future<void> first = value.refresh().timeout(
      const Duration(milliseconds: 200),
    );
    final Future<void> second = value.refresh().timeout(
      const Duration(milliseconds: 200),
    );

    await Future.wait(<Future<void>>[first, second]);
    await Future<void>.delayed(const Duration(milliseconds: 30));

    expect(calls, 1);
    expect(value.value.data, 1);
    value.dispose();
  });

  test('debounced refresh future resolves after dispose', () async {
    final AsyncSignal<int> value = asyncSignal<int>(
      () async => 1,
      autoStart: false,
      debounce: const Duration(milliseconds: 50),
    );

    final Future<void> pending = value.refresh().timeout(
      const Duration(milliseconds: 200),
    );
    value.dispose();

    await pending;
    expect(value.disposed, isTrue);
  });

  test('refresh after dispose is a completed no-op', () async {
    final AsyncSignal<int> value = asyncSignal<int>(
      () async => 1,
      autoStart: false,
    );
    value.dispose();

    await expectLater(value.refresh(), completes);
  });
}
