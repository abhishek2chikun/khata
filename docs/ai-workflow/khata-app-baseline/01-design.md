# Design: GST And Non-GST Invoices, Adaptive PDFs, And Balance Sharing

## Verdict
proceed

## Objective And User Outcome
Enable a wholesaler using the mobile app, especially in local mode, to create legally and financially distinct GST or non-GST invoices, avoid the invoice timezone blocker, generate polished A5/A4 PDFs, and share invoices or customer receivable summaries through Android sharing/WhatsApp.

## Current-State Evidence
- Invoice quote/create exists in API and Drift local modes with shared mobile service boundaries.
- Invoice requests currently accept both `invoice_date` and `invoice_datetime`; timezone-naive datetimes are rejected.
- Invoice totals always use product/line GST and PDFs always say `TAX INVOICE`, show GST fields, and use A4.
- Company profiles and invoice snapshots contain optional GSTIN but no seller/invoice GST mode.
- Invoice sharing currently attaches a PDF through `share_plus`, while the direct WhatsApp action only opens `wa.me` and does not attach the PDF.
- Customer list/detail responses already expose ledger-derived `pending_balance` in both modes.

## Problem Definition
The owner needs documents whose tax treatment, displayed identity, calculation, size, and sharing behavior match the actual sale. The current PDF can misrepresent non-GST sales, date handling can block creation, all invoices consume A4, and balance collection messages require manual composition.

The smallest complete version is an end-to-end seller/invoice GST mode with immutable invoice snapshots, date-only mobile creation, four PDF variants, attached-PDF sharing, and two customer-balance text formats. A visual-only GST toggle would fail the real goal because ledger totals and document totals could disagree with displayed tax.

## Scope
- Seller-level `gst_flag` in company profile and immutable invoice-level `gst_flag`.
- GST/non-GST quote and create behavior in API and local modes.
- Date-only mobile invoice flow while preserving legacy backend datetime compatibility.
- GST/non-GST PDF templates with A5 as the paper-saving candidate for at most 15 lines; retain A5 only when the complete invoice fits one page, otherwise use A4. More than 15 lines uses A4 directly.
- Attached invoice PDF plus formatted caption via the system share sheet.
- Individual customer receivable sharing and current-day all-due-customer summary sharing.
- Backend/local schema alignment, migrations, backup version bump, tests, and operational docs.

## Non-Goals
- GST return filing, IRN/e-invoicing, e-way bills, tax advice, or automatic legal classification of products.
- Arbitrary non-GST invoices for taxable lines by a regular GST seller.
- Supplier/buyer payable sharing.
- Cloud sync, Google Drive completion, background delivery, or direct WhatsApp Business API integration.
- Removing the persisted legacy `invoice_datetime` column in this release.

## Canonical Glossary
- **GST seller:** active company profile has `gst_flag=true` and a non-empty GSTIN.
- **Non-GST seller:** active company profile has `gst_flag=false`; GSTIN must be absent.
- **GST invoice:** invoice has `gst_flag=true`, computes tax, and renders a `TAX INVOICE`.
- **Non-GST invoice:** invoice has `gst_flag=false`, computes zero tax, and omits GST-specific identity and columns.
- **Customer:** retail shop/person owing receivables. This is the balance-sharing target.
- **Buyer:** supplier/vendor. Buyer payables are outside this feature.
- **Line count:** number of invoice item rows, not summed quantity.

## Confirmed Facts, Assumptions, Unknowns, Contradictions
- Confirmed: the user approved genuinely tax-free non-GST documents, not hidden GST.
- Confirmed: balance sharing targets customers and the daily format lists all customers with positive current balances.
- Confirmed: primary WhatsApp experience is PDF attachment through the Android share sheet.
- Assumption: for a non-GST seller, stored product GST metadata is ignored and effective invoice GST is forced to zero because the seller cannot collect GST.
- Assumption: a GST seller may select non-GST only when every selected line resolves to a zero GST rate.
- Assumption: `gst_flag` defaults from the active seller profile for each new draft and remains immutable after creation.
- Contradiction recovered from Stage 0: Stage 0 had no feature request and was partial; this design supplies the missing objective.
- Unknown but non-blocking: exact printer hardware; standard A5/A4 PDF dimensions are used.

## Options Considered
1. **Template-only GST toggle:** cheapest, but financially misleading because tax remains in totals. Rejected.
2. **Invoice-level calculation mode with seller policy and immutable snapshots:** preserves accounting integrity and supports both modes. Selected.
3. **Separate GST and non-GST invoice domains/tables:** strong isolation but duplicates quote/create/cancel logic and migrations. Rejected as unnecessary.

