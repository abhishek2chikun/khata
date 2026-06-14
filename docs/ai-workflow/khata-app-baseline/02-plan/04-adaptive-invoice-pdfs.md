# Task 04: Render Four Adaptive Invoice PDF Variants

## Outcome
Invoice PDFs render polished GST/non-GST documents using A5 for complete, readable one-page invoices of at most 15 item rows and A4 for overflow or more than 15 rows, with immutable snapshot content and visible cancellation state.

## Why This Task Exists
Covers AC-GST-02, AC-PDF-01, and AC-PDF-02. It follows canonical calculations and date-only UI so the renderer does not infer policy.

## Dependencies
Tasks 01-03. `InvoiceDetail.gstFlag` and canonical zero/GST totals are available.

## Repository Evidence
- `mobile/lib/services/invoice_pdf_service.dart:InvoicePdfService.generateInvoicePdf` is the sole renderer; it currently always uses `PdfPageFormat.a4`, `TAX INVOICE`, DateTime text, and GST tables.
- `mobile/test/services/invoice_pdf_service_test.dart` already creates files for intra/inter-state, minimal, discount, and payment cases.
- The `pdf` package is already installed; no new PDF dependency is needed.

## Read Before Editing
Read the entire PDF service, `InvoiceDetail`, PDF tests, and invoice detail screen generation path.

## Scope
- Modify/refactor: `invoice_pdf_service.dart` into shared shell plus GST/non-GST sections and adaptive format selection.
- Tests: expand `invoice_pdf_service_test.dart`; add only a small test utility for parsing PDF bytes/text/page dimensions if current package APIs require it.
- Docs/state: log rendered artifacts/manual review.

## Contracts And Invariants
- Page format starts as A5 for `items.length <= 15`; after rendering, retain it only when the complete document has one page. Overflow and `items.length > 15` use A4. Line quantity never affects selection.
- GST title is `TAX INVOICE`; non-GST title is `INVOICE` (use `BILL OF SUPPLY` only if product wording is consistently changed in UI/tests; do not vary dynamically).
- Never display `invoiceDatetime`; display `invoiceDate` only.
- GST variant includes seller/customer GSTIN when present, place of supply, tax regime, HSN/item number, GST rate, CGST/SGST or IGST, taxable and GST totals.
- Non-GST variant omits all GSTIN labels/values, place-of-supply/tax-regime block, GST/CGST/SGST/IGST columns/rows, and GST total. It may show item code but must not label it HSN unless a separate HSN field exists.
- Both variants show seller/customer identity, invoice number/date, item rows, quantities, final rates, discounts, line totals, subtotal/grand total, amount in words, payment state, paid amount, balance due, notes, bank details, and signature space.
- Canceled invoices show a prominent `CANCELED` marker on every page or header area that repeats across pages.
- Render only persisted invoice snapshots; never fetch current profile/customer data.
- Long content may span multiple pages of the selected size without clipping; header/footer should remain legible.

## Implementation Guidance
1. Add tests for title, omitted/present tax strings, date-only text, page format threshold, totals, and canceled marker before refactor.
2. Keep one `pw.MultiPage` shell. Select `pageFormat` once and compose mode-specific widgets; avoid four copied templates.
3. Create explicit helpers such as `_buildDocumentHeader`, `_buildPartyInfo`, `_buildGstSupplyInfo`, `_buildItemTable`, `_buildTotals`, with `gstFlag` controlling columns only at the composition boundary.
4. Tune margins/font sizes separately for A5 versus A4 via a small layout configuration object/constants; do not reduce A5 below readable text merely to force one page.
5. Preserve file naming compatibility `invoice_<number>.pdf`; sanitize only if current invoice numbers can contain unsafe characters (currently numeric/string snapshots).
6. Produce four sample PDFs plus canceled/long examples in a temporary evidence directory for manual review; do not commit generated PDFs unless workflow policy requests evidence artifacts.

## Test-First Specification
- `uses_a5_for_standard_15_item_rows_in_gst_and_non_gst_modes`: parse media box dimensions. Prevents wasteful default-A4 output.
- `falls_back_to_a4_when_verbose_content_does_not_fit_one_a5_page`: use long names/addresses/notes. Prevents clipping or multi-page A5 output.
- `uses_one_page_a4_for_16_standard_rows`: assert A4 media box and one page. Prevents wasting a second sheet for the first full-page tier.
- `uses_a4_for_11_item_rows_in_gst_and_non_gst_modes`: same.
- `gst_pdf_contains_tax_invoice_and_tax_components`: assert extracted text includes title/GSTIN/CGST-SGST or IGST/tax total.
- `non_gst_pdf_omits_all_gst_specific_content_and_keeps_grand_total`: assert forbidden terms and seller/customer GSTIN values absent. Prevents visual hiding bugs.
- `pdf_displays_invoice_date_but_not_invoice_datetime`: prevents blocker detail leaking into document.
- `canceled_invoice_contains_prominent_canceled_marker`.
- `long_a5_and_a4_documents_generate_without_exception_and_have_all_item_names`: catches clipping/dropped rows.
- Keep and update existing discount, partial payment, minimal, and interstate tests.

## Validation Ladder
1. Red: focused PDF tests fail on A4-only/GST-only/current datetime behavior.
2. Green: `cd mobile && flutter test test/services/invoice_pdf_service_test.dart`.
3. Run invoice model/service/detail widget tests.
4. Formatter/analyzer and local release build smoke if PDF package behavior differs in release mode.
5. Render four canonical PDFs and inspect page size, readability, totals, tax omission/presence, long rows, and canceled marker at 100% zoom/print preview.
6. Proves AC-GST-02 PDF portion, AC-PDF-01, AC-PDF-02.

## Review Checklist
- One shared renderer, no four-way duplication.
- A5 candidate cap of 15, actual one-page fit guard, and item-row definition.
- Forbidden tax content absent from non-GST bytes/text.
- Snapshot-only data and correct totals.
- Multi-page readability, no clipped totals/signature.
- Canceled state unmistakable.

## Allowed Adaptation
Use available PDF parsing APIs or a lightweight test-only parser already transitively available. If text extraction is not available, expose deterministic renderer metadata for tests plus manual artifact review; page-size and forbidden-content proof must still be strong.

## Stop And Escalate If
- The `pdf` package cannot reliably expose/test page dimensions or text and no non-production test seam can prove them.
- A5 GST tables are unreadable even across multiple pages without dropping required columns.
- Existing invoice snapshots lack a field the design requires; do not fetch live data to compensate.

## Commit Checkpoint
Suggested: `feat: render adaptive gst and non-gst invoice pdfs`

## Done When
Automated threshold/content tests pass, all four artifacts and canceled/long cases receive visual review, and no current invoice regression is observed.

## Handoff Update
Log sample inputs, generated artifact locations (temporary), visual findings, page dimensions, and test results. Mark the PDF strong-review gate complete in `STATE.md`.
