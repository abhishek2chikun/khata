# LLM Review Anchor

Workflow objective: Deliver genuinely distinct GST/non-GST invoices, date-only mobile creation, adaptive A5/A4 PDFs, attached invoice sharing, and customer receivable sharing with API/local alignment.

User value and success definition: A wholesaler can create and share financially truthful documents and collection reminders without timezone failures or manual message composition.

Repository baseline SHA: `7699ae634988fcf577d7ee3e26480a37c475be02`

## Approved Scope And Non-Goals
Approved: seller/invoice `gst_flag`, zero-tax non-GST calculation, date-only mobile flow, four PDF variants, attached-PDF sharing, individual customer balance, and daily all-positive customer summary.

Excluded: arbitrary tax suppression by GST sellers, supplier payables, GST filing/IRN, cloud sync, direct WhatsApp API, v8 backup conversion, and destructive datetime removal.

## Architecture In One Page
Company profile defines seller policy/default. Invoice draft carries the selected mode. Backend/local invoice services resolve policy, calculate canonical totals, hash mode, persist immutable snapshots, and preserve stock/ledger transactionality. PDF renders only invoice detail. OS sharing handles attachment/caption. Balance formatter consumes existing customer-list balances and profile identity without new backend routes.

## Key Decisions And Why
| Decision | Choice | Why | Rejected alternatives |
|---|---|---|---|
| Non-GST meaning | Zero effective tax and omitted tax identity | Avoid misleading totals | Hide GST fields only |
| GST seller exception | Non-GST only for zero-rate lines | Approved safety boundary | Arbitrary taxable non-GST bills |
| Non-GST seller prices | Stored/entered selling price is final; force tax zero | Seller cannot collect GST | Back-calculate embedded GST |
| Date | Mobile sends date only; legacy aware datetime remains | Fix blocker compatibly | Drop column/validator |
| PDF size | <=15 rows is an A5 candidate retained only for a complete one-page render; overflow or >15 uses A4 | User-approved Stage 5 paper-efficiency refinement with readable 6pt minimum table text | Fixed 10/11 threshold; forcing overflow into A5 |
| WhatsApp | PDF+caption through OS chooser | `wa.me` cannot attach file | Chat-only action |
| Balance scope | Customer receivables, current dated snapshot | User approval/repo terminology | Supplier payables/today delta |

## Contracts And Invariants That Must Survive
- Append-only customer ledger, transactional invoice/stock effects, exact cancellation reversal.
- Existing GST invoice math and intra/inter-state behavior.
- `gst_flag` in idempotency hash; replay same succeeds, changed mode conflicts.
- Invoice snapshots remain immutable after profile/customer edits.
- API/local schemas and validation codes align.
- Non-GST PDF contains no GSTIN/tax-regime/GST component content.
- Sharing is explicit/user initiated and does not log sensitive bodies.

## Acceptance Criteria By Risk
| ID | Outcome | Planned proof | Risk if wrong |
|---|---|---|---|
| AC-GST-01/02 | Mode policy and truthful zero/GST totals | API/local policy tests plus PDF extraction | Financial/legal misstatement |
| AC-DATE-01 | Date-only mobile works; legacy aware datetime works | Payload and API/local tests | Invoice creation blocker/date shift |
| AC-PDF-01/02 | Exact sizes/readable variants/canceled marker | Dimension/text tests plus visual review | Unprintable/misleading document |
| AC-SHARE-01 | Attached PDF and caption reach chooser | Handler/widget and Android evidence | User shares no attachment/privacy leak |
| AC-BAL-01/02 | Exact individual/daily receivables | Formatter/widget/parity/runtime tests | Incorrect collection request |
| AC-COMPAT-01 | Historical rows and clients survive | Alembic/Drift and legacy API tests | Data/app upgrade failure |
| AC-REGRESSION-01 | Side effects/parity/build remain sound | Full suites and local Android E2E | Stock/ledger corruption |

## Expected Change Surface
| Module/contract | Expected change | Expected task/commit |
|---|---|---|
| Alembic/Drift/backup/profile/invoice DTOs | additive flags, schema 9, deterministic backfill | Task 01 |
| Backend/local invoice services | validation, non-GST math, hash, snapshots | Task 02 |
| Profile/draft/create/preview | seller controls, mode defaults, date-only payload | Task 03 |
| PDF service | shared adaptive renderer | Task 04 |
| Invoice share service/detail | attachment+caption, remove misleading direct action | Task 05 |
| Customer screens/new formatter | individual/daily preview and text share | Task 06 |

## Highest-Risk Failure Modes
- Treating non-GST as visual-only or back-calculating GST from final price.
- Allowing GST seller taxable lines in non-GST mode.
- Omitting mode from request hash or applying policy only in UI.
- Migration rewriting historical money/hash/ledger data.
- Date conversion crossing calendar day.
- A5 test checking file existence but not page dimensions/readability.
- WhatsApp action opening chat without attaching PDF.
- Daily summary using invoice totals/today movement or N+1 ledger queries instead of canonical current balances.

## Review Hypotheses
- SLM may modify `normalize_line` and regress GST invoices instead of isolating non-GST normalization.
- SLM may infer `gst_flag` from GSTIN at render time instead of persisted invoice flag.
- SLM may hand-edit generated Drift code or include unrelated generated churn.
- SLM may weaken backend timezone validation rather than omit mobile datetime.
- SLM may use current profile in old invoice PDFs, leaking changed GSTIN/bank details.
- SLM may claim WhatsApp delivery from OS chooser handoff.
- SLM may update docs/test counts optimistically before full evidence.

## Expected Runtime/E2E Evidence
Disposable PostgreSQL migration/backfill/downgrade; Drift v8-to-v9 upgrade; four visually reviewed PDFs plus canceled/long variants; Android local-mode date-only create, prohibited modes, attachment chooser, exact individual balance, positive-only daily summary, empty state, persistence after restart; full backend/mobile suites and release APK build.

## Plan Assumptions To Recheck
- `share_plus` 10 supports attachment plus caption on target Android.
- Existing zero product GST rate is adequate for GST-seller eligibility.
- Customer list excludes/includes archived records consistently across modes.
- Local double/string rounding matches backend Decimal for representative and boundary values.

## Final Review Checklist
- Compare actual diff/commits to every task and AC mapping.
- Inspect migration SQL and generated Drift diff first.
- Trace representative GST/non-GST quote -> create -> ledger -> cancel in both modes.
- Inspect request hash and date serialization.
- Parse and visually inspect PDFs.
- Verify captions/messages omit sensitive fields and sharing is explicit.
- Require full-suite/build/runtime evidence or record honest blockers.

## Rehydration Order
1. `STATE.md`
2. This anchor
3. Stage 4 return packet
4. Actual commit range/diff
5. Targeted files/evidence listed by the return packet

## When Full Rediscovery Is Justified
Only if repository baseline changed outside the workflow, the return packet contradicts the diff, or a material Stage 0 fact is missing/stale.
