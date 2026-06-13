# Task 02: Enforce GST And Non-GST Invoice Semantics

## Outcome
API and local quote/create paths calculate, validate, hash, persist, and reverse GST/non-GST invoices consistently while preserving transactional stock and ledger behavior.

## Why This Task Exists
Covers AC-GST-01, AC-GST-02, AC-REGRESSION-01, idempotency, and accounting integrity. It must precede UI/PDF work so presentation consumes canonical values.

## Dependencies
Task 01 complete. Existing pricing helpers, invoice services, test fixtures, and PostgreSQL test database available.

## Repository Evidence
- `backend/app/services/invoice_service.py:_prepare_invoice, _build_invoice_request_hash, create_invoice` own canonical API calculation and side effects.
- `backend/app/core/pricing.py:normalize_line` is the existing GST normalization path and must remain unchanged for GST invoices.
- `mobile/lib/local/local_invoices_service.dart` mirrors preparation, validation, hashing, writes, stock, and ledger behavior.
- `backend/tests/services/test_invoice_service.py`, API invoice tests, and `mobile/test/local/local_invoices_service_test.dart` are existing seams.

## Read Before Editing
Read both invoice services end to end, pricing/tax helpers, invoice/item models, create/cancel tests, and `01-design.md` contracts section.

## Scope
- Modify: `backend/app/schemas/invoice.py`, `backend/app/services/invoice_service.py`, the selected non-GST pricing helper location, `mobile/lib/local/local_invoices_service.dart`, `mobile/lib/models/invoice_detail.dart`, and quote/detail parsing in `mobile/lib/services/invoices_service.dart`.
- Tests: backend service/API create/cancel/idempotency and local invoice service parity.
- Docs/state: implementation log and task status.

## Contracts And Invariants
- Resolve requested mode as `payload.gst_flag` when supplied, otherwise active company `gst_flag`.
- Reject seller `gst_flag=true` without trimmed GSTIN and seller `gst_flag=false` with GSTIN using `INVALID_GST_PROFILE` before calculation.
- Reject GST invoice for non-GST seller with `GST_INVOICE_NOT_ALLOWED`.
- For GST seller + non-GST request, resolve every line's source rate using current override/product precedence; reject any non-zero rate with `NON_GST_TAXABLE_LINES`.
- For non-GST seller + non-GST request, ignore legacy product GST metadata and force effective rate/amount components to zero.
- Non-GST line algorithm: quantity/discount validation remains; final unit price is the entered `unit_price` when present, otherwise product `selling_price`; subtotal is quantity times final unit price, discount applies using existing rounding, taxable amount equals discounted amount, line total equals taxable amount, and all GST components are zero.
- GST invoice behavior remains byte-for-byte semantically equivalent to current `normalize_line` output.
- Quote and create enforce identical rules. Invoice snapshot `company_gstin` must be null for non-GST invoices even if a GST seller issued an allowed zero-rate bill; customer GSTIN may remain stored internally but PDF omission is Task 04.
- Add resolved `gst_flag` to canonical request hash. Same request/same content is idempotent; changed mode conflicts.
- Ledger debit equals canonical `grand_total`; cancellation reverses the same persisted amount. Stock rules remain unchanged.

## Implementation Guidance
1. Add red policy/calculation tests in backend and local suites with matching representative inputs.
2. Introduce a small prepared-line normalization boundary rather than duplicating entire invoice services. Reuse `normalize_line` for GST; add a clearly named non-GST normalization helper near pricing code or locally only if sharing would create circular dependencies.
3. Use Decimal/backend and existing canonical double/string rounding/local conventions. Do not calculate by hiding tax from already-normalized GST output.
4. Include resolved mode in quote response and persisted invoice construction/snapshots.
5. Update local canonical hash in the same task and compare normalized payload shapes across modes.
6. Re-run existing create, partial-paid, total-paid, negative-stock warning, duplicate product, cancel, analytics snapshot, and customer ledger tests.

Representative outcomes:
```text
non-GST seller, product selling_price=118, stored gst_rate=18, qty=2
=> unit final=118, taxable=236, gst=0, grand_total=236

GST seller, gst_flag=false, resolved rate=18
=> 400 NON_GST_TAXABLE_LINES; no writes
```

## Test-First Specification
- Backend/local `non_gst_seller_forces_zero_tax_without_reducing_final_price`: asserts line/totals and ledger amount. Prevents hiding tax after tax-inclusive decomposition.
- `gst_seller_rejects_non_gst_taxable_lines_at_quote_and_create`: asserts stable code and zero invoice/stock/ledger writes.
- `gst_seller_allows_non_gst_zero_rate_lines`: asserts snapshot flag/GSTIN/totals.
- `non_gst_seller_rejects_gst_invoice`: stable error, no writes.
- `invalid_profile_gst_configuration_blocks_invoice`: both invalid combinations.
- `gst_invoice_preserves_existing_intra_and_inter_state_totals`: regression fixtures.
- `idempotency_hash_includes_gst_flag`: replay succeeds; same request with flipped mode is 409/local conflict.
- `cancel_non_gst_invoice_restores_stock_and_reverses_exact_grand_total`: prevents cancellation drift.

## Validation Ladder
1. Red: focused new backend/local policy tests fail because mode is not enforced.
2. Green: run backend invoice service/API files and `mobile/test/local/local_invoices_service_test.dart`.
3. Run backend customer ledger/analytics/invoice cancel suites and mobile local analytics/customer invoice history suites.
4. Run formatter/analyzer checks for changed files.
5. Runtime via API and local service fixtures: create one GST and one non-GST invoice, inspect item/totals/ledger/stock, cancel both.
6. Proves AC-GST-01, AC-GST-02 calculation portion, and accounting/idempotency parts of AC-REGRESSION-01.

## Review Checklist
- Quote/create parity; API/local parity.
- No float-only money algorithm introduced on backend.
- GST behavior/regime unchanged.
- Non-GST final price semantics match approved examples.
- Failed validations perform no writes.
- Hash and retry behavior include resolved mode.
- Snapshot immutability and cancellation are preserved.

## Allowed Adaptation
Place the non-GST helper in `core/pricing.py` if it cleanly returns the existing `NormalizedLine`; otherwise keep equivalent private helpers in services with parity tests. Do not alter approved math.

## Stop And Escalate If
- Existing `pricing_mode=PRE_TAX` semantics make “final non-GST unit price” ambiguous for a real supported workflow; return with exact fixture conflict rather than guessing.
- Local and backend rounding cannot produce matching two-decimal totals.
- Policy enforcement requires historical product classification not present in the repository.

## Commit Checkpoint
Suggested: `feat: enforce gst and non-gst invoice calculations`

## Done When
All policy, calculation, idempotency, stock, ledger, cancellation, and parity tests pass; no UI/PDF claim is made yet.

## Handoff Update
Log representative totals/errors, test commands/results, and changed hash shape. Update `STATE.md` with Task 02 complete and strong-model tax review gate status.
