import 'package:test/test.dart';
import 'package:virex_persist/virex_persist.dart';

void main() {
  test('policy serializes expected fields', () {
    const PersistedSignalPolicy policy = PersistedSignalPolicy(
      flushPolicy: PersistFlushPolicy.manual,
      conflictResolution: PersistConflictResolution.preferStorage,
      migrationVersion: 2,
    );

    final Map<String, Object?> json = policy.toJson();
    expect(json['flushPolicy'], 'manual');
    expect(json['conflictResolution'], 'preferStorage');
    expect(json['migrationVersion'], 2);
  });
}
