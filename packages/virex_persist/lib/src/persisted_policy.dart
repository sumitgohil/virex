/// Conflict resolution strategy for persisted signal hydration/write races.
enum PersistConflictResolution { preferMemory, preferStorage, merge }

/// Persisted signal write scheduling mode.
enum PersistFlushPolicy { immediate, debounced, manual }

/// Policy configuration for persisted signal lifecycle and migrations.
final class PersistedSignalPolicy {
  const PersistedSignalPolicy({
    this.flushPolicy = PersistFlushPolicy.debounced,
    this.conflictResolution = PersistConflictResolution.preferMemory,
    this.migrationVersion = 1,
  });

  final PersistFlushPolicy flushPolicy;
  final PersistConflictResolution conflictResolution;
  final int migrationVersion;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'flushPolicy': flushPolicy.name,
      'conflictResolution': conflictResolution.name,
      'migrationVersion': migrationVersion,
    };
  }
}
