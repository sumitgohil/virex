## Unreleased

## 2.0.0

- V2 runtime hardening:
  - Added `VirexRuntimeConfig` and `VirexWriteViolationPolicy`.
  - Default policy is now `hardFail` for writes during computed execution.
  - Added deferred-write queue (`deferNextEpoch`) and warning-drop mode.
  - Added scheduler metrics API (`metricsSnapshot`) with p95 window data.
  - Added bounded trace ring buffer plumbing and inspector trace APIs.
  - Added structured invariant diagnostics and invariant failure events.
  - Added effect loop cooloff behavior across repeated breaches.
- Added deterministic replay and write-policy matrix tests.
- Added tagged extreme scale tests (`500k`/`50k`) and nightly scale workflow.
- CI now excludes scale-tag tests in fast tier; release includes scale tier.
- Added milestone adoption packages:
  - `virex_riverpod_bridge`
  - `virex_bloc_bridge`
- Added production reference app scaffold:
  - `examples/production_reference_app`
- Added tooling packages:
  - `virex_observability`
  - `virex_testkit`
- Added ecosystem packages:
  - `virex_router_bridge`
  - `virex_forms`
- Expanded `virex_persist` with policy and production adapter abstractions.
- Added inspector events API with sampling and timeline controls.
- Added CI performance budget enforcement and package-matrix validation.
- Added adoption/governance/ecosystem/metrics documentation tracks.

## 1.0.0

- Finalized deterministic Virex runtime for production use.
- Shipped core primitives: `Signal`, `Computed`, `Effect`, and `AsyncSignal`.
- Added strict execution phases and computed-write guard semantics.
- Added epoch-based scheduling (`flushEpoch`, per-node enqueue/compute epochs).
- Added topological flush behavior: computeds settle before effects.
- Added effect loop guard with configurable threshold.
- Added centralized ID-based graph registry and hard detach on dispose.
- Added debug invariant checker and snapshot inspector APIs.
- Added VM service extensions for inspector snapshots and invariant checks.
- Added Flutter binding via `SignalBuilder` with frame-aligned rebuild scheduling.
- Added benchmark suite and baseline comparison tooling.
- Added battle-test example app with 8 stress modules and rebuild overlay.
- Added CI/release workflows, coverage gate tooling, and OSS templates.

## 0.1.0

- Introduced Virex reactive core primitives: `Signal`, `Computed`, `Effect`, `AsyncSignal`.
- Added deterministic scheduler with phase model and flush epoch versioning.
- Added two-queue flush model (computed before effects) and loop guard logic.
- Added centralized ID-based dependency graph and disposal hard-detach semantics.
- Added debug inspector snapshots, invariant checks, and logger plumbing.
- Added Flutter `SignalBuilder` binding with frame-aligned rebuild scheduling.
- Added comprehensive core/widget/stress tests.
- Added benchmark suite scaffold and battle-test example app modules.
- Added README, architecture, and migration documentation.
