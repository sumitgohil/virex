import 'scheduler.dart';

/// Defines how Virex handles writes attempted during computed execution.
enum VirexWriteViolationPolicy {
  /// Throw immediately and fail fast.
  hardFail,

  /// Defer the write deterministically to the next flush epoch.
  deferNextEpoch,

  /// Drop the write and emit a runtime warning.
  dropAndLog,
}

/// Global runtime configuration for scheduler and safety policies.
final class VirexRuntimeConfig {
  const VirexRuntimeConfig({
    this.writeViolationPolicy = VirexWriteViolationPolicy.hardFail,
    this.effectLoopThreshold = 100,
    this.maxNodesPerFlushSlice = 0,
    this.enableInvariantAuditInDebug = true,
  });

  final VirexWriteViolationPolicy writeViolationPolicy;
  final int effectLoopThreshold;
  final int maxNodesPerFlushSlice;
  final bool enableInvariantAuditInDebug;
}

const VirexRuntimeConfig _defaultRuntimeConfig = VirexRuntimeConfig();
VirexRuntimeConfig _runtimeConfig = _defaultRuntimeConfig;

/// Applies runtime configuration globally.
void configureVirexRuntime(VirexRuntimeConfig config) {
  _runtimeConfig = config;
  VirexScheduler.instance.applyRuntimeConfig(
    effectLoopThreshold: config.effectLoopThreshold,
    maxNodesPerFlushSlice: config.maxNodesPerFlushSlice,
    enableInvariantAuditInDebug: config.enableInvariantAuditInDebug,
  );
}

/// Returns current global runtime configuration.
VirexRuntimeConfig getVirexRuntimeConfig() => _runtimeConfig;

/// Resets runtime config to defaults for tests.
void debugResetVirexRuntimeConfig() {
  configureVirexRuntime(_defaultRuntimeConfig);
}
