# Task 06: Share Customer Balances And Complete Integration Validation

## Outcome
Users can preview and share an individual customer's current receivable or a dated all-due-customer summary, and the complete feature passes migration, parity, build, and Android acceptance gates.

## Why This Task Exists
Covers AC-BAL-01, AC-BAL-02, and final AC-REGRESSION-01. It deliberately reuses current customer-list balances instead of adding redundant reporting APIs.

## Dependencies
Tasks 01-05 complete. `CustomersService.fetchCustomers`, profile service, navigation, and `share_plus` work in API/local modes.

## Repository Evidence
- `CustomerResponse.pending_balance` is ledger-derived by backend `customer_service._pending_balance_value`.
- `LocalCustomersService._pendingBalancesByCustomerId` provides the local equivalent.
- `mobile/lib/screens/customer_detail_screen.dart` displays individual balance.
- `mobile/lib/screens/customer_list_screen.dart` already loads all customers and balances.
- App dependencies already provide customer/profile services; sharing pattern exists from Task 05.

## Read Before Editing
Read customer model/service/local service, customer detail/list screens and tests, company profile service, navigation composition, and Task 05 sharing contract.

## Scope
- Create: `mobile/lib/services/balance_share_service.dart` (pure formatting plus injectable share handler) and focused tests.
- Modify: customer detail/list screens and app wiring to expose preview/share actions.
- Tests: formatter/service/widget tests for both modes/edge cases; integration and full-suite evidence.
- Docs/state: update README/agent docs for schema 9 and behavior, complete implementation log/state for Stage 4 handoff.

## Contracts And Invariants
- Individual message fields: seller name, customer name, `Pending balance: <two decimals>`, `As of: YYYY-MM-DD`, and polite payment reminder. Exclude GSTIN, address, phone, bank account, internal IDs, transaction history, and supplier data.
- Daily summary uses the current device-local calendar date as the label, one `fetchCustomers()` result, active customers with `pendingBalance > 0`, sorted case-insensitively by name, each amount at two decimals, and exact sum of included values.
- Zero and negative balances are excluded. Empty summary is `No pending customer balances as of <date>.` and remains shareable.
- “Day-wise” is a current dated balance snapshot, not today's transaction delta. Do not call ledger once per customer.
- Before OS sharing, show a modal/dialog preview with message text and explicit `Share`/`Cancel` actions.
- Individual action lives on customer detail. Daily action lives on customer list and shows loading/error/empty states.
- Sharing is user initiated and read-only. No logs of message bodies/customer values.
- API/local customer balance algorithms remain authoritative and unchanged.

## Implementation Guidance
1. Build deterministic pure formatters first, accepting profile name, date, and customer(s). Keep platform sharing behind an injected handler for tests.
2. Reuse `share_plus` text sharing (`Share.share`) or an abstraction compatible with Task 05; do not create files or backend endpoints for text summaries.
3. Fetch company profile and customers concurrently where safe in the list action; surface `ApiError`/network errors with existing error banner/snackbar patterns.
4. Use existing loaded customer detail where available to avoid a second balance query; refresh only through existing screen behavior.
5. Use `DateTime.now()` only at the UI boundary, convert to local `YYYY-MM-DD`, and pass date into formatter so tests are deterministic.
6. Update stale docs: backup schema 9, test counts only if measured, and explain GST/date/share behavior without claiming implementation before tests pass.

## Test-First Specification
- `balance_share_service_test.dart::formats_individual_current_balance_without_sensitive_fields`: exact included/forbidden content.
- `...::daily_summary_filters_non_positive_sorts_and_totals`: mixed balances and duplicate-like names; prevents invoice-only or unsorted output.
- `...::daily_summary_empty_is_shareable`: exact dated empty text.
- `customer_detail_screen_test.dart::previews_and_shares_individual_balance`: cancel causes no platform call; share causes one.
- `customer_list_screen_test.dart::previews_daily_all_due_summary`: loaded API-like list and exact total.
- Widget error test: customer/profile fetch failure shows error and no share call.
- Local/API parity fixture: same customer transaction set yields same displayed/shared balance.
- Regression: archived customer handling follows current fetch behavior; do not silently include records the service excludes.

## Validation Ladder
1. Red: new formatter/widget tests fail because actions/services do not exist.
2. Green: focused balance service and customer widget tests.
3. Run all customer, analytics, invoice, backup, service, local, and widget tests; then full `flutter test test` and backend PostgreSQL suite.
4. Run Drift generation cleanliness check, `flutter analyze`, and local release APK build.
5. End-to-end Android local-mode matrix:
   - configure non-GST seller; create/share 10-line A5 invoice;
   - configure GST seller; create/share taxable 11-line A4 invoice;
   - verify prohibited mode errors and date-only creation;
   - create customer debit/collection values, share individual exact balance;
   - share daily positive-only summary and empty state;
   - cancel an invoice and verify marked PDF plus corrected balance;
   - restart app and confirm persisted flags/details.
6. Proves AC-BAL-01, AC-BAL-02, and final AC-REGRESSION-01; re-confirms all earlier ACs.

## Review Checklist
- Canonical balance source, no N+1 ledger requests.
- Positive-only filter and exact total.
- Local date deterministic in tests.
- Preview/cancel privacy behavior.
- No supplier terminology or data.
- README/agent schema versions corrected.
- Full tests/build/runtime evidence recorded honestly.

## Allowed Adaptation
Place daily action in app bar or an accessible overflow action based on existing screen layout. Reuse a shared text-share adapter if Task 05 created one; preserve separate formatter responsibility.

## Stop And Escalate If
- Customer list API/local results differ materially in whether archived customers are returned.
- Double precision causes a visible total mismatch; introduce/use the repository's canonical decimal-string representation rather than rounding ad hoc.
- Full backend suite cannot run after three documented environment recovery attempts; hand to Stage 4 as blocked, not production-ready.
- Runtime share preview exposes sensitive fields not in the approved contract.

## Commit Checkpoint
Suggested: `feat: share customer pending balance summaries`

## Done When
Individual/daily previews and sharing work in tests and Android local mode, exact balances match canonical ledgers, all blocking acceptance evidence is recorded, docs reflect schema 9, and Stage 4 receives a coherent green or honestly blocked repository.

## Handoff Update
Complete `03-implementation-log.md` with commit range, per-task files, commands/results, migration/runtime evidence, deviations, and unresolved failures. Update `STATE.md` to Stage 3 complete only if implementation is complete; set next owner to Stage 4 fresh SLM and point it to the validation instructions. Do not claim production readiness from mocked tests alone.
