# Implementation Log

## Workflow Summary

Baseline SHA: `837ccbc0cfdb09a25b6aad02e4b0c357abafa8a6`
Current HEAD: `47c6700cceaff6df80237d7c821c4d4ef03c9210`
Integration target branch: `main`
Feature branch: `codex/khata-invoice-collections-backup-analytics`
Worktree name/ID: `khata_app-upgrade`
Canonical worktree path: `/Users/abhishek/python_venv/khata_app-upgrade`
Merge status: not-started
Assigned tasks: 01-07 (full plan)

## Task Evidence

| Slice | Status | Implementation evidence | Verification evidence | Deviations/blockers |
|---|---|---|---|---|
| Platform feasibility | complete | Task 01 merged at `d12306c` | prior ladder green | none |
| Contracts/migrations/catalog | complete | Task 02 merged at `d12306c` | prior ladder green | none |
| Invoice creation/PDF | complete | searchable `ProductPicker`, Cash/Credit UX, compliant PDFs | 71 focused tests green; `flutter analyze` info-only | PDF text assertions use helper/metadata tests (compressed PDF bytes are not plain-text searchable) |
| Batch collections | pending | pending | pending | none |
| Drive backup | pending | pending | pending | External OAuth configuration cannot be committed |
| Analytics | pending | pending | pending | none |
| Integration/release | pending | pending | pending | Physical-device evidence depends on available configured device/account |

### Task 03 — Invoice creation and PDFs (2026-06-14)

**Search / entry**
- Replaced `SimpleDialog` with searchable modal (`productSearchField`, `ListView.builder`, cached normalized strings).
- Empty query shows first 50 alphabetically sorted products; 1,199-product fixture builds <60 `ListTile` widgets (no eager 1,199 children).
- Match fields: item name, item number, company, HSN (case-insensitive trim).

**Cash / Credit**
- UI: `SegmentedButton` Cash/Credit; optional `amountReceivedField` on Credit only.
- Controller maps Cash → `TOTAL_PAID` + grand-total paid amount after quote; Credit unpaid/partial with validation (negative, equal/over-total rejected).
- Preview/detail/list show `Cash` or `Credit` via `invoiceSettlementLabel`; no raw `TOTAL_PAID` / `PARTIAL_PAID` labels.

**Non-GST / precision**
- GST line fields and bulk apply hidden when `gstFlag` false; switching off clears line GST overrides.
- Unit prices use three-decimal canonical strings; quantities integral on new drafts.
- Discount editing removed from creation/preview; payload always zero discount.

**PDF policy**
- GST table uses `productHsnCode` snapshot; non-GST omits HSN and all GST columns.
- Removed tax regime, status, and per-line discount columns; historical `discount_total > 0` keeps compact totals-row discount.
- Integer quantity display, 3dp unit prices, widened serial column (`FixedColumnWidth(18)`), A5≤15 / A4>15 preserved.

**Focused verification (Task 03)**
```bash
(cd mobile && flutter test test/widgets/product_picker_test.dart test/widgets/create_invoice_screen_test.dart test/state/invoice_draft_controller_test.dart test/services/invoice_pdf_service_test.dart test/widgets/invoice_preview_screen_test.dart test/widgets/invoice_detail_screen_test.dart test/widgets/invoice_list_screen_test.dart)
(cd mobile && flutter analyze)
```
Result: **71 passed**, analyze info/warnings only (no new errors).

**Files touched (summary)**
- New: `mobile/lib/services/invoice_settlement.dart`, `mobile/test/widgets/product_picker_test.dart`
- Updated: `product_picker.dart`, `create_invoice_screen.dart`, `invoice_draft_controller.dart`, `invoice_draft.dart`, `invoice_preview_screen.dart`, `invoice_detail_screen.dart`, `invoice_list_screen.dart`, `invoice_pdf_service.dart`, `invoice_detail.dart`, `local_invoices_service.dart`, 6 test files, this log, `STATE.md`

## Acceptance Evidence

| AC | Status | Evidence |
|---|---|---|
| AC5-AC8 (invoice entry/PDF/settlement) | complete | 71 focused tests; helper PDF layout tests; Cash/Credit label coverage |
| AC1-AC4, AC9-AC14 | pending | later tasks |
