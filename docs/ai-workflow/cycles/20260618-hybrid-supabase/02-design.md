# Design: Hybrid Supabase-Only Khata

Workflow schema: five-stage-v1

## Verdict

proceed

## Problem And Outcome

Khata is currently production-oriented around local Drift/SQLite mode. That is safe for one writer but unsafe for multiple family/business devices because each phone can independently assign invoice numbers, mutate inventory, and update ledgers. Google Drive backup is a recovery mechanism, not a multi-writer sync protocol.

The desired outcome is a robust low-cost hybrid architecture:

- Supabase Postgres is the master database for all official business data.
- Flutter reads quickly from Drift cache.
- All official writes go through Supabase RPC functions that enforce transactions, idempotency, stock, ledger, and invoice-number rules.
- The same app can serve 5-10 low-volume devices without a custom FastAPI deployment.
- The codebase is cleaned to a hybrid-only runtime after parity is proven.

What could look successful while failing the real goal:

- Screens load from Supabase but invoice confirm still writes locally.
- Sync downloads snapshots by replacing the local DB and loses local cache history.
- Product/customer writes bypass RPC and create state that invoice RPC later rejects.
- Invoice preview writes draft records before user confirmation.
- Cleanup removes local/API reference behavior before parity tests prove hybrid rules.

## Architecture

Runtime shape:

```text
Flutter UI
  -> existing service interfaces
  -> Hybrid*Service
     reads: Drift cache
     writes: Supabase RPC
     sync: Supabase rows -> Drift upsert
  -> Supabase Postgres authority
```

Component boundaries:

| Component | Responsibility | Must not do |
|---|---|---|
| Supabase SQL schema | Business tables, constraints, indexes, RLS | Store app secrets |
| Supabase RPC | Official writes, transactions, idempotency, canonical return payloads | Delegate financial decisions to client |
| Drift cache | Fast reads, PDF/share data, draft support, offline view | Assign official invoice numbers or become master |
| `HybridSyncService` | Startup/resume/manual/post-write sync, cursors, cache upserts | Whole-database replace during normal sync |
| Hybrid services | Fit current mobile interfaces; call RPC for writes | Expose old API/local runtime choices |
| UI | Existing workflows, sync status, clear offline write errors | Hide stale/offline state for official writes |

## Data Flow

### App Start / Login

1. Initialize Supabase with `SUPABASE_URL` and `SUPABASE_ANON_KEY`.
2. Restore Supabase session from secure storage.
3. Open Drift.
4. If this is first hybrid run, mark cache as hybrid-managed and clear/rebuild business cache from Supabase.
5. Run sync.
6. Open app shell using Drift cache.

### Read

1. Screen calls service interface.
2. Hybrid service reads Drift cache.
3. User sees cached data plus sync status.
4. Manual/app-resume sync upserts newer Supabase rows.

### Write

1. Screen validates obvious UI input only.
2. Hybrid service calls Supabase RPC with request payload and `request_id`.
3. RPC validates against current Postgres rows, performs transaction, and returns canonical changed rows.
4. Hybrid service upserts returned rows into Drift.
5. Sync service optionally pulls related rows after write.

### Invoice Preview And Confirm

1. Create-invoice screen builds draft from cached products/customers/profile.
2. Preview/quote may compute locally from cache and must not write.
3. PDF preview before confirm uses preview-only model.
4. Confirm calls `create_invoice(request_id, draft)`.
5. Supabase assigns invoice number and writes invoice/items/stock/customer ledger atomically.
6. App upserts canonical invoice result and shares PDFs only from canonical invoice after confirm.

## Persistence And Schema

Supabase tables mirror current schema-10 business concepts:

- `buyers`
- `buyer_transactions`
- `products`
- `customers`
- `customer_transactions`
- `company_profiles`
- `invoices`
- `invoice_items`
- `stock_movements`

Additions required for hybrid:

- `updated_at` on every synced table.
- `deleted_at` only where tombstones are needed; otherwise use existing `is_active`.
- `sync_cursors` or Drift-local sync metadata table on the phone.
- RPC idempotency support through existing/request-specific `request_id` and `request_hash`.
- Invoice-number sequence/counter owned by Postgres.

Do not add backup tables to Supabase unless a later admin export feature needs them. Local `backup_settings` may be repurposed or replaced for cache metadata during Stage 3, but final naming should not imply user backup.

