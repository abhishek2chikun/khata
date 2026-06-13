# Task 03: Make The Mobile Invoice Flow Policy-Aware And Date-Only

## Outcome
Users configure seller GST status, new invoice drafts default correctly, invalid mode choices are prevented or explained, and mobile quote/create payloads send date only without the timezone blocker.

## Why This Task Exists
Covers AC-GST-01 and AC-DATE-01 at the mobile workflow boundary. It consumes canonical Task 02 behavior and keeps the SLM from embedding policy only in UI.

## Dependencies
Tasks 01-02 complete. `CompanyProfileService`, `InvoiceDraftController`, and invoice services expose the new fields.

## Repository Evidence
- `mobile/lib/screens/company_profile_screen.dart:_CompanyProfileScreenState` owns profile edit/load/save.
- `mobile/lib/services/company_profile_service.dart:UpsertCompanyProfileInput` and local/API implementations share the profile contract.
- `mobile/lib/models/invoice_draft.dart:InvoiceDraft` currently contains both `invoiceDate` and `invoiceDatetime`.
- `mobile/lib/state/invoice_draft_controller.dart` owns draft mutation, quote, create, and request-id reset.
- `mobile/lib/screens/create_invoice_screen.dart` and `invoice_preview_screen.dart` are existing interaction/tests seams.
- Backend `InvoiceQuoteRequest` already derives UTC midnight from `invoice_date` and accepts aware legacy datetimes.

## Read Before Editing
Read the files above, `mobile/lib/services/invoices_service.dart`, app dependency/main screen construction, and focused profile/draft/create/preview tests.

## Scope
- Modify: company profile model/input/screen and both profile implementations; invoice draft/controller/API serialization; create and preview screens; app composition only where required to supply the loaded profile default.
- Tests: profile API/local/widget, invoice service payload, controller, create/preview widgets, and backend date compatibility tests.
- Docs/state: implementation log and task status.

## Contracts And Invariants
- Profile UI exposes an accessible `GST registered seller` switch.
- Switch off disables and clears GSTIN before save; switch on requires non-empty GSTIN client-side and server/local validation remains authoritative.
- New profile defaults non-GST. Existing migrated profile loads its flag.
- New draft initializes `gstFlag` from the active profile, not merely from GSTIN text.
- Non-GST seller sees non-GST mode fixed with explanatory text; GST seller can choose GST or non-GST.
- When GST seller chooses non-GST and selected lines have non-zero resolved rates, quote surfaces `NON_GST_TAXABLE_LINES` through the existing quote error area. Do not duplicate product-rate eligibility logic in the widget.
- Remove invoice time inputs/displays. Keep one date picker and serialize `invoice_date: YYYY-MM-DD`; omit `invoice_datetime` entirely from mobile quote/create JSON.
- Remove `invoiceDatetime` from mobile draft state if no other live mobile contract requires it. Keep response `InvoiceDetail.invoiceDatetime` only for legacy parsing/internal compatibility, never display it.
- Draft changes to date or GST mode invalidate quote and request ID through existing controller behavior.
- Payment, item, stock warning, customer, notes, and place-of-supply behavior remain unchanged for GST mode.

## Implementation Guidance
1. Start with service/controller/widget tests that inspect exact JSON keys and visible controls.
2. Thread profile into invoice-draft construction through existing app composition. Prefer passing a loaded/default mode through screen/controller construction over adding global state.
3. Add `setGstFlag(bool)` to `InvoiceDraftController`; rely on `_updateDraft` for quote/idempotency invalidation.
4. Use stable keys for tests: `companyGstFlagSwitch`, `invoiceGstFlagSwitch`, `invoiceDateField`.
5. In preview, label document type (`GST invoice` / `Non-GST invoice`) and omit tax rows for non-GST or show GST as zero only if layout consistency requires it; PDF rules remain Task 04.
6. Add backend compatibility tests: date-only accepted/derived; aware datetime accepted; naive datetime rejected; supplied date mismatch rejected. Do not weaken timezone validation for legacy datetime input.

## Test-First Specification
- `company_profile_screen_test.dart`: switch-off clears/disables GSTIN; switch-on without GSTIN blocks save; loaded values round-trip. Prevents inconsistent profiles.
- `company_profile_api/local tests`: invalid combinations return `INVALID_GST_PROFILE` after Task 02 validation wiring.
- `invoices_service_test.dart::date_only_payload_omits_invoice_datetime`: inspect quote/create JSON. Prevents timezone regression.
- `invoice_draft_controller_test.dart::gst_mode_change_invalidates_quote_and_request_id`: prevents stale quote/idempotent replay.
- `create_invoice_screen_test.dart`: non-GST seller fixed default; GST seller toggle; date picker only; no time label/control.
- `invoice_preview_screen_test.dart`: correct mode/tax presentation and service errors visible.
- Backend API `test_date_only_invoice_uses_utc_midnight_and_legacy_aware_datetime_still_works` plus naive/mismatch negatives.
- Local service date-only test ensures stored `invoiceDatetime` is `<date>T00:00:00.000Z` (or canonical equivalent) without accepting naive arbitrary timestamps.

## Validation Ladder
1. Red: run focused profile, service payload, controller, and widget tests.
2. Green: `cd mobile && flutter test` with explicit focused file list; backend focused date API tests.
3. Run all mobile invoice/profile/service/widget tests and backend invoice API/schema tests.
4. `dart format --output=none --set-exit-if-changed` after formatting changed files; `flutter analyze` and relevant Python tests.
5. Manual local-mode flow: configure non-GST seller, create invoice for selected date; configure GST seller, create GST zero/nonzero cases; observe no time field/error.
6. Proves AC-GST-01 UI/default portion and AC-DATE-01.

## Review Checklist
- UI defaults derive from persisted flag.
- Invalid combinations blocked in domain, not UI only.
- No mobile request includes `invoice_datetime`.
- Legacy backend compatibility tests remain.
- Accessible labels/keys and loading/error states exist.
- Existing payment and quote warning flows remain intact.

## Allowed Adaptation
If screen construction cannot synchronously load profile, add a small loading state/factory at the existing dependency boundary. Do not introduce a new state-management package.

## Stop And Escalate If
- Active profile is not available before invoice draft creation and the only solution would duplicate profile persistence or add global mutable state.
- Removing draft datetime breaks a documented external mobile contract beyond repository tests.
- Backend date conversion produces a date shift under existing API semantics.

## Commit Checkpoint
Suggested: `feat: add seller gst controls and date-only invoices`

## Done When
Profile/draft/create/preview behavior is accessible and tested, mobile payloads are date-only, legacy backend datetime behavior is explicitly covered, and focused/full related suites pass.

## Handoff Update
Log JSON payload evidence, UI defaults, compatibility tests, runtime date used, and results. Mark Task 03 complete and Task 04 next in `STATE.md`.
