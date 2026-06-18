# Workflow State

Cycle ID: `20260618-hybrid-supabase`

Parent cycle: `20260614-invoice-collections-backup-analytics`

Objective: Convert Khata from selectable API/local runtimes into one hybrid runtime where Supabase Postgres is the source of truth, Drift is an append/upsert cache, all official writes go through Supabase RPC, and backup/local-only runtime surfaces are removed after parity is proven.

Workflow schema: five-stage-v1

Current stage: `3-implementation`

Stage status: `in-progress`

Persistent LLM lane: `paused-after-stage-2`

Current owner: `Stage 3 fresh SLM`

Next owner: `Stage 4 fresh SLM`

Current task: Task 02 — Supabase schema, RLS, RPC, SQL tests

Stage 2 planning baseline SHA: `f873c3853c263bcbd91dbaab8b72b4f1ed2e8eb1`

Stage 3 implementation baseline SHA: `1fe37eee8fa8bc689f1c40fa630853fa8f3daf5a`

## Stage 2 Boundary Audit

- Stage 2 planning commit: `c7fff58`
- User backup commit atop planning: `1fe37ee backup before hybrid`
- Implementation baseline for Stage 3: `1fe37ee`

## Git And Worktree Contract

Integration target branch: `main`

Planning checkout absolute path: `/Users/abhishek/python_venv/khata_app`

Feature branch: `codex/hybrid-supabase`

Worktree name/ID: `hybrid-supabase`

Canonical worktree absolute path: `/Users/abhishek/python_venv/khata_app/.worktrees/hybrid-supabase`

Feature worktree status: created

Safety backup branch: `main_backup` at `f873c3853c263bcbd91dbaab8b72b4f1ed2e8eb1` (verified remote)

Supabase project ref: `ekwkklcfovwarcvvxtiq`

Merge owner: Stage 5 persistent LLM

Merge authorization: required

Merge status: not-started

## Completed Tasks

- Task 01: worktree created, safety audit, .env untracked (pending commit)

## Pending Tasks

- Task 02: Supabase schema, RLS, RPC, SQL tests
- Task 03: catalog canonicalization and seed parity
- Task 04: mobile hybrid auth, sync, services
- Task 05: cutover cleanup
- Task 06: validation and Stage 4 handoff

## Locked Decisions

(Unchanged from Stage 2 — see prior STATE.md sections.)

## Exact Next Action

Implement Task 02: create `supabase/migrations/`, RLS, RPCs, and SQL tests; link and push to remote project `ekwkklcfovwarcvvxtiq`.