## Security And Auth

- Use Supabase email/password auth.
- Keep a known-user operational model: father, brother, and any future operator are separate users.
- Enable RLS on business tables.
- Authenticated users may read business tables.
- Critical direct writes are blocked; RPC functions perform writes with controlled permissions.
- Stage 3 must avoid committing secrets. `SUPABASE_URL` and anon key are runtime config. Service role keys are never used in Flutter.

## Failure Semantics

| Scenario | Required behavior |
|---|---|
| App starts offline with cache | Open read-only cached data; show stale/offline state |
| User confirms invoice offline | Block with clear "Connect before saving invoice" message |
| RPC times out after commit | Retry same `request_id`; RPC returns existing canonical result |
| Same `request_id`, different payload | Return idempotency conflict; app does not mutate Drift |
| Stale product/customer cache | RPC rejects with clear refresh-required or domain error |
| Post-write Drift upsert fails | Surface local cache refresh error and force sync retry; Supabase remains source of truth |
| First hybrid run finds old local data | Clear/rebuild business cache from Supabase; do not merge silently |
| Supabase seed missing | App login can succeed but sync blocks business shell with setup-required error |

## Cleanup Design

Cleanup is gated:

1. Hybrid path implemented and tests pass.
2. Supabase schema/RPC tests pass.
3. App can login, sync, create invoice, cancel invoice, and share PDF from cache.
4. Only then remove reachable old modes and backup surfaces.

Final runtime must not expose:

- `DATA_MODE=api/local` mode selection.
- Local first-user setup.
- Backup & Restore drawer destination.
- Google Drive backup scheduling.
- Local backup import/restore as a user workflow.

The backend/FastAPI folder may be removed or retained only as non-runtime historical reference if the cleanup plan explicitly marks it. Preferred final state for this cycle is hybrid-only app plus Supabase SQL.

## Acceptance Criteria

| ID | Required outcome | Proof method | Required environment/artifact | Blocking? |
|---|---|---|---|---|
| AC1 | `main_backup` exists remotely at pre-cleanup HEAD | `git ls-remote --heads origin main_backup` | Git remote | yes |
| AC2 | `MASTER CATALOG.xlsx` is canonical tracked source | Git status and catalog doc | Repo | yes |
| AC3 | Drift and Supabase seed outputs share IDs/counts | Catalog generator test | Local dev | yes |
| AC4 | Supabase schema applies cleanly | Supabase migration command | Local Supabase or project | yes |
| AC5 | RLS blocks unauthenticated reads | SQL/API test | Supabase test env | yes |
| AC6 | Auth login/session restore/logout works | Flutter auth tests | Mobile tests | yes |
| AC7 | Startup/resume/manual sync upserts without DB replace | Hybrid sync tests | Mobile tests | yes |
| AC8 | First hybrid cutover clears old business cache and rebuilds | Cutover test | Mobile test with seeded Drift | yes |
| AC9 | Product/customer/buyer writes use RPC and update Drift | Service tests | Fake/real Supabase adapter | yes |
| AC10 | Invoice preview performs no official write | Widget/service test | Mobile tests | yes |
| AC11 | Confirm invoice writes only through Supabase RPC | RPC spy/integration test | Mobile + Supabase test | yes |
| AC12 | Concurrent invoices receive unique server numbers | SQL concurrency test | Supabase/Postgres | yes |
| AC13 | Invoice create commits invoice/items/stock/ledger atomically | SQL test | Supabase/Postgres | yes |
| AC14 | Cancel invoice atomically reverses stock and ledger | SQL test | Supabase/Postgres | yes |
| AC15 | Offline official writes are blocked | Mobile service/widget tests | Mobile tests | yes |
| AC16 | PDF/share works from cached canonical invoice | Widget/service tests | Mobile tests | yes |
| AC17 | Backup menu and Drive/local backup runtime are unreachable | Widget/app shell tests | Mobile tests | yes |
| AC18 | Full validation passes | test/analyze/build command log | Stage 3 return packet | yes |

## Deferred

- Realtime subscriptions.
- Offline official write queue.
- Silent local-to-Supabase import of existing phone data.
- Google Drive backup repair.
- Public multi-tenant SaaS behavior.
