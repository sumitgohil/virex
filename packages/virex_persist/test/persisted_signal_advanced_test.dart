import 'package:test/test.dart';
import 'package:virex/virex_core.dart';
import 'package:virex_persist/virex_persist.dart';

final class _RecordingStore implements VirexStore {
  final Map<String, String> values = <String, String>{};
  int writeCount = 0;
  bool throwOnRead = false;
  bool throwOnWrite = false;

  @override
  Future<String?> read(String key) async {
    if (throwOnRead) {
      throw StateError('read failed');
    }
    return values[key];
  }

  @override
  Future<void> write(String key, String value) async {
    if (throwOnWrite) {
      throw StateError('write failed');
    }
    writeCount += 1;
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }
}

void main() {
  setUp(debugResetVirexForTests);

  test(
    'hydrate decode errors are reported and initial value is retained',
    () async {
      final _RecordingStore store = _RecordingStore()..values['age'] = 'bad';
      final List<Object> errors = <Object>[];

      final PersistedSignal<int> persisted = await PersistedSignal.create<int>(
        key: 'age',
        initial: 18,
        store: store,
        toStorage: (int value) => value.toString(),
        fromStorage: int.parse,
        onError: (Object error, StackTrace stackTrace) => errors.add(error),
      );

      expect(persisted.node.value, 18);
      expect(errors, hasLength(1));

      persisted.dispose();
    },
  );

  test(
    'write failures are reported without throwing from signal updates',
    () async {
      final _RecordingStore store = _RecordingStore()..throwOnWrite = true;
      final List<Object> errors = <Object>[];

      final PersistedSignal<int> persisted = await PersistedSignal.create<int>(
        key: 'counter',
        initial: 0,
        store: store,
        toStorage: (int value) => value.toString(),
        fromStorage: int.parse,
        onError: (Object error, StackTrace stackTrace) => errors.add(error),
      );

      persisted.node.value = 1;
      VirexScheduler.instance.flush();
      await Future<void>.delayed(Duration.zero);

      expect(errors, isNotEmpty);
      persisted.dispose();
    },
  );

  test('debounced persistence coalesces rapid updates', () async {
    final _RecordingStore store = _RecordingStore();

    final PersistedSignal<int> persisted = await PersistedSignal.create<int>(
      key: 'debounced',
      initial: 0,
      store: store,
      toStorage: (int value) => value.toString(),
      fromStorage: int.parse,
      writeDebounce: const Duration(milliseconds: 25),
    );

    persisted.node.value = 1;
    persisted.node.value = 2;
    persisted.node.value = 3;
    VirexScheduler.instance.flush();

    await Future<void>.delayed(const Duration(milliseconds: 60));
    expect(store.values['debounced'], '3');
    expect(store.writeCount, lessThanOrEqualTo(2));

    persisted.dispose();
  });

  test('dispose is idempotent and clearPersistedValue still works', () async {
    final _RecordingStore store = _RecordingStore();

    final PersistedSignal<int> persisted = await PersistedSignal.create<int>(
      key: 'session',
      initial: 7,
      store: store,
      toStorage: (int value) => value.toString(),
      fromStorage: int.parse,
    );
    await Future<void>.delayed(Duration.zero);
    expect(store.values['session'], '7');

    persisted.dispose();
    expect(() => persisted.dispose(), returnsNormally);

    await persisted.clearPersistedValue();
    expect(store.values.containsKey('session'), isFalse);
  });
}
