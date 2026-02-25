import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:virex/virex.dart';

import '_test_utils.dart';

void main() {
  setUp(resetRuntime);

  test('async signal loads initial value', () async {
    final AsyncSignal<int> value = asyncSignal<int>(() async => 42);

    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(value.value.data, 42);
    expect(value.value.isLoading, isFalse);

    value.dispose();
  });

  test('refresh cancels stale responses by versioning', () async {
    final Completer<int> slow = Completer<int>();
    int call = 0;

    final AsyncSignal<int> value = asyncSignal<int>(() {
      call += 1;
      if (call == 1) {
        return slow.future;
      }
      return Future<int>.value(99);
    }, autoStart: false);

    unawaited(value.refresh());
    await value.refresh();
    slow.complete(1);
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(value.value.data, 99);
    value.dispose();
  });

  test('errors map into AsyncState.error and retries recover', () async {
    int attempts = 0;

    final AsyncSignal<String> value = asyncSignal<String>(
      () async {
        attempts += 1;
        if (attempts < 3) {
          throw StateError('try again');
        }
        return 'ok';
      },
      autoStart: false,
      maxRetries: 2,
      retryDelay: (_) => const Duration(milliseconds: 1),
    );

    await value.refresh();
    expect(value.value.data, 'ok');
    expect(value.value.error, isNull);

    value.dispose();
  });

  test('completion after dispose is ignored safely', () async {
    final Completer<int> completer = Completer<int>();
    final AsyncSignal<int> value = asyncSignal<int>(
      () => completer.future,
      autoStart: false,
    );

    unawaited(value.refresh());
    value.dispose();
    completer.complete(1);

    await Future<void>.delayed(const Duration(milliseconds: 5));
    expect(value.disposed, isTrue);
  });
}
