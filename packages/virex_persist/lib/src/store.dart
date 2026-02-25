/// Storage abstraction used by persistence helpers.
abstract interface class VirexStore {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);
}

/// In-memory store useful for tests and local demos.
final class MemoryVirexStore implements VirexStore {
  final Map<String, String> _values = <String, String>{};

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async {
    _values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _values.remove(key);
  }

  String? peek(String key) => _values[key];
}
