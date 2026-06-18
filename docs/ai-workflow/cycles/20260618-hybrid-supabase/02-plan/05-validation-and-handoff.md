# Task 06: Validate Hybrid Runtime And Prepare Stage 4 Handoff

## Outcome

Produce evidence that Supabase authority, Drift cache behavior, mobile workflows, cleanup, and Android build are correct enough for Stage 4/5 review.

## Why This Task Exists

This migration can look green while still allowing corrupting writes, stale cache assumptions, or hidden backup/local paths. The handoff must make those risks reviewable.

## Dependencies

- Tasks 02-05 complete or explicitly blocked with evidence.

## Repository Evidence

Review changed files since Stage 2 planning commit and all task logs. Inspect current test commands, Android build commands, and docs touched by cleanup.

## Read Before Editing

1. `00-plan-index.md`
2. `implementation_guide.md`
3. All task packets
4. `03-implementation-log.md`
5. `../STATE.md`

## Scope

### Change

- Update Stage 3 implementation log with final evidence.
- Prepare return/validation artifacts only according to workflow stage ownership.
- Fix validation failures within the approved design scope.

### Preserve

- No merge to `main`.
- No weakening tests to pass.
- No hidden credential commits.

### Explicitly out of scope

- New product features.
- Realtime/offline queue.
- Stage 5 merge decision.

## Contracts And Invariants

- Any failed required evidence is reported as failed or blocked, not passed.
- Mock-only evidence cannot prove Supabase authority.
- Stage 3 does not merge.
- Stage 4/5 can reconstruct intent from artifacts and diffs.

## Implementation Guidance

Record:

- implementation branch and baseline/final SHA
- `main_backup` remote SHA
- Supabase migration command and result
- catalog seed command and counts
- SQL/RPC test result
- Flutter test/analyze result
- Android build result
- manual or scripted runtime scenario evidence
- known blocked evidence and why
- deviations from Stage 2 plan

Required scenarios:

1. Fresh Supabase seed from master catalog.
2. First app login and initial sync.
3. Cached read with Supabase temporarily unavailable.
4. Offline invoice draft preparation.
5. Offline invoice confirm blocked.
6. Invoice preview does not write.
7. Confirm invoice creates official Supabase invoice number.
8. Second device/manual sync sees invoice.
9. Cancel invoice reverses status, stock, and ledger.
10. Product/customer/buyer archive preserves historical invoice rendering.
11. Drift cache deletion/rebuild succeeds from Supabase.
12. Backup menu is absent.

## Test-First Specification

Before claiming done, run or explicitly block:

- SQL/RPC tests against local or real Supabase/Postgres.
- Catalog generator parity tests.
- Focused hybrid service tests.
- Full Flutter tests.
- Flutter analyze.
- Android release build with dart defines.
- Static searches for forbidden paths.

## Validation Ladder

```bash
python3 tools/build_preinstalled_catalog.py
<supabase migration command>
<supabase SQL/RPC test command>
(cd mobile && flutter test test)
(cd mobile && flutter analyze)
(cd mobile && flutter build apk --release --dart-define=SUPABASE_URL=<url> --dart-define=SUPABASE_ANON_KEY=<anon>)
rg -n "DATA_MODE|max\\(invoice|invoice_number\\s*\\+\\s*1|service_role|Google Drive|Backup" .
git diff --stat <stage2-planning-sha>...HEAD
git status --short
```

Expected evidence: all blocking commands pass or are honestly marked blocked with exact reason and residual risk.

## Review Checklist

- Stage 2 AC1-AC18 are mapped to evidence.
- Any retained backend/local code is non-runtime or justified.
- No credentials or service role keys are present.
- `MASTER CATALOG.xlsx` is tracked or intentionally moved to tracked canonical path.
- `main_backup` remains available.
- Stage 4 reviewer has exact commands and outputs.

## Allowed Adaptation

If a validation environment is unavailable, create the narrowest fake/local evidence possible and mark the real environment proof blocked.

## Stop And Escalate If

- Any official write can happen locally without Supabase.
- SQL/RPC tests cannot prove atomic invoice create/cancel.
- Backup/local/API runtime remains reachable.
- Android build fails for nontrivial reasons.
- Tests are removed without equivalent hybrid coverage.
- Supabase service role or private credential is committed.

## Commit Checkpoint

Commit validation fixes and final docs on the feature branch. Suggested message: `test(hybrid): validate supabase runtime`.

## Done When

Stage 3 has a complete implementation log, validation evidence, clean feature worktree, and unmerged branch ready for Stage 4/5 review.

## Handoff Update

Add to `03-implementation-log.md`: final task summary, command outputs, blocked items, final SHA, and reviewer notes.

Update `STATE.md`: Stage 3 status complete or blocked, validation summary, final feature SHA, and next owner `Stage 4 reviewer` or persistent Stage 5 lane per workflow.
