# Implementation Plan Index: Hybrid Supabase-Only Khata

Workflow schema: five-stage-v1

Objective: Implement one hybrid runtime where Supabase Postgres is the business authority, Drift is the local read/cache store, all official writes use Supabase RPC, and obsolete API/local/backup runtime paths are removed after parity is proven.

Cycle/lineage: `20260618-hybrid-supabase` / parent `20260614-invoice-collections-backup-analytics`

Repository baseline: `f873c3853c263bcbd91dbaab8b72b4f1ed2e8eb1`

Integration target branch: `main`

Planning checkout: `/Users/abhishek/python_venv/khata_app`

Safety branch: `main_backup` at `f873c3853c263bcbd91dbaab8b72b4f1ed2e8eb1`

Proposed feature branch/worktree: `codex/hybrid-supabase` at `/Users/abhishek/python_venv/khata_app/.worktrees/hybrid-supabase`

Implementation baseline rule: Stage 3 must create the feature worktree from the clean Stage 2 planning commit HEAD, then record that HEAD in `STATE.md` and `03-implementation-log.md`.

Execution shape: sequential

Implementation guide: `02-plan/implementation_guide.md`

## Scope/Non-Goals

In scope:

- Supabase schema, RLS, transactional RPCs, SQL tests, and idempotency.
- Master catalog generation from `MASTER CATALOG.xlsx` into both Supabase seed data and Drift seed JSON.
- Supabase Auth email/password login/session behavior.
- Drift cache metadata, startup/resume/manual/post-write sync, and cache upsert behavior.
- Hybrid service implementations behind existing app interfaces.
- Invoice preview/confirm/cancel semantics with server-side invoice numbers only.
- Phased removal of reachable API/local/backup runtime surfaces after parity tests.
- Runtime, SQL, Flutter, and Android validation evidence.

Non-goals:

- Realtime subscriptions in v1.
- Offline official write queue in v1.
- Silent import of existing phone-local business data into Supabase.
- Google Drive backup repair.
- Play Store deployment or production signing resolution.

## Locked Decisions

- Supabase Postgres is master for official business records.
- Drift is local cache/read store and may support drafts, but cannot authorize official writes.
- All business writes go through Supabase RPC functions.
- Normal sync uses row-level upsert by stable IDs; it must not replace the whole local DB.
- First hybrid cutover clears/rebuilds local business cache from Supabase after auth/setup checks.
- `MASTER CATALOG.xlsx` is the canonical catalog source and must become tracked in Stage 3.
- `main_backup` exists and is preserved as the pre-cleanup safety branch.

## Contracts To Preserve

- GST/non-GST invoice semantics, HSN handling, 3dp unit prices, 2dp money totals, whole-number new quantities.
- Customer receivables and buyer/supplier payable distinction.
- Pre-confirm invoice PDF preview does not create official records.
- Post-confirm sharing/PDF uses canonical invoice rows.
- Batch collection and analytics behavior remain available through hybrid data.

## Requirements Coverage

| AC/invariant | Task(s) | Implementation evidence expected | Verification | Runtime scenario |
|---|---|---|---|---|
| AC1 `main_backup` exists remotely | 01 | `git ls-remote` output in implementation log | Git command | Recovery branch available before cleanup |
| AC2 catalog source is tracked | 03 | Workbook moved/copied to tracked canonical path | Git status + generator tests | Seed can be rebuilt without chat context |
| AC3 Drift/Supabase seed parity | 03 | Shared IDs/counts in generated outputs | Catalog parity test | Fresh app and Supabase project see same catalog |
| AC4 schema applies cleanly | 02 | Supabase migrations under `supabase/migrations/` | Migration command | Empty project becomes usable |
| AC5 RLS/auth boundary works | 02,04 | RLS policies and auth tests | SQL/API tests | Unauthenticated client cannot read/write |
| AC6 all official writes use RPC | 02,04,05 | RPC wrappers only; old direct writes unreachable | Service/widget/static tests | Product/invoice/ledger writes hit RPC |
| AC7 no local invoice numbering | 02,04 | Server sequence/lock in `create_invoice`; no client max+1 path | SQL + code search | Two devices get unique invoice numbers |
| AC8 idempotent retry behavior | 02,04 | `request_id`/hash table and mobile retry preservation | SQL + service tests | Timeout retry returns same canonical result |
| AC9 cancel invoice atomicity | 02,04 | `cancel_invoice` reverses status, stock, ledger in one transaction | SQL tests | Cancel is all-or-nothing |
| AC10 startup/resume/manual/post-write sync | 04 | `HybridSyncService` triggers and state | Flutter tests | Second device sees confirmed invoice after sync |
| AC11 normal sync never full-replaces Drift | 04 | Upsert DAO calls and tests protecting unrelated rows | Service tests | Cache survives incremental refresh |
| AC12 first hybrid cutover rebuilds cache | 04,05 | hybrid-managed marker and reset path | Service/integration tests | Old local data is not merged silently |
| AC13 offline official writes blocked | 04 | connectivity/session gate and UX error | Service/widget tests | Draft allowed; confirm blocked offline |
| AC14 backup/runtime UI removed after parity | 05 | Backup menu/routes/hooks gone or unreachable | Widget/static tests | User cannot start Drive/local backup |
| AC15 API/local modes unreachable | 05 | no runtime `DATA_MODE` selection path | Static/app-shell tests | App always starts hybrid runtime |
| AC16 retained behavior parity | 04,06 | regression tests for GST/PDF/collections/analytics | Flutter tests | Existing workflows still work |
| AC17 Android build works with dart defines | 06 | release build command output | Android build | Installable hybrid APK |
| AC18 Stage 4 handoff is reviewable | 06 | return packet, validation report, implementation log | Artifact audit | Reviewer can verify without redoing discovery |

