import 'package:test/test.dart';
import 'package:virex_persist/virex_persist.dart';

final class _FakePrefs implements SharedPreferencesLike {
  final Map<String, String> data = <String, String>{};

  @override
  String? getString(String key) => data[key];

  @override
  Future<bool> remove(String key) async {
    data.remove(key);
    return true;
  }

  @override
  Future<bool> setString(String key, String value) async {
    data[key] = value;
    return true;
  }
}

final class _FakeBox implements KeyValueBoxLike {
  final Map<String, dynamic> data = <String, dynamic>{};

  @override
  Future<void> delete(String key) async {
    data.remove(key);
  }

  @override
  dynamic get(String key) => data[key];

  @override
  Future<void> put(String key, dynamic value) async {
    data[key] = value;
  }
}

final class _FakeEncrypted implements EncryptedStoreLike {
  final Map<String, String> data = <String, String>{};

  @override
  Future<void> deleteEncrypted(String key) async {
    data.remove(key);
  }

  @override
  Future<String?> readEncrypted(String key) async => data[key];

  @override
  Future<void> writeEncrypted(String key, String value) async {
    data[key] = value;
  }
}

void main() {
  test('shared preferences store adapter works', () async {
    final _FakePrefs prefs = _FakePrefs();
    final SharedPreferencesVirexStore store = SharedPreferencesVirexStore(
      prefs,
    );

    await store.write('k', 'v');
    expect(await store.read('k'), 'v');

    await store.delete('k');
    expect(await store.read('k'), isNull);
  });

  test('hive store adapter works', () async {
    final _FakeBox box = _FakeBox();
    final HiveVirexStore store = HiveVirexStore(box);

    await store.write('a', '1');
    expect(await store.read('a'), '1');
  });

  test('encrypted store adapter works', () async {
    final _FakeEncrypted encrypted = _FakeEncrypted();
    final EncryptedVirexStore store = EncryptedVirexStore(encrypted);

    await store.write('t', 'secret');
    expect(await store.read('t'), 'secret');
  });
}
