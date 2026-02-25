import 'package:test/test.dart';
import 'package:virex/virex_core.dart';
import 'package:virex_persist/virex_persist.dart';

void main() {
  test('hydrates persisted value from store', () async {
    final MemoryVirexStore store = MemoryVirexStore();
    await store.write('count', '42');

    final PersistedSignal<int> persisted = await PersistedSignal.create<int>(
      key: 'count',
      initial: 0,
      store: store,
      toStorage: (int value) => value.toString(),
      fromStorage: int.parse,
    );

    expect(persisted.node.value, 42);
    persisted.dispose();
  });

  test('persists signal updates', () async {
    final MemoryVirexStore store = MemoryVirexStore();

    final PersistedSignal<int> persisted = await PersistedSignal.create<int>(
      key: 'counter',
      initial: 1,
      store: store,
      toStorage: (int value) => value.toString(),
      fromStorage: int.parse,
    );

    persisted.node.value = 9;
    VirexScheduler.instance.flush();

    expect(store.peek('counter'), '9');
    persisted.dispose();
  });

  test('clearPersistedValue deletes key', () async {
    final MemoryVirexStore store = MemoryVirexStore();

    final PersistedSignal<int> persisted = await PersistedSignal.create<int>(
      key: 'session',
      initial: 5,
      store: store,
      toStorage: (int value) => value.toString(),
      fromStorage: int.parse,
    );

    await persisted.clearPersistedValue();
    expect(store.peek('session'), isNull);
    persisted.dispose();
  });
}
