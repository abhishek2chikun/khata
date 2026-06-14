# Task 02: Add HSN, Precision, Quantity, And Compatibility Contracts

## Outcome

Land the single authoritative backend/local contract change: product and invoice-line HSN, three-decimal unit prices, integral new quantities, disabled new discounts, catalog v2, Drift/Alembic migrations, generated code, and backup v9-to-v10 compatibility.

## Why This Task Exists

Every later slice depends on these fields and invariants. Implementing UI first would duplicate validation and risk incompatible snapshots/backups.

## Dependencies

Task 01 go verdict. No later task may edit shared migrations/contracts until this task is reviewed.

## Repository Evidence

- Backend: `models/product.py`, `models/invoice_item.py`, `schemas/product.py`, `schemas/invoice.py`, `core/pricing.py`, `services/invoice_service.py`.
- Alembic head: `0009_invoice_gst_flags.py`.
- Local: `local_database.dart` schema 9, `local_products_service.dart`, `local_invoices_service.dart`, generated `local_database.g.dart`.
- Backup: `local_backup_service.dart`, `backup_models.dart`; schema 9, compatibility `local-v2`.
- Catalog: `tools/build_preinstalled_catalog.py`, source `data/source/products.xlsx`, asset JSON, seeder.

## Read Before Editing

- Design sections: Product And Catalog; Precision And Quantity; Invoice HSN, Discount, And Payment; Persistence/Migration/Compatibility.
- Existing migration and backup tests named in the plan index.

## Scope

### Change

- Backend product `hsn_code` nullable string, max 32, whitespace-normalized to null.
- Backend invoice item `product_hsn_code` nullable snapshot.
- Product buying/selling price and invoice entered/excl/incl unit-price columns to `Numeric(14,3)`; totals and ledger money remain `(14,2)`.
- Product create/opening quantity and stock delta validators enforce integral values; invoice line validator enforces positive integral quantity.
- Unit-price validators accept at most three decimal places and positive values.
- New non-zero discount is rejected; retain fields/default zero.
- Quote/create preparation snapshots HSN and blocks GST lines missing HSN with `MISSING_PRODUCT_HSN` before side effects.
- Alembic `0010_product_hsn_and_price_precision.py` with safe upgrade/downgrade; no value rewrite.
- Drift schema 10 with equivalent columns/migration and regenerated code.
- Backup schema 10. Import v9 by adding null HSN fields and preserving all other values; export v10. Keep explicit rejection below the supported floor.
- Catalog builder emits `catalog_version: 2`, nullable `hsn_code`, and prices rounded half-up to three decimals. Rebuild asset.
- Seeder upgrades matched rows by item number: set HSN/catalog prices, preserve quantity, active state, IDs, item numbers, and user-added products.

### Preserve

- Product identity/uniqueness rules.
- Existing decimal-capable quantity columns and historical values.
- Existing invoice totals, ledgers, request IDs, stock movements, statuses, and timestamps.
- API/local tax and idempotency semantics, extended only with HSN/precision canonicalization where required.

### Explicitly Out Of Scope

- Search UI, payment-mode UI, PDF layout, batch collection, Drive transport, analytics.

## Contracts And Invariants

- Canonical HSN is trimmed text or null; it is never unique and never parsed as a number.
- Request hashes use canonical three-decimal unit-price strings and integral quantity strings so API/local retries agree.
- GST validation uses the resolved product record, not client-provided HSN.
- Invoice response HSN comes from the stored snapshot, never the current product.
- `3.0075` catalog input rounds half-up to `3.008`; totals round half-up to two decimals after line calculations.
- A migration must not round existing two-decimal values or fractional historical quantities.

## Implementation Guidance

- Add shared Decimal validation helpers rather than duplicating scale checks.
- In PostgreSQL, altering scale from 2 to 3 is widening and should not need a data rewrite expression.
- In Drift, follow the existing explicit migration pattern and verify generated table constraints.
- Extend backup required-column maps and conversion before import validation.
- Add a pure catalog identity report comparing product IDs/item numbers before and after rebuild.
- Bump catalog seed marker/version so existing local installs receive HSN/precision updates without stock reset.

## Test-First Specification

- Failing backend schema tests for HSN fields, three-decimal prices, integral quantity rejection, and non-zero discount rejection.
- Failing invoice service/API/local tests: GST missing HSN rejected with no side effects; non-GST accepted; snapshot survives product edit.
- Failing migration contracts proving added columns/scale and forbidden money/ledger updates absent.
- Failing Drift v9 fixture migration preserving fractional history and adding null HSN.
- Failing backup v9 import/v10 round-trip tests.
- Failing catalog builder/seeder tests for 1,199 identities, 125 null HSN values, repeated HSN acceptance, `3.0075 -> 3.008`, and preserved stock on upgrade.

## Validation Ladder

```bash
.venv/bin/python -m pytest backend/pure_tests -q
.venv/bin/python -m pytest backend/tests/test_invoice_gst_flag_migration_contract.py <new migration contract> -q
BILLING_DATABASE_URL='postgresql+psycopg://khata:khata@localhost:55432/internal_billing_test' PYTHONPATH=backend .venv/bin/python -m pytest backend/tests/api/test_products_api.py backend/tests/services/test_product_service.py backend/tests/services/test_invoice_service.py -q
python3 tools/build_preinstalled_catalog.py
(cd mobile && dart run build_runner build --delete-conflicting-outputs)
(cd mobile && flutter test test/local/local_database_test.dart test/backup/local_backup_service_test.dart test/local/local_product_catalog_seeder_test.dart test/local/local_products_service_test.dart test/local/local_invoices_service_test.dart)
git diff --check
```

Expected evidence includes a live Alembic upgrade/downgrade/upgrade on a disposable test DB when PostgreSQL is available.

## Review Checklist

- [ ] No identity or financial-history rewrite.
- [ ] HSN nullable/non-unique and snapshot-based.
- [ ] Price/totals precision boundaries explicit.
- [ ] API/local request hashing agrees.
- [ ] Backup v9 compatibility proven.
- [ ] Generated Drift and catalog files match sources.

## Allowed Adaptation

Helper names and migration implementation details may follow repository conventions. Do not change scale, quantity, HSN, discount, or compatibility policy.

## Stop And Escalate If

- Drift migration requires destructive table replacement without complete column-copy proof.
- API/local hashes cannot be made equivalent.
- Catalog upgrade would overwrite user stock or duplicate products.
- v9 backup conversion cannot be deterministic.

## Commit Checkpoint

`feat(contracts): add hsn and invoice precision rules`

## Done When

All shared contracts/migrations/catalog/backup changes and focused tests are green, generated artifacts are current, and later tasks can consume stable types.

## Handoff Update

Record schema/catalog versions, migration commands, row/identity counts, compatibility fixtures, and exact changed public fields in the log and `STATE.md`.
