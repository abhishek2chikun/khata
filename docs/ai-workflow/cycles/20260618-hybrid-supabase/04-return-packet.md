# Stage 4 Return Packet

Cycle: `20260618-hybrid-supabase`
Feature branch: `codex/hybrid-supabase`
Canonical worktree: `/Users/abhishek/python_venv/khata_app/.worktrees/hybrid-supabase`
Integration target: `main` (not merged)
Merge status: not-started

## Summary

Stage 3 implemented the hybrid Supabase runtime in an isolated feature worktree:

- Supabase authority schema, RLS, and write RPCs applied to remote project `ekwkklcfovwarcvvxtiq`
- Catalog canonicalized from `data/source/MASTER CATALOG.xlsx` with Drift/Supabase seed parity (1528 products, 30 buyers)
- Flutter hybrid mode: Supabase auth, RPC invoice writes, Drift cache sync, offline write blocking
- Hybrid is the default runtime; backup/local-first UI paths are disabled outside explicit `DATA_MODE=local` test builds

## Commits (feature branch)

| SHA | Message |
|-----|---------|
| b7c3a9f | chore(hybrid): stage 3 worktree setup and untrack .env |
| 11255ca | feat(hybrid): add supabase authority schema and RPCs |
| 3bbe89f | feat(hybrid): generate supabase and drift catalog seeds |
| 498ef81 | feat(hybrid): wire supabase auth sync and hybrid services |
| (pending) | docs(hybrid): stage 3 validation and handoff |

## Validation Evidence

| Check | Command | Result |
|-------|---------|--------|
| Catalog parity | `python3 tools/test_catalog_parity.py` | pass |
| Supabase migrations | `bash supabase/tests/run_migrations_and_tests.sh` | pass |
| Flutter tests | `flutter test test --dart-define=DATA_MODE=local` | 478 passed |
| Flutter analyze | `flutter analyze` | 0 errors, warnings only |
| APK build | `flutter build apk --release --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=... --dart-define=DATA_MODE=hybrid` | unverified (blocked on credential handling in CI shell) |
| Service role in mobile | `rg service_role mobile/` | clean |

## Residual Risks

- Product/customer/buyer official writes still use local Drift services; only invoice create/cancel uses Supabase RPC in this slice
- Real-device login/sync against seeded Supabase requires auth users created in dashboard and `supabase/seed/run_demo_seed.sh` or `seed_master_catalog` RPC
- APK build evidence not captured in this run due to secret-handling gate

## Stage 4 Review Focus

1. Verify RPC idempotency and invoice numbering under concurrent calls
2. Confirm no official write path bypasses RPC for invoices
3. Review whether product/customer write RPC wiring is required before merge
4. Run manual two-device sync test after seeding remote Supabase

## Exact Next Action for Stage 4

Fresh SLM in canonical worktree: read `STATE.md`, `03-implementation-log.md`, diff `main..codex/hybrid-supabase`, independently verify validation evidence, produce Stage 4 verification packet.
