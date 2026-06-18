# Workflow State

Cycle ID: `20260618-hybrid-supabase`

Parent cycle: `20260614-invoice-collections-backup-analytics`

Objective: Convert Khata from selectable API/local runtimes into one hybrid runtime where Supabase Postgres is the source of truth, Drift is an append/upsert cache, all official writes go through Supabase RPC, and backup/local-only runtime surfaces are removed after parity is proven.

Workflow schema: five-stage-v1

Current stage: `2-design-and-planning`

Stage status: `complete`

Persistent LLM lane: `paused-after-stage-2`

Current owner: `Stage 2 persistent LLM`

Next owner: `Stage 3 fresh SLM`

Current task: Stage 2 artifact audit and handoff

Stage 2 planning baseline SHA: `f873c3853c263bcbd91dbaab8b72b4f1ed2e8eb1`

## Stage 2 Boundary Audit

- Stage 2 was requested after a chat-only plan. A premature Stage 3 attempt occurred in this same conversation.
- External side effect retained with user approval: local and remote branch `main_backup` created at `f873c3853c263bcbd91dbaab8b72b4f1ed2e8eb1`.
- Implementation files touched by the premature attempt were restored/removed before this planning packet:
  - `tools/build_preinstalled_catalog.py`
  - `mobile/assets/catalog/preinstalled_catalog.json`
  - `supabase/`
- Current non-planning working-tree item intentionally preserved and not staged by Stage 2: untracked `MASTER CATALOG.xlsx`.
- No source, test, migration, dependency, generated, runtime-data, or config file is part of this Stage 2 planning artifact set.
- Audit result before planning commit: pass.
- Pre-existing changed paths: `MASTER CATALOG.xlsx` only, untracked and preserved.
- Stage 2-created/modified paths: this cycle's `STATE.md`, `02-design.md`, `02-plan/**/*.md`, `02-llm-review-anchor.md`, plus `docs/ai-workflow/INDEX.md` and `docs/ai-workflow/PROJECT_CONTEXT.md`.
- Allowlist violations: none.
- Stage 3-5 artifacts created by Stage 2: none.
- Feature branch/worktree created by Stage 2: no.
- Production implementation started by Stage 2 after recovery: no.
- Planning commit: reported in the final Stage 2 response.

## Git And Worktree Contract

Integration target branch: `main`

Planning checkout absolute path: `/Users/abhishek/python_venv/khata_app`

Stage 2 planning HEAD before artifact commit: `f873c3853c263bcbd91dbaab8b72b4f1ed2e8eb1`

Safety backup branch: `main_backup`

Safety backup branch status: created and pushed to `origin/main_backup` at `f873c3853c263bcbd91dbaab8b72b4f1ed2e8eb1`

Proposed feature branch: `codex/hybrid-supabase`

Proposed worktree name/ID: `hybrid-supabase`

Proposed canonical worktree absolute path: `/Users/abhishek/python_venv/khata_app/.worktrees/hybrid-supabase`

Stage 3 creation command/policy:

```bash
git fetch origin
git switch main
git status --short
git rev-parse HEAD
git worktree add .worktrees/hybrid-supabase -b codex/hybrid-supabase main
```

Implementation baseline: clean Stage 2 planning commit HEAD, to be resolved and recorded by Stage 3

Feature worktree status: not-created

Merge owner: Stage 5 persistent LLM

Merge authorization: required

Merge status: not-started

## Locked Decisions

- Supabase Postgres is the only authority for official business data after cutover.
- Drift remains as local cache only; normal sync must never whole-database-replace Drift.
- V1 sync runs after login/app start, app resume, manual refresh, and each successful write. Realtime subscriptions are deferred.
- V1 offline mode is read/cache plus invoice drafts only; official writes fail while Supabase is unreachable.
- Supabase email/password auth is the v1 auth model.
- `MASTER CATALOG.xlsx` is the canonical catalog source for Stage 3. Stage 3 must commit or move it into a tracked canonical source path.
- Supabase and Drift seed data must be generated from the same catalog output and must share stable UUIDs.
- All official writes go through Supabase RPC. Direct table writes from Flutter are not part of v1.
- Invoice preview must not write. Confirm invoice calls Supabase `create_invoice`.
- Invoice numbers are assigned only by Supabase/Postgres.
- Existing phone-local data is not silently imported. First hybrid launch clears/rebuilds local business cache from Supabase.
- Google Drive backup/local backup UI is removed only after hybrid parity tests pass.
- API/local implementation code may stay temporarily as a reference oracle during Stage 3, but must not remain reachable in the final runtime.

## Execution Order

1. Stage 3 setup and safety audit.
2. Supabase schema, RLS, RPC, and SQL tests.
3. Catalog canonicalization and deterministic seed generation.
4. Mobile Supabase config/auth and hybrid dependency wiring.
5. Drift cache metadata and sync service.
6. Hybrid service implementations behind existing interfaces.
7. Invoice preview/confirm/cancel hardening.
8. Backup/runtime cleanup after parity gates.
9. Full validation, artifact update, and Stage 4 handoff packet.

## High-Risk Gates

- Do not clear or modify real local business data before proving Supabase seed and first-sync behavior on disposable data.
- Do not let Flutter calculate official invoice numbers.
- Do not allow direct client inserts/updates for invoice, ledger, stock, or catalog writes.
- Do not remove local/API reference implementations before hybrid parity tests pass.
- Do not claim production readiness without testing against a real Supabase project or local Supabase stack.
- Do not commit Supabase service role keys, anon key secrets beyond expected public anon key configuration, passwords, device tokens, or generated private config.

## Acceptance Criteria

See `02-design.md` for AC1-AC18 and proof methods.

## Minimum Read Set For Stage 3

1. This file.
2. `02-design.md`.
3. `02-plan/00-plan-index.md`.
4. `02-plan/implementation_guide.md`.
5. Assigned task packet under `02-plan/`.
6. `02-llm-review-anchor.md`.
7. `docs/ai-workflow/PROJECT_CONTEXT.md`.

## Exact Next Action

Stop this Stage 2 conversation after the planning commit. Open a fresh Stage 3 implementation context with the separate Stage 3 prompt, create the feature worktree from the clean Stage 2 planning commit, and implement Task 01 from `02-plan/01-stage-3-setup.md`. Do not merge; Stage 5 owns integration.
