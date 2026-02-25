/// Compatibility status for a Virex ecosystem integration package.
final class PluginCompatibilityReport {
  const PluginCompatibilityReport({
    required this.plugin,
    required this.version,
    required this.virexVersion,
    required this.platforms,
    required this.certified,
    this.notes,
  });

  final String plugin;
  final String version;
  final String virexVersion;
  final List<String> platforms;
  final bool certified;
  final String? notes;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'plugin': plugin,
      'version': version,
      'virexVersion': virexVersion,
      'platforms': platforms,
      'certified': certified,
      'notes': notes,
    };
  }
}