## Recommended Approach And Tradeoffs
Extend the existing invoice domain with one boolean policy field rather than fork it. Company profile controls allowed defaults; invoice `gst_flag` controls effective calculation and is persisted/snapshotted. Reuse existing services and ledger side effects. This adds migrations and broad tests, but avoids divergent tax and accounting paths.

## Architecture And Responsibility Boundaries
- Company profile services validate seller GST configuration and expose the default/allowed invoice mode.
- Invoice draft/controller owns the selected mode for a pending invoice.
- Backend and local invoice services enforce policy, normalize effective tax, calculate totals, hash idempotency input, persist snapshots, and apply unchanged stock/ledger side effects.
- PDF service renders from immutable invoice detail only; it never re-reads current company settings.
- Invoice share service attaches the rendered PDF and caption through `share_plus`.
- Customer balance share formatter consumes existing customer balances plus company identity; it performs no writes.

## Contracts, Types, State, And Data Flow
- Company profile request/response/model/table add required boolean `gst_flag`, defaulting to `false` for new profiles.
- Invoice quote/create requests add required boolean `gst_flag` in new mobile clients. Backend accepts omitted value only for compatibility and resolves it to the active company profile value.
- Quote/detail/list responses expose `gst_flag`; invoice table stores it as non-null.
- Idempotency request hash includes resolved `gst_flag`.
- GST seller + GST invoice: existing tax normalization remains unchanged.
- GST seller + non-GST invoice: allowed only when every requested/product-resolved GST rate is zero; otherwise `NON_GST_TAXABLE_LINES` validation error.
- Non-GST seller + GST invoice: rejected as `GST_INVOICE_NOT_ALLOWED`.
- Non-GST seller + non-GST invoice: effective GST rates/amounts are zero; entered or product selling price is treated as the final unit price.
- Mobile sends `invoice_date` only. Backend/local persistence derives UTC midnight `invoice_datetime` for compatibility.
- Existing timezone-aware `invoice_datetime` API requests remain supported; timezone-naive values remain invalid.

## Persistence/Migration/Compatibility
- Add backend Alembic `0009` with `company_profiles.gst_flag` and `invoices.gst_flag`.
- Backfill company profile true when trimmed GSTIN is present, false otherwise.
- Backfill invoice true when seller snapshot GSTIN is present or GST total is non-zero, false otherwise.
- Add equivalent Drift columns, raise schema version 8 to 9, and regenerate `local_database.g.dart`.
- Raise encrypted backup schema 8 to 9; retain backend compatibility label `local-v2` because the mapping remains additive. Version-8 backup packages continue to fail closed under the existing exact-version rule.
- Do not rewrite old invoice amounts or snapshots.

## Failure, Recovery, And Fallback Behavior
- Invalid seller GST configuration blocks profile save and invoice creation with an actionable validation message.
- Invalid invoice mode/line combinations fail quote before create and repeat identically at create.
- PDF/share failure leaves invoice, stock, and ledgers unchanged and allows retry.
- Missing customer phone does not block system PDF sharing or balance text sharing.
- Empty daily due list produces a shareable `No pending customer balances` message.
- Canceled invoices render with a prominent `CANCELED` marker.

## Security And Privacy
- Sharing is user initiated and shows a preview/confirmation surface before invoking the OS share sheet.
- Do not log message bodies, GSTINs, bank accounts, phone numbers, or generated PDF contents.
- Existing authentication boundaries remain unchanged; no public sharing links are introduced.

## Performance, Cost, And Scalability
- PDF generation remains on device and linear in line count.
- Daily balance summary reuses one customer-list query and sorts positive balances; no per-customer API fan-out.
- No external paid service or network dependency is added.

## Observability, Deployment, Rollout, And Rollback
- Validation errors use existing API/local `ApiError` behavior and stable codes.
- Deploy backend migration before an API-mode mobile build that sends `gst_flag`.
- Local app migration runs before service use; backup version changes with the schema.
- Roll back application code only after database downgrade when required; downgrade drops additive flags but cannot preserve newly created non-GST semantics in an old renderer, so production rollback must stop new writes first.

