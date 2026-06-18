# Task 02: Create Supabase Schema, RLS, RPC, And SQL Tests

## Outcome

Create the Supabase authority layer: migrations, constraints, RLS policies, transactional RPCs, idempotency support, and SQL/RPC tests for all official writes.

## Why This Task Exists

The app becomes safe for 5-10 devices only if Postgres, not Flutter/Drift, owns concurrency, invoice numbering, stock, ledger, and retry semantics.

## Dependencies

- Task 01 setup complete.
- Existing schema-10 Drift/Alembic concepts reviewed before writing migrations.
- Catalog fields from Task 03 are anticipated but not generated yet; use stable IDs and seed tables that Task 03 can populate.

## Repository Evidence

Read current analogs before editing:

- `backend/alembic/versions/`
- `backend/app/models/`
- `backend/app/services/`
- `mobile/lib/local/`
- `mobile/lib/models/`
- `docs/ai-workflow/PROJECT_CONTEXT.md`
- `../02-design.md` AC1-AC18

## Read Before Editing

1. `00-plan-index.md`
2. `implementation_guide.md`
3. `../02-design.md` sections: persistence, failure semantics, acceptance criteria
4. Current backend and Drift schema files

## Scope

### Change

- Add `supabase/migrations/` with canonical SQL DDL.
- Add SQL/RPC test harness under an appropriate Supabase/backend test location.
- Add RPC functions for official writes.
- Add idempotency tables/constraints and indexes.
- Add RLS policies and grants needed for authenticated users and security-definer RPCs.

### Preserve

- Existing business semantics: GST/non-GST, HSN, 3dp prices, 2dp totals, whole quantity.
- Historical invoices must remain renderable through soft archive fields.
- Backend/local code may remain as reference until Task 05.

### Explicitly out of scope

- Flutter service wiring.
- Catalog workbook parsing.
- Runtime cleanup.
- Service role key usage in the app.

## Contracts And Invariants

- Supabase is the only authority for official records after cutover.
- Flutter clients cannot directly mutate invoice, invoice item, stock, ledger, product, customer, buyer, or company profile tables.
- Every write RPC accepts `request_id` and enough payload to compute a deterministic `request_hash`.
- Same `request_id` plus same hash returns the original canonical result.
- Same `request_id` plus different hash returns an idempotency conflict.
- `create_invoice` assigns invoice numbers server-side only.
- `cancel_invoice` updates invoice status, stock reversal, and ledger reversal in one transaction.
- Archive/reactivate is soft state; v1 exposes no hard delete.

## Implementation Guidance

Port current business tables into Supabase SQL while preserving schema-10 fields and UUID IDs:

- `company_profiles`
- `products`
- `customers`
- `buyers`
- `invoices`
- `invoice_items`
- `stock_movements`
- `customer_transactions`
- `buyer_transactions`
- `collections` or existing payment transaction equivalent
- `operator_profiles` if needed for auth display/audit
- `rpc_requests` or per-domain idempotency table

Add sync metadata:

- `created_at timestamptz default now()`
- `updated_at timestamptz not null default now()`
- `is_active boolean not null default true` where archive exists
- `deleted_at timestamptz` only for tombstones
- indexes on `updated_at`, stable IDs, invoice number, and FK columns

Required RPCs:

- `seed_master_catalog`
- `create_invoice`
- `cancel_invoice`
- `record_collection`
- `record_batch_collections`
- `create_product`, `update_product`, `archive_product`, `reactivate_product`
- `adjust_stock`
- `create_customer`, `update_customer`, `archive_customer`, `reactivate_customer`
- `create_buyer`, `update_buyer`, `archive_buyer`, `reactivate_buyer`
- buyer ledger/opening balance RPCs
- `upsert_company_profile`

RPC return contract:

- Return canonical changed rows in snake_case JSON.
- Invoice RPC returns invoice header, items, stock movements, customer ledger rows, customer balance, and any affected product stock rows.
- Cancel RPC returns invoice status, reversal movements, ledger reversals, and affected balances.
- Product/customer/buyer/company RPCs return changed rows.

## Test-First Specification

Create SQL/RPC tests that fail before implementation:

- Migration applies from empty DB.
- Unauthenticated table reads/writes fail.
- Authenticated direct writes to critical tables fail.
- RPC writes succeed for authenticated user.
- Concurrent `create_invoice` calls produce unique sequential official numbers.
- Invoice create inserts header/items/stock/customer ledger atomically.
- Retry with same request returns same result.
- Retry with same request but changed payload conflicts.
- Cancel invoice is atomic and idempotent where allowed.
- Archived product/customer write attempts fail.
- Catalog seed is idempotent and does not reset mutable stock after cutover unless explicit admin reseed flag is used.

## Validation Ladder

Focused:

```bash
<supabase migration command>
<supabase SQL/RPC test command>
```

Broader:

```bash
rg -n "max\\(invoice|invoice_number\\s*\\+\\s*1|service_role" .
```

Expected evidence:

- Migration and SQL tests pass.
- Search does not reveal client-side official invoice numbering or committed service role secrets.

## Review Checklist

- RLS stays enabled on protected tables.
- Security-definer functions are narrowly granted.
- Idempotency covers every write RPC.
- Errors are typed or structured enough for mobile to show refresh/offline/conflict messages.
- No Supabase secret is committed.

## Allowed Adaptation

If one RPC becomes too large, split it into internal helper SQL functions but keep one public transactional entrypoint per business write.

## Stop And Escalate If

- A required invariant cannot be enforced inside Postgres/RPC.
- RLS must be disabled globally to make RPC work.
- Existing backend semantics conflict with Drift schema-10 fields.
- Supabase free-tier limits appear insufficient for the planned family workload.

## Commit Checkpoint

Commit after migrations and SQL/RPC tests pass. Suggested message: `feat(hybrid): add supabase authority schema`.

## Done When

Supabase migrations apply cleanly, SQL/RPC tests prove the authority rules, and Task 04 can call stable RPC names/payloads without redesign.

## Handoff Update

Add to `03-implementation-log.md`: migration files, RPC list, test command/output summary, any deviations, and next task.

Update `STATE.md`: Task 02 status, schema/RPC validation evidence, and current task `Task 03`.
