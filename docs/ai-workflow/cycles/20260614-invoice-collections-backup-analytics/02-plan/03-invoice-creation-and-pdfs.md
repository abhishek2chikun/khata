# Task 03: Deliver Searchable Invoice Entry And Correct Documents

## Outcome

Make invoice creation efficient for the full catalog, remove irrelevant non-GST controls, expose truthful Cash/Credit settlement, and produce aligned GST/non-GST PDFs using stored HSN and approved precision.

## Why This Task Exists

The current all-products dialog is unusable at catalog scale and the PDF/UI expose internal or irrelevant tax/payment/discount details.

## Dependencies

Task 02 contracts are merged into the feature branch and reviewed.

## Repository Evidence

- `widgets/product_picker.dart`: `SimpleDialog` with every product.
- `screens/create_invoice_screen.dart`: payment-state dropdown and always-visible line/bulk GST controls.
- `state/invoice_draft_controller.dart`, `models/invoice_draft.dart`: invoice draft/payment/item state.
- `screens/invoice_preview_screen.dart`: internal payment-state labels.
- `services/invoice_pdf_service.dart`: tax regime, decimal quantities, discount columns/totals, HSN/item-number behavior, adaptive A5/A4 renderer.
- Existing tests: create/preview/detail/list widgets, controller, invoice services, PDF service.

## Read Before Editing

- Design sections: Invoice HSN/Discount/Payment; Failure; Scenario Matrix.
- Task 02 public DTOs and precision helpers.

## Scope

### Change

- Replace `ProductPicker` with a searchable modal/page using a text field and lazily built list.
- Case-insensitive match over item name, item number, company, and HSN; trim query; empty query shows an initial bounded/recent or alphabetic list without constructing 1,199 dialog children at once.
- Result rows show item name primary, company/item number secondary, and HSN only when present. Selection closes and populates three-decimal selling price.
- Non-GST mode hides each GST-rate field and the bulk apply-GST control. Switching GST off clears line overrides through controller state and requotes.
- Replace payment-state dropdown with Cash/Credit control:
  - Cash has no paid-amount input and resolves full payment after quote.
  - Credit shows optional `Amount received`; blank/zero means unpaid, positive below total means partial.
  - Reject negative, over-total, or equal-total Credit amount; equal-total guidance says use Cash.
- Remove discount editing from all creation/preview paths and always submit zero.
- Preview/detail/list show `Cash` or `Credit`, never raw internal payment-state values. Do not add invoice-list search.
- PDF GST table uses `product_hsn_code` only. Non-GST table omits HSN and all GST columns.
- Remove tax regime, normal status/payment-state labels, and new-invoice discount columns/totals.
- Preserve `CANCELED` watermark. A historical invoice whose stored `discount_total` is greater than zero must always include a compact discount summary row, without restoring the new-invoice discount column.
- Quantity text is integer for integral new records; legacy fractional quantity uses a trimmed decimal fallback rather than misleading rounding.
- Unit prices render exactly three decimals; currency totals remain two.
- Widen serial-number column for at least `1..99`, disable wrapping, and tune remaining widths. Preserve <=15-row A5 candidate plus actual-fit fallback to A4.

### Preserve

- Customer/date/place-of-supply flow, stock checks, quote-before-create, snapshot authority, sharing, four PDF variants, and adaptive page selection.

### Explicitly Out Of Scope

- Invoice-list search, new discount capability, multilingual font work, batch collections.

## Contracts And Invariants

- UI never supplies HSN as authoritative input.
- Non-GST draft cannot retain hidden non-zero GST overrides.
- Cash/Credit mapping is deterministic and covered in controller and service tests.
- PDF uses persisted snapshot fields only.
- Historical canceled/discounted documents remain truthful.

## Implementation Guidance

- Keep state in `InvoiceDraftController`; avoid introducing a new state-management framework.
- Search locally over the already-fetched active product list for this 1,199-row target. Use `ListView.builder`; debounce is optional because filtering 1,199 normalized strings is bounded.
- Cache a normalized search string per product in the picker state if widget tests show rebuild cost.
- Extract PDF table-column specs per page size/tax mode instead of scattered indices.
- Add semantic labels for search, result count, payment mode, amount received, and validation messages.

## Test-First Specification

- Picker test with 1,199 products: no eager 1,199 option widgets, matches each approved field, no-result state, selection.
- Create-screen tests: non-GST controls absent, switch clears overrides, GST controls return when enabled.
- Controller tests for Cash, unpaid Credit, partial Credit, equal/over-total errors, zero discounts, integer quantities, three-decimal payloads.
- API/local paired quote/create tests for payment/ledger results.
- PDF tests extract text/layout metadata for GST HSN presence, non-GST HSN/GST absence, no tax regime/status/new discount, canceled watermark, serial `10`/`11` on one line, integer quantity, three-decimal price, legacy fractional/discount fixture.
- Generate rendered artifacts for GST/non-GST 15-row A5 and 16-row A4 plus verbose fallback.

## Validation Ladder

```bash
(cd mobile && flutter test test/widgets/create_invoice_screen_test.dart test/widgets/invoice_preview_screen_test.dart test/state/invoice_draft_controller_test.dart)
(cd mobile && flutter test test/services/invoice_pdf_service_test.dart test/widgets/invoice_detail_screen_test.dart test/widgets/invoice_list_screen_test.dart)
(cd mobile && flutter test test/local/local_invoices_service_test.dart test/services/invoices_service_test.dart)
PYTHONPATH=backend .venv/bin/python -m pytest backend/pure_tests/test_invoice_v2_domain_pure.py -q
BILLING_DATABASE_URL='postgresql+psycopg://khata:khata@localhost:55432/internal_billing_test' PYTHONPATH=backend .venv/bin/python -m pytest backend/tests/api/test_invoice_create_api.py backend/tests/services/test_invoice_service.py -q
(cd mobile && flutter analyze)
```

Runtime evidence: type product-name/item-number/company/HSN searches on emulator/device, create Cash/Credit GST/non-GST invoices, inspect four rendered PDFs.

## Review Checklist

- [ ] Search is lazy and accessible.
- [ ] Non-GST has no hidden tax state.
- [ ] Cash/Credit and ledger math agree.
- [ ] No raw internal status labels leak.
- [ ] PDF snapshots/precision/layout correct.
- [ ] Historical documents still reconcile.

## Allowed Adaptation

Modal vs full-screen picker may follow responsive Flutter conventions, but search fields and lazy result behavior are fixed. PDF widths may be tuned from rendered evidence without changing content policy.

## Stop And Escalate If

- Cash cannot resolve paid amount without a second quote/create race; redesign must keep one authoritative total.
- Historical discounted invoices cannot reconcile after removing columns.
- A5 readability requires changing the approved page-selection rule.

## Commit Checkpoint

`feat(invoices): add searchable entry and compliant pdfs`

## Done When

AC5-AC8 focused tests and rendered review pass, with API/local settlement parity and no invoice-list search added.

## Handoff Update

Record search fixture size/timing, payment scenarios, PDF artifact paths/page counts, historical fixture behavior, and any layout thresholds in the implementation log.
