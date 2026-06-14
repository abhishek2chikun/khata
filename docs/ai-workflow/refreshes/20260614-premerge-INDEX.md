# AI Workflow Cycle Registry

Project: Internal Billing and Khata System (`khata_app`)
Workflow root: `docs/ai-workflow/`
Current repository HEAD: `837ccbc0cfdb09a25b6aad02e4b0c357abafa8a6`
Active cycle: none (await concrete feature objective)
Last accepted/reviewed cycle: `khata-app-baseline` @ `de7318a` (Stage 5 closed; post-review commit `837ccbc` on `main`)
Last updated: 2026-06-14 IST

## Cycle Registry

| Cycle ID | Type | Objective | Status/verdict | Baseline SHA | Final SHA | Affected areas/tags | Parent/relevant cycles | Artifact path |
|---|---|---|---|---|---|---|---|---|
| khata-app-baseline | first-cycle | GST/non-GST invoicing, date-only creation, adaptive PDFs, invoice/balance sharing, API/local parity | accepted-with-followups (`code-ready-for-phone-testing`; production-release-blocked) | `7699ae6` | `de7318a` (+ post-review `837ccbc`) | mobile/local, invoices, PDF, sharing, backup, gst | none | `docs/ai-workflow/khata-app-baseline/` |

## Active Cross-Cycle Blockers

1. Android application ID still `com.example.internal_billing_khata_mobile` — must be finalized before distribution.
2. Release APK still uses debug signing; production keystore required.
3. Physical-device verification pending for share chooser, encrypted backup export/import, restart persistence.
4. PostgreSQL integration suite unverified (`localhost:55432` unavailable in refresh run).
5. PDF Helvetica font does not support non-Latin text (deferred).

## Deferred Opportunities

- Google Drive backup OAuth/upload/download (skeleton only).
- Hybrid local-to-server migration/sync (design-only).
- Unicode/multilingual PDF font support.
- CI pipeline (no `.github/workflows` found).
- Permanent Android app ID + release signing setup (prerequisite for production).

## Superseded Cycles/Decisions

| Prior claim | Superseded by | Notes |
|---|---|---|
| A5 PDF threshold ≤10 line items | Stage 5 refinement + `837ccbc` | Code uses ≤15-row A5 candidate with one-page fit fallback; README/mobile `agent.md` still mention ≤10 in places |
| Backup schema version 8 | Drift v9 / README | Current local schema and backup payload version is **9** |
| Mobile test count ~355–376 | Current suite | **389 passed** at refresh (`flutter test test`) |
| Stage 4/5 fixes "uncommitted" | `837ccbc` on `main` | Workflow artifacts and prod-audit fixes are committed on `main` |
