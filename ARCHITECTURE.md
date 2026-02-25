# Virex Architecture

## Layers

1. Pure Dart core (`lib/src/core`)
2. Flutter binding (`lib/src/flutter`)
3. Debug tools (`lib/src/debug`)

## Core Graph Model

Virex uses a centralized registry:
- `Map<int, NodeRecord>`
- Dependencies and subscribers stored as `Set<int>` node IDs
- Monotonic node IDs for deterministic ordering and inspection

No reactive node stores direct strong references to peer nodes.

## Scheduler

The scheduler uses two queues per flush cycle:
- Computed queue
- Effect queue
- Deferred-write queue (policy-driven)

Cycle order:
1. Increment epoch
2. Drain computed queue to fixed point
3. Drain effect queue
4. If effects mutate state, schedule next epoch
5. Persist metrics window and flush listeners

## Epoch Versioning

- Scheduler tracks `_flushEpoch`
- Each node tracks:
  - `lastEnqueuedEpoch`
  - `lastComputedEpoch`
  - `runCountInEpoch`

This guarantees same-cycle dedupe and easier deterministic diagnostics.

## Execution Phases

- `IDLE`
- `TRACKING`
- `FLUSHING`
- `COMPUTING`
- `EFFECT_RUNNING`

Signal writes during `COMPUTING` are blocked.
V2 default policy is `hardFail`; optional policies are `deferNextEpoch` and `dropAndLog`.

## Error Contract

- Computed errors: cached and rethrown on read until dependency invalidation
- Effect errors: reported, effect remains subscribed
- AsyncSignal errors: captured in state (`AsyncState.error`) without graph crash

## Debug Invariants

In debug mode, Virex verifies after each flush:
- No unresolved dirty computed nodes
- No edges referencing missing node IDs
- Dependency/subscriber reciprocity is intact
- Queue and registry consistency

Invariant checks return structured issues (`invariantName`, `offenderNodeIds`, `message`) and inspector emits failure events.

## Flutter Binding

`SignalBuilder` creates an observer node, tracks signal reads in `builder`, and schedules frame-aligned rebuilds.

## DevTools Hook

`VirexInspector.registerDevToolsExtension(...)` provides a V1 extension point for external observability bridges.

## VM Service Extensions

Virex also exposes runtime inspection endpoints through `dart:developer` service extensions:
- `ext.virex.snapshot`: returns the current graph snapshot JSON
- `ext.virex.auto_snapshots`: enables or disables automatic snapshots on flush
- `ext.virex.invariants`: returns invariant health (`ok: true/false`)

## Trace and Metrics

- Scheduler exposes `metricsSnapshot()` with epoch/pending/deferred/p95 windows.
- Inspector exposes bounded trace ring buffer via:
  - `configureTrace(...)`
  - `getTraceSnapshot()`
  - `clearTrace()`
