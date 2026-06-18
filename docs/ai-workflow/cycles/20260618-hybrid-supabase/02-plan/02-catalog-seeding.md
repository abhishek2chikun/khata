# Task 03: Canonicalize Catalog And Generate Drift/Supabase Seed Parity

## Outcome

Make `MASTER CATALOG.xlsx` the tracked canonical catalog source and update tooling so one parse produces both bundled Drift seed JSON and Supabase seed data with identical stable IDs.

## Why This Task Exists

Hybrid sync cannot be trustworthy if the local cache and Supabase start from different product/buyer identities or counts.

## Dependencies

- Task 01 setup.
- Task 02 table/RPC names for catalog seed destination.

## Repository Evidence

Read current analogs before editing:

- `tools/build_preinstalled_catalog.py`
- `data/source/products.xlsx`
- `mobile/assets/catalog/preinstalled_catalog.json`
- Current product/buyer models in `mobile/lib/`
- `MASTER CATALOG.xlsx` at repo root, currently untracked in the planning checkout

## Read Before Editing

1. `../STATE.md`
2. `00-plan-index.md`
3. `01-supabase-schema-rpc.md`
4. Existing catalog generator and tests, if present

## Scope

### Change

- Move or copy `MASTER CATALOG.xlsx` into a tracked canonical path. Recommended: `data/source/MASTER CATALOG.xlsx`.
- Update catalog generator to parse the workbook once.
- Generate Drift bundled seed JSON.
- Generate Supabase seed SQL/JSON consumed by `seed_master_catalog`.
- Add tests for deterministic parsing and seed parity.

### Preserve

- Existing app field semantics.
- Existing bundled catalog behavior for fresh install before Supabase sync.
- User's source workbook content; do not manually edit the workbook data unless explicitly required and documented.

### Explicitly out of scope

- Mobile sync implementation.
- Changing official stock through seed after production cutover.
- Inventing product categorization not present in the workbook or current app.

## Contracts And Invariants

- One canonical workbook source.
- Stable UUIDs for products and buyers/sellers across Drift and Supabase.
- Same normalized product count and buyer count in both outputs.
- Deterministic de-dup rule for repeated rows.
- Seed is idempotent.
- Supabase reseed must not overwrite mutable production stock without explicit admin flag.

## Implementation Guidance

Normalize at least:

- product name
- HSN
- GST rate
- unit
- purchase/sale price fields used by current app
- opening stock/current stock fields if present
- seller/buyer association if present
- active/archive state

Use structured workbook parsing, not ad hoc string slicing. If sheet names or formulas are ambiguous, document selected sheet/table in code comments and tests.

Stable ID strategy:

- Prefer deterministic UUIDv5 from normalized business key.
- Include enough source fields to avoid collisions.
- Persist a mapping output if deterministic key changes would otherwise churn IDs.

## Test-First Specification

Add tests that fail before implementation:

- Generator reads the tracked workbook path.
- Drift and Supabase outputs have identical product IDs and counts.
- Drift and Supabase outputs have identical buyer/seller IDs and counts when present.
- Running generator twice produces byte-stable outputs or a documented stable ordering.
- Duplicate normalized product rows follow the documented de-dup rule.
- Missing required HSN/GST fields fail with actionable errors.

## Validation Ladder

```bash
python3 tools/build_preinstalled_catalog.py
<catalog parity test command>
git status --short
```

Expected evidence:

- Generated outputs are updated intentionally.
- Workbook is tracked at the canonical path.
- No unrelated generated/runtime files changed.

## Review Checklist

- IDs are stable and shared.
- Count mismatches fail tests.
- The old `data/source/products.xlsx` role is either preserved as historical input or clearly superseded.
- Supabase seed cannot accidentally reset mutable production data.

## Allowed Adaptation

If the workbook must remain at repo root because downstream tooling expects it, keep it there but track it and update docs to mark that root path canonical.

## Stop And Escalate If

- Workbook rows cannot be mapped to required schema fields.
- Duplicate handling would change real product identity in a way the user must approve.
- Generator requires dependencies not already acceptable for the repo.

## Commit Checkpoint

Commit after generator tests and seed parity pass. Suggested message: `feat(hybrid): generate supabase and drift catalog seeds`.

## Done When

Stage 3 has a tracked canonical workbook and repeatable seed outputs that match across Drift and Supabase.

## Handoff Update

Add to `03-implementation-log.md`: workbook path, generator command, output paths, counts, ID strategy, test evidence, and next task.

Update `STATE.md`: Task 03 status, catalog path/counts, and current task `Task 04`.
