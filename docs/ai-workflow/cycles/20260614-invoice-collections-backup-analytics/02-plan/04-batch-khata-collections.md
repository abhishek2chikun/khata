# Task 04: Add Atomic Seven-Day Customer Collections

## Outcome

Add a Customers/Khata workflow that records collections for all owing customers across today and up to the previous six days in one atomic, idempotent submission.

## Why This Task Exists

Recording each payment through individual customer detail screens is too slow for daily operations. Reusing the single-row endpoint in a client loop would allow partial days and duplicate retries, so a domain-level batch boundary is required.

## Dependencies

Task 02 shared schema/types. May run parallel with Tasks 05/06 after that checkpoint.

## Repository Evidence

- Backend `schemas/customer.py`, `services/customer_service.py`, customer/collection routers.
- Local `services/payments_service.dart`, `local/local_payments_service.dart`.
- UI `customer_list_screen.dart`, `customer_detail_screen.dart`, `record_payment_screen.dart`.
- `CustomerTransaction` already supports dated, positive, idempotent `COLLECTION` rows.

## Read Before Editing

- Design Batch Collections contract, failure behavior, and scenario matrix.
- Existing customer money/idempotency tests.

## Scope

### Change

- Backend request/response models for grid read and batch write.
- Backend read route accepts `from_date` and `to_date`; require inclusive range <=7 days, no future date, and return active customers with positive current balance plus existing collection totals keyed by date.
- Backend batch route validates and inserts one transaction per entry inside one service-owned transaction; do not call committing single-row helper repeatedly.
- Local service exposes matching read/write methods and runs the same checks inside one Drift transaction.
- Extend the shared mobile payments boundary with `loadCollectionGrid` and `recordCollectionBatch` rather than placing batch methods on customer UI classes.
- Add `Daily collections` action to Customers/Khata.
- Grid behavior:
  - active positive-balance customers only;
  - customer search filters rows without losing entered values;
  - frozen/name and pending-balance columns; horizontally scrollable date columns;
  - today by default; add distinct dates from today-minus-six through today, max seven; order oldest to newest; visually emphasize today;
  - each cell shows existing total read-only and a separate additional-amount input;
  - blank/zero is omitted;
  - per-customer entered sum cannot exceed current pending balance;
  - summary shows entry count and total before confirmation.
- Save uses one generated batch request ID retained through retry until success/cancel/edit. Any edit after a failed attempt generates a new request ID.
- On success, show posted count/total, refresh grid and customer list, clear committed inputs. On stale-balance/conflict, write nothing, reload balances, preserve unsaved input values, and show the conflict.

### Preserve

- Individual collection workflow and append-only ledger history.
- Existing collection reversal/invoice cancellation behavior.
- Two-decimal money validation and active-customer rule.

### Explicitly Out Of Scope

- Editing/replacing existing collections, future dates, dates older than six days, advance credit, buyer/payable batch entry.

## Contracts And Invariants

- Canonical hash sorts entries by customer UUID then date and formats amounts to two decimals.
- Duplicate customer/date entries in one request are rejected rather than summed silently.
- All customers are re-read/locked in one transaction before balance validation.
- Sum new entries per customer across all selected dates; compare with current pending balance.
- Zero is UI-only omission and never persisted.
- Same request ID/same hash returns the original result without duplicate rows.

## Implementation Guidance

- Refactor single collection construction into a no-commit helper reusable by single and batch services; outer service owns commit/rollback.
- PostgreSQL should lock affected customer/balance rows or otherwise serialize against concurrent writes. Use deterministic customer ordering to reduce deadlocks.
- Local Drift transaction computes balances and inserts all rows synchronously in one transaction.
- For the grid, keep controllers in a map keyed by `(customerId, date)` so filtering/reordering does not lose text.
- Pageless vertical list + horizontal date viewport is preferred over building one giant table widget.

## Test-First Specification

- Backend/local tests for one-day, seven-day, blank/zero omission, duplicate cell, old/future date, archived customer, inactive/zero-balance exclusion, overpayment, concurrent/stale balance, same retry, conflicting retry, and injected failure after N inserts proving rollback.
- API wire tests assert normalized error envelope and response totals.
- Widget tests cover default today, add/remove dates, max seven, search preserving values, existing totals, zero cells, overpayment validation, confirmation, success refresh, and failure preservation.
- End-to-end local test confirms individual ledger totals and customer balances after a multi-customer batch.

## Validation Ladder

```bash
PYTHONPATH=backend .venv/bin/python -m pytest backend/pure_tests -q
BILLING_DATABASE_URL='postgresql+psycopg://khata:khata@localhost:55432/internal_billing_test' PYTHONPATH=backend .venv/bin/python -m pytest backend/tests/api/test_customers_api.py backend/tests/services/test_customer_ledger_service.py <new batch tests> -q
(cd mobile && flutter test test/services/payments_service_test.dart test/local/local_customers_payments_service_test.dart test/local/local_customers_collections_service_test.dart)
(cd mobile && flutter test test/widgets/customer_list_screen_test.dart <new batch screen test>)
```

Runtime: enter a mixed grid with zeros, multiple customers, and multiple dates; verify ledger entries/balances; retry the same request; provoke an overpayment and confirm no rows were added.

## Review Checklist

- [ ] True service/database atomicity, not UI sequencing.
- [ ] Canonical idempotency hash.
- [ ] Zero cells omitted.
- [ ] Seven-day window exact.
- [ ] Existing entries immutable.
- [ ] Search/filter preserves unsaved state.

## Allowed Adaptation

Router path and widget decomposition may follow current naming. Do not weaken atomicity, date window, overpayment, or retry behavior.

## Stop And Escalate If

- Existing service transaction ownership cannot support a no-commit helper safely.
- Pending balance cannot be validated consistently under concurrent API writes.
- The UI design would instantiate controllers for unbounded historical dates.

## Commit Checkpoint

`feat(khata): add atomic daily collection grid`

## Done When

AC9 passes in API and local modes, widget behavior matches the approved grid, and injected failures prove zero partial postings.

## Handoff Update

Record endpoint shapes, hash format, concurrency mechanism, transaction tests, runtime request IDs, and balance before/after evidence.