## Task/Slice Order

| ID | Outcome | Depends on | Parallel? | Risk | Plan file |
|---|---|---|---|---|---|
| 01 | Create Stage 3 worktree and safety audit | none | no | high | `01-stage-3-setup.md` |
| 02 | Create Supabase schema, RLS, RPCs, and SQL tests | 01 | no | high | `01-supabase-schema-rpc.md` |
| 03 | Canonicalize catalog and generate Drift/Supabase seed parity | 01,02 contracts | no | high | `02-catalog-seeding.md` |
| 04 | Implement Supabase auth, sync, Drift cache, and hybrid services | 02,03 | no | high | `03-mobile-hybrid-services-sync.md` |
| 05 | Remove reachable API/local/backup runtime surfaces after parity | 04 | no | high | `04-cutover-cleanup.md` |
| 06 | Validate end-to-end and prepare Stage 4 handoff | 02-05 | no | high | `05-validation-and-handoff.md` |

## Baseline Commands

Run from `/Users/abhishek/python_venv/khata_app` before Stage 3 creates the worktree:

```bash
git fetch origin
git switch main
git status --short
git rev-parse HEAD
git ls-remote --heads origin main_backup
git worktree add .worktrees/hybrid-supabase -b codex/hybrid-supabase main
cd .worktrees/hybrid-supabase
git status --short
git rev-parse HEAD
```

Expected:

- `main` is clean except any explicitly preserved unrelated user files in the planning checkout.
- `origin/main_backup` exists at `f873c3853c263bcbd91dbaab8b72b4f1ed2e8eb1`.
- The feature worktree starts from the Stage 2 planning commit, not from the older pre-planning `f873c38` baseline.
- `MASTER CATALOG.xlsx` is intentionally adopted into a tracked canonical source path before catalog generator work.

## Cross-Task Integration

- Task 02 owns DB contracts. Task 04 may not redesign RPC payloads without updating Task 02 tests and the design document.
- Task 03 owns seed IDs and normalized catalog fields. Task 02 and Task 04 consume those outputs.
- Task 04 owns mobile read/write paths. Task 05 may remove old modes only after Task 04 tests prove all expected hybrid paths exist.
- Task 06 owns evidence gathering and must not weaken tests to produce a green handoff.

## Runtime/Release Evidence

Required validation ladder:

```bash
python3 tools/build_preinstalled_catalog.py
<supabase migration command chosen by Task 02>
<supabase SQL/RPC test command chosen by Task 02>
(cd mobile && flutter test test)
(cd mobile && flutter analyze)
(cd mobile && flutter build apk --release --dart-define=SUPABASE_URL=<url> --dart-define=SUPABASE_ANON_KEY=<anon>)
```

If real Supabase credentials are unavailable, run against local Supabase/Postgres or mark real-project evidence blocked. Do not mark it passed from mocks alone.

## Rollout/Rollback

Rollout:

1. Create Supabase project.
2. Apply migrations.
3. Seed from tracked master catalog output.
4. Create father/brother/operator users.
5. Install hybrid APK on primary and secondary devices.
6. Login, force initial sync, verify counts and sample workflows.

Rollback:

- Before real Supabase production writes, reinstall/build from `main_backup`.
- After real Supabase writes exist, export/preserve Supabase data before any rollback.

## Strong-Model/Human Review Gates

- After Task 02: review transaction/idempotency/RLS choices.
- After Task 04: review that no official write can happen outside RPC.
- Before Task 05 deletion: review parity and cleanup risk.
- Before merge: Stage 5 persistent LLM reviews full diff and evidence.

## Known Plan Assumptions

- Supabase Dart RPC, Auth, Postgres functions, and RLS remain suitable.
- V1 load is small: about 50 invoices/day, 2k products, 30 sellers, 50-100 customers, 5-10 devices.
- Existing phone-local production data does not need preservation for first hybrid cutover.
- The workbook can be parsed deterministically.

## Plan Self-Review Result

- Execution shape is sequential because schema/RPC, seed IDs, and mobile service contracts share critical boundaries.
- No parallel lane is justified until DB and seed contracts are stable.
- Every blocking AC maps to at least one task and proof method.
- Stage 3 must stop rather than invent behavior if Supabase RPC cannot enforce an existing invariant.
