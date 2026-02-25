# Rollback Strategy

## Principle
Every migration PR must be reversible in one commit.

## Rules
- Keep old state implementation behind a feature flag for the first rollout window.
- Avoid mixing migration and behavior changes in the same PR.
- Keep adapter boundaries explicit (`bridge` packages).
- Capture runtime config used in rollout (`VirexRuntimeConfig`) so rollback is deterministic.

## Rollback playbook
1. Disable Virex feature flag.
2. Re-enable previous provider/bloc path.
3. Restore prior runtime behavior/config if it was modified.
4. Redeploy hotfix.
5. Triage root cause with `VirexMigrationReport` notes and inspector traces.
