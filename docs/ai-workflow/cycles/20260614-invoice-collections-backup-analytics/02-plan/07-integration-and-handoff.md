# Task 07: Integrate, Validate, And Produce The Return Packet

## Outcome

Integrate Tasks 01-06, run every available automated and runtime gate, capture artifacts, classify blockers honestly, and prepare Stage 4/5 handoff without merging.

## Why This Task Exists

This cycle crosses financial contracts, migrations, local recovery, background execution, and high-density UI. Focused task tests are insufficient evidence for release readiness.

## Dependencies

All previous tasks completed at their commit checkpoints.

## Repository Evidence

- Canonical commands in `docs/ai-workflow/PROJECT_CONTEXT.md`, `backend/agent.md`, and `mobile/agent.md`.
- Prior baseline audit distinguishes phone-testing readiness from distribution readiness.
- Current release blockers outside scope: example app ID, debug signing, physical-device evidence until performed.

## Read Before Editing

- `STATE.md`, design acceptance/scenario tables, plan index coverage matrix, all task handoff updates, and actual baseline-to-head diff.

## Scope

### Change

- Resolve only integration issues caused by approved task interactions.
- Regenerate Drift/catalog artifacts once from final sources.
- Add/update `04-validation-report.md` and `04-return-packet.md` with command outputs, artifacts, hashes, deviations, and review map.
- Update `03-implementation-log.md`, `02-llm-review-anchor.md`, and `STATE.md` to final Stage 3 handoff status.
- Correct stale agent/README facts touched by this cycle: schema/catalog versions, quantity/price/HSN rules, PDF behavior, Drive setup, analytics behavior, and test commands.

### Preserve

- No merge to `main`.
- No unrelated refactors, dependency upgrades, app ID/signing changes, or suppression of pre-existing warnings.

### Explicitly Out Of Scope

- Fixing unrelated baseline defects unless they block an AC; classify and return them.

## Contracts And Invariants

- Every AC needs independent evidence or an explicit blocker.
- Automated tests cannot substitute for physical Drive/OAuth/background evidence.
- Emulator/device smoke cannot substitute for production signing/distribution readiness.
- Generated files must match source generators.

## Implementation Guidance

- Review `git diff 837ccbc...HEAD` before running broad gates; look specifically for financial writes, migration copy lists, secrets, generated churn, and API/local divergence.
- Start PostgreSQL test infrastructure if the repository provides it; use only the dedicated `_test` database guard.
- Render PDFs to a temp/artifact directory outside tracked source unless the workflow intentionally records sample artifacts.
- For canonical restore digest, sort table names/rows/keys and omit intentionally volatile fields only if the omission is documented and justified.
- Capture command, environment, exit code, counts, artifact path, and what each result proves.

## Test-First Specification

Before broad validation, add any missing cross-slice regression tests:

- schema-10 backup containing HSN/three-decimal invoice data restores and drives PDF/analytics correctly;
- batch collection changes receivables KPI immediately;
- Cash/Credit invoice creation affects collection balances/KPIs correctly;
- catalog-upgraded product with missing HSN is blocked only in GST mode;
- scheduled backup after schema migration uploads a restorable v10 package.

## Validation Ladder

```bash
git status --short
git diff --check
python3 tools/build_preinstalled_catalog.py
git diff --exit-code -- mobile/assets/catalog/preinstalled_catalog.json
.venv/bin/python -m pytest backend/pure_tests -q
pg_isready -h localhost -p 55432
(cd backend && BILLING_DATABASE_URL='postgresql+psycopg://khata:khata@localhost:55432/internal_billing_test' ../.venv/bin/python -m alembic upgrade head)
BILLING_DATABASE_URL='postgresql+psycopg://khata:khata@localhost:55432/internal_billing_test' PYTHONPATH=backend .venv/bin/python -m pytest backend/tests -q
(cd mobile && dart run build_runner build --delete-conflicting-outputs)
(cd mobile && flutter test test)
(cd mobile && flutter analyze)
(cd mobile && flutter build apk --release --dart-define=DATA_MODE=local)
shasum -a 256 mobile/build/app/outputs/flutter-apk/app-release.apk
```

Also perform:

1. Alembic upgrade/downgrade/upgrade with pre/post row-value comparison.
2. Drift v9 fixture migration and backup v9/v10 restore.
3. Four PDF render review plus historical discounted/canceled fixture.
4. Emulator/phone invoice search, GST/non-GST, Cash/Credit, and seven-day batch collection matrix.
5. Configured physical Android Drive matrix from Task 05.
6. Restart persistence after successful restore.

## Review Checklist

- [ ] AC1-AC14 mapped to evidence/blocker.
- [ ] No secrets or user data in diff/artifacts/logs.
- [ ] API/local parity checked at calculation and wire levels.
- [ ] Migrations preserve history.
- [ ] Physical-device gaps are explicit.
- [ ] Main/default checkout untouched and branch unmerged.

## Allowed Adaptation

Commands may use the repo’s current Docker/test setup if ports or service names differ; record exact commands. Do not skip a gate silently.

## Stop And Escalate If

- Any financial/migration/restore test fails nondeterministically.
- Generated output changes after a second generation run.
- Physical Drive proof is blocked by external configuration: mark AC10/AC11 blocked, do not claim completion.
- The baseline-to-head diff contains unrelated user changes or secrets.

## Commit Checkpoint

`docs(workflow): hand off khata upgrade validation`

Do not merge or push unless separately authorized.

## Done When

The implementation is either fully evidenced or honestly classified as partial/blocked, all workflow artifacts are current, and Stage 4 receives a copy-ready read/command sequence.

## Handoff Update

Set `STATE.md` owner to Stage 4 fresh verifier, persistent lane to paused-after-stage-3, merge owner/status to Stage 5/not-started, and include exact first validation command and unresolved blockers.
