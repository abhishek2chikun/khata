# Task 05: Remove Reachable Old Runtime And Backup Surfaces After Hybrid Parity

## Outcome

After hybrid parity is proven, remove or make unreachable the old API/local runtime choices and user-facing Google Drive/local backup flows so the product has one clear runtime model.

## Why This Task Exists

Keeping local-only or backup restore surfaces after Supabase becomes master can corrupt user expectations and reintroduce split-brain state.

## Dependencies

- Task 04 proves hybrid auth/sync/service parity.
- Task 02 SQL/RPC tests pass.
- Task 03 catalog parity passes.
- `origin/main_backup` exists.

## Repository Evidence

Read current analogs before editing:

- runtime mode wiring (`DATA_MODE`, `AppDependencies`, config files)
- `mobile/lib/api/`
- `mobile/lib/local/`
- `mobile/lib/backup/`
- Android WorkManager backup hooks
- backup routes/menu items/screens
- README and `mobile/agent.md`

## Read Before Editing

1. `03-mobile-hybrid-services-sync.md`
2. Latest Task 04 tests and implementation log
3. `../02-design.md` cleanup design
4. `implementation_guide.md` stop conditions

## Scope

### Change

- Remove reachable API mode selection.
- Remove reachable local-only auth/setup/runtime mode.
- Remove Google Drive backup UI/routes/runtime.
- Remove local backup import/restore user flow.
- Remove WorkManager backup scheduling hooks.
- Remove obsolete tests only when equivalent hybrid tests exist.
- Update docs to describe hybrid setup.

### Preserve

- Drift cache, local PDF/share, analytics, and tests needed for hybrid behavior.
- Backend/API code temporarily only if it is clearly non-runtime reference and deletion would risk losing unported fixtures.
- `main_backup`.

### Explicitly out of scope

- Removing reference code before parity.
- Deleting tests without equivalent hybrid coverage.
- Repairing Drive backup.

## Contracts And Invariants

- Final app has no reachable `DATA_MODE=api/local` selection.
- User cannot start backup/restore as a business-state sharing mechanism.
- Supabase is clearly the master; local cache is not marketed as backup.
- Historical invoices remain renderable after product/customer/buyer archive.
- Cleanup cannot remove code still needed for PDF/share/analytics/cache.

## Implementation Guidance

Candidate removal/unreachability targets:

- mode toggles and environment branches
- API service runtime wiring
- local-only auth/setup screens
- backup drawer/menu entries
- Drive sign-in/settings screens
- backup scheduler registration
- backup restore/import commands
- old docs that instruct backup sharing

If full backend deletion is too risky, mark it archived/reference and remove all mobile runtime dependency on it. Prefer compile-time removal of runtime choices over hiding buttons only.

Docs to update:

- README hybrid setup, Supabase config, migration/seed commands, Android build.
- `mobile/agent.md` stale local-mode/backup statements.
- Any backup docs should be removed or marked historical.

## Test-First Specification

Add/update tests that fail before cleanup:

- App shell has no backup menu destination.
- Backup routes/screens are unreachable.
- Missing Supabase config shows setup error, not local fallback.
- No test or runtime setup passes `DATA_MODE=local/api` as a selectable app mode.
- Old backup WorkManager hooks are not registered.
- Flutter tests still cover PDF/share/collections/analytics through hybrid services.

## Validation Ladder

```bash
(cd mobile && flutter test test)
(cd mobile && flutter analyze)
rg -n "DATA_MODE|Drive backup|Google Drive|restore backup|WorkManager|Api.*Service|Local.*Auth|local-only" mobile/lib mobile/test README.md docs mobile/agent.md
```

Expected evidence:

- Search hits are either gone or explicitly historical/test-oracle references.
- Backup UI is absent.
- Hybrid runtime still passes tests.

## Review Checklist

- Cleanup happened after parity evidence, not before.
- User-facing backup and local-only runtime are unreachable.
- Reference code, if retained, cannot be invoked by the app.
- Docs do not tell family users to backup/sync through local files or Google Drive.

## Allowed Adaptation

If deleting a directory breaks useful fixtures, keep it under a clearly named archived/reference path or leave it with no runtime imports and document the reason.

## Stop And Escalate If

- Old API/local runtime must stay reachable to preserve an approved workflow.
- Backup removal would delete PDF/share/cache functionality.
- Equivalent hybrid coverage is missing for tests being removed.

## Commit Checkpoint

Commit after cleanup tests pass. Suggested message: `refactor(hybrid): remove old runtime and backup surfaces`.

## Done When

The final runtime is hybrid-only from a user's perspective, backup/local/API paths cannot be launched, and tests prove preserved behavior still works.

## Handoff Update

Add to `03-implementation-log.md`: removed/unreachable paths, search results, preserved reference code rationale, test evidence, and next task.

Update `STATE.md`: Task 05 status, cleanup evidence, and current task `Task 06`.
