# Task 05: Share The Attached Invoice PDF With A Formatted Caption

## Outcome
The invoice detail flow creates the correct PDF and invokes the Android/system share sheet with both attachment and a useful caption, so the user can choose WhatsApp without a misleading chat-only action.

## Why This Task Exists
Covers AC-SHARE-01 and the approved WhatsApp behavior. It depends on Task 04 because the attachment must be the final variant.

## Dependencies
Task 04 complete. Existing `share_plus` dependency and invoice detail PDF cache path remain available.

## Repository Evidence
- `mobile/lib/services/invoice_share_service.dart` currently uses `Share.shareXFiles` for generic share and `wa.me` for direct WhatsApp without attachment.
- `mobile/lib/screens/invoice_detail_screen.dart:_sharePdf, _doShareWhatsApp, _doShareSystem` owns the share sheet and generated PDF caching.
- Existing service/widget tests capture file/text and action visibility.

## Read Before Editing
Read the share service, invoice detail screen, PDF service, invoice detail model, and both sharing test files.

## Scope
- Modify: invoice share interface/implementation and invoice-detail share actions.
- Tests: share service and invoice-detail widget tests.
- Docs/state: implementation log and runtime evidence.

## Contracts And Invariants
- One primary action, labeled clearly such as `Share PDF (WhatsApp and more)`, calls system sharing with the generated PDF and formatted caption.
- Caption includes seller name, document type, invoice number/date, customer name, grand total, paid amount/balance due when relevant, and a polite short note. It must not include bank account, GSTIN, address, internal IDs, or product-level details.
- Direct `wa.me` invoice action is removed because it cannot attach the local PDF. Retain the existing SMS action as a separate text-only contact option, label it `Send SMS`, and do not present it as carrying the PDF.
- Missing phone/WhatsApp number never hides or disables system PDF sharing.
- Generate/cache failure and share failure show a user-visible error and permit retry; no invoice/ledger writes occur.
- Sharing is always user initiated; no automatic send, delivery claim, or success claim beyond handing off to OS.
- Do not log caption, file contents, phone, or sensitive invoice data.

## Implementation Guidance
1. Replace file-path-only share API with a contract accepting path plus caption, e.g. `shareInvoicePdf(String filePath, {required String text})`.
2. Keep handler factory testability. Production calls `Share.shareXFiles([XFile(path)], text: text)`.
3. Add a pure caption formatter or private deterministic helper with tests; use currency formatting consistent with current app (plain two decimals if no shared formatter exists).
4. Simplify the bottom sheet so the primary action does not depend on phone presence. Remove the misleading WhatsApp-specific key/action/tests.
5. Keep `_ensurePdf` cache behavior but invalidate only when screen invoice identity changes (normally immutable detail screen).

## Test-First Specification
- `invoice_share_service_test.dart::shares_pdf_and_formatted_caption`: asserts one file and exact required caption fields; forbids GSTIN/bank/account/internal IDs.
- `invoice_detail_screen_test.dart::share_pdf_visible_without_customer_phone`: prevents phone-gated attachment sharing.
- `...::primary_share_generates_pdf_then_invokes_share_service_with_caption`: verifies sequencing and busy state.
- `...::share_failure_displays_retryable_error`: prevents swallowed platform errors.
- Remove/replace tests expecting `wa.me`; retain phone-cleaning tests for the explicitly retained SMS action.

## Validation Ladder
1. Red: focused service/widget tests fail on old signature/chat-only option.
2. Green: run the two focused sharing files.
3. Run PDF, invoice detail, and full service/widget invoice tests.
4. Formatter/analyzer and debug/release Android build.
5. Android local-mode runtime: open GST and non-GST invoice, tap primary share, verify chooser lists WhatsApp when installed, preview shows one PDF and caption, cancel chooser safely, retry.
6. Proves AC-SHARE-01.

## Review Checklist
- Attachment and caption use one OS share invocation.
- No claim that WhatsApp received/delivered it.
- No sensitive caption fields.
- Works without phone number.
- Errors and chooser cancellation do not mutate state.
- Old misleading direct action is gone.

## Allowed Adaptation
Use the current `share_plus` API signature for installed version 10.0.0. Adjust button copy to fit UI while preserving meaning.

## Stop And Escalate If
- Target Android/share_plus cannot attach a PDF and caption together in an actual runtime test.
- WhatsApp requires unsupported provider/file permissions not supplied by share_plus.
- Product owner insists on silent/direct sending, which is outside approved design.

## Commit Checkpoint
Suggested: `feat: share invoice pdfs with formatted captions`

## Done When
Focused/full tests pass and Android evidence confirms a PDF attachment plus caption reaches the chooser without phone gating or privacy leakage.

## Handoff Update
Log device/emulator, installed chooser targets, attachment/caption observation, cancellation/error behavior, and commands. Mark Task 05 complete in `STATE.md`.
