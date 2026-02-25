import 'store.dart';

/// Minimal adapter interface compatible with shared_preferences-like APIs.
abstract interface class SharedPreferencesLike {
  String? getString(String key);

  Future<bool> setString(String key, String value);

  Future<bool> remove(String key);
}

/// Shared preferences store adapter.
final class SharedPreferencesVirexStore implements VirexStore {
  SharedPreferencesVirexStore(this._prefs);

  final SharedPreferencesLike _prefs;

  @override
  Future<String?> read(String key) async => _prefs.getString(key);

  @override
  Future<void> write(String key, String value) async {
    await _prefs.setString(key, value);
  }

  @override
  Future<void> delete(String key) async {
    await _prefs.remove(key);
  }
}

/// Minimal key/value box interface for Hive/Isar-like wrappers.
abstract interface class KeyValueBoxLike {
  dynamic get(String key);

  Future<void> put(String key, dynamic value);

  Future<void> delete(String key);
}

/// Generic key/value box adapter for Hive/Isar style stores.
final class HiveVirexStore implements VirexStore {
  HiveVirexStore(this._box);

  final KeyValueBoxLike _box;

  @override
  Future<String?> read(String key) async {
    final dynamic value = _box.get(key);
    if (value == null) {
      return null;
    }
    return '$value';
  }

  @override
  Future<void> write(String key, String value) async {
    await _box.put(key, value);
  }

  @override
  Future<void> delete(String key) async {
    await _box.delete(key);
  }
}

/// Minimal encrypted key/value storage interface.
abstract interface class EncryptedStoreLike {
  Future<String?> readEncrypted(String key);

  Future<void> writeEncrypted(String key, String value);

  Future<void> deleteEncrypted(String key);
}

/// Encrypted storage adapter.
final class EncryptedVirexStore implements VirexStore {
  EncryptedVirexStore(this._store);

  final EncryptedStoreLike _store;

  @override
  Future<String?> read(String key) => _store.readEncrypted(key);

  @override
  Future<void> write(String key, String value) {
    return _store.writeEncrypted(key, value);
  }

  @override
  Future<void> delete(String key) {
    return _store.deleteEncrypted(key);
  }
}
