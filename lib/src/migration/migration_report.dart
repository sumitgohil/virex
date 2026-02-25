/// Summary of a migration effort from another state-management approach.
final class VirexMigrationReport {
  const VirexMigrationReport({
    required this.sourceFramework,
    required this.feature,
    required this.estimatedDevDays,
    required this.riskFlags,
    required this.rollbackSteps,
    this.notes,
  });

  final String sourceFramework;
  final String feature;
  final double estimatedDevDays;
  final List<String> riskFlags;
  final List<String> rollbackSteps;
  final String? notes;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'sourceFramework': sourceFramework,
      'feature': feature,
      'estimatedDevDays': estimatedDevDays,
      'riskFlags': riskFlags,
      'rollbackSteps': rollbackSteps,
      'notes': notes,
    };
  }
}
