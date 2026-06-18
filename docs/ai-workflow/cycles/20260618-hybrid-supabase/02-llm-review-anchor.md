# LLM Review Anchor: Hybrid Supabase Cycle

Workflow schema: five-stage-v1

Workflow objective: move Khata to one hybrid runtime where Supabase Postgres is master, Drift is cache, and official writes use RPC.

Cycle ID and lineage: `20260618-hybrid-supabase`, parent `20260614-invoice-collections-backup-analytics`.

Repository baseline SHA: `f873c3853c263bcbd91dbaab8b72b4f1ed2e8eb1` before Stage 2 planning commit.

Integration target and Stage 2 planning baseline rule: `main`; Stage 3 must start from the clean Stage 2 planning commit HEAD.

Proposed feature branch/worktree specification: `codex/hybrid-supabase` at `/Users/abhishek/python_venv/khata_app/.worktrees/hybrid-supabase`.

User value and success definition: father, brother, and future 5-10 small-business devices can share correct invoices, products, customers, stock, ledgers, PDF/share, collections, and analytics without a custom server deployment.

## Approved Scope And Non-Goals

In scope: Supabase schema/RPC/RLS, catalog seed parity from `MASTER CATALOG.xlsx`, Supabase Auth, Drift cache sync, hybrid services, invoice confirm/cancel hardening, phased cleanup, and validation.

Non-goals: realtime v1, offline official write queue, silent local-data import, Google Drive backup repair, Play Store deployment.

## Architecture In One Page

- Supabase Postgres is master.
- Supabase RPC owns official writes and transactions.
- Drift stores cached canonical rows and drafts.
- Screens read Drift and show sync status.
- Sync runs at login/start/resume/manual/post-write.
- First hybrid cutover clears/rebuilds local business cache from Supabase.
- Backup/local/API runtime is removed after parity is proven.

## Key Decisions And Rejected Alternatives

- Chosen: Supabase Postgres authority. Rejected: phone-only database sync, Google Drive backup sync, local-only multi-device sharing.
- Chosen: RPC-only writes. Rejected: direct Flutter table writes.
- Chosen: no official offline writes in v1. Rejected: offline mutation queue.
- Chosen: phased cleanup. Rejected: deleting old runtime before hybrid tests.

## Contracts And Invariants That Must Survive

- No Flutter/Drift official invoice numbering.
- No official write bypasses RPC.
- Same `request_id` plus same payload is idempotent.
- Same `request_id` plus changed payload conflicts.
- Cancel invoice reverses invoice status, stock, and ledger atomically.
- Normal sync upserts rows and does not full-replace Drift.
- GST/non-GST, HSN, 3dp prices, 2dp totals, whole quantities, batch collections, analytics, and PDF/share behavior are preserved.

## Acceptance Criteria By Risk

Highest risk: AC4-AC14 in `02-design.md`, especially schema/RPC atomicity, idempotency, invoice numbering, sync upsert, first cutover, and offline write blocking.

## Expected Change Surface By Task/Commit

- Task 01: Stage 3 worktree/state/log only.
- Task 02: `supabase/migrations/`, SQL/RPC tests, DB authority contracts.
- Task 03: catalog source, generator, Drift/Supabase seed outputs, parity tests.
- Task 04: Supabase config/auth, sync service, hybrid services, mobile tests.
- Task 05: runtime cleanup, backup removal, docs/tests.
- Task 06: validation evidence and handoff artifacts.

## Highest-Risk Failure Modes

- Client still writes official data locally.
- Invoice number uniqueness depends on cached local state.
- Timeout retry creates duplicate invoice.
- Sync replaces local DB and loses cache/draft/user context.
- Backup UI remains and users treat it as sync.
- Tests pass only with mocks and no Supabase/Postgres evidence.

## Review Hypotheses

- Supabase free tier is enough for the stated workload.
- RPC functions can enforce existing backend/local invariants without Edge Functions.
- The workbook can be parsed deterministically.
- First cutover does not need preserving existing phone-local business data.

## Expected Runtime/Release Evidence

- Supabase migration and SQL/RPC tests.
- Catalog generator parity tests.
- `flutter test`, `flutter analyze`, Android release build with Supabase dart defines.
- Static searches proving no local invoice numbering, service role key, or old runtime surface.
- Manual/scripted two-device sync scenario if credentials/device access are available.

## Plan Assumptions To Recheck

- `MASTER CATALOG.xlsx` content and sheet shape.
- Existing current branch remains clean before Stage 3.
- Supabase project/local stack is available for real authority tests.

## Final Review And Merge Checklist

- Read `STATE.md`, this anchor, Stage 4 return packet, actual diff, and validation evidence.
- Confirm no merge happened before Stage 5.
- Confirm `main_backup` still exists.
- Confirm all blocking ACs are proven or honestly blocked.

## Rehydration Order

1. `STATE.md`
2. This anchor
3. `02-design.md`
4. `02-plan/00-plan-index.md`
5. `02-plan/implementation_guide.md`
6. Assigned task packet
7. Stage 4 return packet after implementation
8. Actual baseline-to-validated-head diff