## Scenario Matrix
| Scenario | Expected behavior | Evidence | Launch blocking? |
|---|---|---|---|
| Non-GST seller creates default invoice | Zero tax, non-GST snapshot/PDF, unchanged stock/ledger transactionality | API/local service and PDF tests | Yes |
| Non-GST seller requests GST | Reject `GST_INVOICE_NOT_ALLOWED` | Negative service tests | Yes |
| GST seller invoices taxable lines | Existing GST calculation and tax invoice retained | Regression tests | Yes |
| GST seller selects non-GST with taxable line | Reject `NON_GST_TAXABLE_LINES` at quote/create | Negative tests | Yes |
| GST seller selects non-GST with zero-rate lines | Zero-tax non-GST invoice succeeds | API/local integration tests | Yes |
| Date-only request | Persist UTC-midnight compatibility datetime; no timezone error | API/local request tests | Yes |
| Legacy aware datetime request | Still accepted when date matches | Backend compatibility test | Yes |
| Standard 15/16 line invoice | One-page A5/A4 respectively; verbose <=15-line content falls back to A4 | Parsed PDF dimensions/page count plus rendered review | Yes |
| PDF share | Attachment and formatted caption reach share handler | Share service/widget tests | Yes |
| Individual balance | Current ledger-derived balance included | Formatter/widget tests | Yes |
| Daily balances | Positive balances only, sorted, accurate total | API/local-backed formatter tests | Yes |
| Empty daily balances | Shareable empty-state message | Unit/widget test | No |
| Canceled invoice | PDF visibly marked canceled | PDF text test | Yes |
| Legacy data upgrade | Existing rows receive deterministic flags without amount changes | Migration tests | Yes |

## Acceptance Criteria
| ID | Required outcome | Proof | Blocking? |
|---|---|---|---|
| AC-GST-01 | Seller defaults and allowed invoice modes match the policy in both modes | Backend API/service and Flutter local/widget tests | Yes |
| AC-GST-02 | Non-GST invoices have zero tax and omit GST-specific PDF content | Calculation assertions plus parsed PDF text | Yes |
| AC-DATE-01 | Mobile date-only quote/create never triggers timezone validation | API/local/service/widget tests | Yes |
| AC-PDF-01 | Standard 15-line invoices use one-page A5, 16-line invoices use one-page A4, and overflowing <=15-line invoices fall back to A4 in both tax modes | PDF page dimension/page-count assertions | Yes |
| AC-PDF-02 | Four variants are readable and contain correct totals/status | PDF text/layout tests and manual rendered review | Yes |
| AC-SHARE-01 | Invoice sharing sends PDF and formatted caption through OS sharing | Handler and widget tests plus Android runtime | Yes |
| AC-BAL-01 | Individual message equals canonical customer pending balance | Formatter and customer-detail widget tests | Yes |
| AC-BAL-02 | Daily summary includes all and only positive customer balances with correct total | Formatter/service/widget tests | Yes |
| AC-COMPAT-01 | Legacy rows migrate and legacy aware-datetime API calls remain valid | Alembic/Drift migration and API tests | Yes |
| AC-REGRESSION-01 | Existing invoice, stock, ledger, cancellation, API/local parity remain green | Full backend/mobile suites and local Android smoke | Yes |

## Decisions Made
| Decision | Choice | Rationale | Rejected alternatives |
|---|---|---|---|
| Tax distinction | Calculation-level `gst_flag` | Prevent misleading documents/accounting | Template-only toggle |
| Seller policy | Non-GST cannot issue GST; GST non-GST only zero-rate | Approved safety/legal boundary | Arbitrary tax suppression |
| Date | Date-only mobile; legacy datetime retained | Removes blocker without destructive migration | Drop datetime column now |
| PDF size | `items.length <= 15` starts as A5 and remains A5 only if the complete document is one page; otherwise A4 | Saves half-sheet paper while preserving readable, complete invoices | Fixed 10/11 threshold; forcing dense A5 content; quantity-only selection |
| WhatsApp | Attached PDF via OS share sheet | Direct `wa.me` cannot attach local PDF | Chat-only deep link |
| Balance target | Customer receivables | Matches app terminology and approval | Buyer/supplier payables |
| Daily summary | All positive customer balances as of current local date | Useful collection list | One-customer daily statement |

## Decisions Requiring User Approval
None.

## Planning Constraints
- Preserve API/local parity and backend-aligned Drift names.
- Use existing ChangeNotifier/service patterns and `ApiError` envelope.
- Use test-first slices and regenerate Drift code only after schema edits.
- Do not claim legal compliance beyond the explicit product rules.

## What Stage 2 Must Not Invent
- Alternative GST eligibility rules, tax-inclusive conversion rules, size thresholds, sharing targets, or WhatsApp attachment mechanisms.
- New cloud services, public links, supplier sharing, or automatic messaging.
- Destructive removal of legacy datetime storage.

## Deferred Work
- Product-level exempt-supply classification beyond the existing numeric GST rate.
- Old backup-package migration tooling.
- Direct WhatsApp Business API integration and delivery receipts.
- Dedicated reporting/export history for shared balance summaries.
