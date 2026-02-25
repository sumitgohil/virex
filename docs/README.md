# Virex Docs Index

This folder is split into two tracks:

- **User-facing docs**: how to adopt and run Virex safely.
- **Maintainer docs**: project governance, release operations, and ecosystem policy.

## User-Facing

- [`adoption/WHY_VIREX.md`](adoption/WHY_VIREX.md)
- [`adoption/MIGRATION_KITS.md`](adoption/MIGRATION_KITS.md)
- [`adoption/PERF_CHECKLIST.md`](adoption/PERF_CHECKLIST.md)
- [`adoption/ROLLBACK_STRATEGY.md`](adoption/ROLLBACK_STRATEGY.md)

## Maintainer / Project Ops

- [`governance/RFC_PROCESS.md`](governance/RFC_PROCESS.md)
- [`governance/RELEASE_CALENDAR.md`](governance/RELEASE_CALENDAR.md)
- [`governance/OWNERSHIP_AND_ONCALL.md`](governance/OWNERSHIP_AND_ONCALL.md)
- [`governance/LTS_POLICY.md`](governance/LTS_POLICY.md)
- [`ecosystem/CERTIFICATION_PROGRAM.md`](ecosystem/CERTIFICATION_PROGRAM.md)
- [`metrics/DASHBOARD.md`](metrics/DASHBOARD.md)
- [`metrics/metrics.schema.json`](metrics/metrics.schema.json)

## Staleness Policy

When behavior changes in runtime, scheduler, or package APIs:

1. Update affected docs in this folder in the same PR.
2. Prefer concrete commands and file paths over vague guidance.
3. Avoid date-specific promises unless enforced by automation.
