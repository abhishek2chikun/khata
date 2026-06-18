# Implementation Guide: Hybrid Supabase-Only Khata

Workflow schema: five-stage-v1

Execution shape: sequential

Why this shape is safe and efficient: Supabase schema/RPC contracts, catalog IDs, Drift cache models, and mobile service boundaries are shared correctness surfaces. Parallel writers would likely edit the same contracts before they are proven. Sequential execution keeps the authority model coherent and still lets a fresh SLM finish in reviewable slices.

Coordinator responsibilities:

- Create the Stage 3 worktree from the clean Stage 2 planning commit.
- Record the implementation baseline in `STATE.md` and `03-implementation-log.md`.
- Execute tasks in dependency order.
- Keep the design decisions fixed unless a stop condition is hit.
- Update implementation log and state after each task.
- Run combined validation before Stage 4 handoff.

Canonical feature worktree creation: from `/Users/abhishek/python_venv/khata_app` on clean `main`, create `/Users/abhishek/python_venv/khata_app/.worktrees/hybrid-supabase` on branch `codex/hybrid-supabase`.

Implementation baseline rule: create from the clean Stage 2 planning HEAD, not from the older pre-planning baseline.

## Dependency Graph

| Task/lane | Depends on | Unlocks | Integration checkpoint |
|---|---|---|---|
| 01 Stage 3 setup | none | all tasks | feature worktree exists and `main_backup` verified |
| 02 Supabase schema/RPC | 01 | 03,04 | migrations apply and SQL/RPC tests cover core writes |
| 03 Catalog seeding | 01,02 contracts | 04,06 | Drift/Supabase seed parity test passes |
| 04 Mobile hybrid services/sync | 02,03 | 05,06 | all official mobile writes call RPC and update Drift |
| 05 Cutover cleanup | 04 parity | 06 | old runtime/backup surfaces unreachable |
| 06 Validation/handoff | 02-05 | Stage 4 | return packet and evidence complete |

## Sequential Spine

1. Establish the isolated worktree and audit safety branch.
2. Build database authority first because mobile writes depend on RPC semantics.
3. Lock catalog seed IDs before syncing products/buyers into mobile cache.
4. Implement mobile hybrid auth/sync/services using the proven DB and seed contracts.
5. Clean old runtime paths only after hybrid tests prove parity.
6. Validate end-to-end and prepare the Stage 4 review packet.

## Parallel Lanes

none

## Sub-Agent Protocol

- Use sub-agents only for read-only review or targeted investigation unless the coordinator creates isolated lane branches/worktrees and can guarantee non-overlap.
- Do not allow concurrent direct writes to the same checkout.
- If a future coordinator chooses parallelism, record the changed execution shape in `03-implementation-log.md`, prove owned paths do not overlap, and keep integration order from this guide.
- The coordinator owns shared contracts, final conflict resolution, state/log updates, and combined validation.

## Integration Order

1. Merge/apply Task 02 changes and run SQL/RPC tests.
2. Merge/apply Task 03 generator/seed changes and run parity tests.
3. Merge/apply Task 04 mobile changes and run focused Flutter tests.
4. Merge/apply Task 05 cleanup and run static/widget tests proving old modes are unreachable.
5. Run Task 06 full validation.

## Shared Validation Gates

- No service role key or private credential in repo.
- No Flutter path assigns official invoice numbers.
- No official write bypasses Supabase RPC.
- Sync upserts rows and never normal-replaces the full Drift DB.
- First hybrid cutover clears local business cache only after Supabase auth/setup check.
- Backup/local/API runtime is unreachable in the final app.

## Commit Strategy

- Prefer one commit per completed task or small group of tightly related subtasks.
- Commit messages should identify the task, for example `feat(hybrid): add supabase invoice rpc`.
- Do not commit broken intermediate states unless explicitly marked as WIP on the feature branch and followed by a fixing commit before handoff.
- Do not merge into `main`; Stage 5 owns merge.

## Stop/Return Conditions

Stop and return to the persistent/strong-model lane if:

- Supabase RPC cannot atomically enforce invoice, stock, and ledger rules.
- RLS requires weakening table security beyond the approved design.
- Catalog workbook parsing is ambiguous enough to change product data semantics.
- Any old runtime path must remain reachable for a reason not approved in Stage 2.
- Real Supabase/local Supabase validation is unavailable and mocks are the only evidence for authority behavior.

## Final Stage 3 Completion Sequence

1. Update `03-implementation-log.md` with task outcomes, commits, evidence, deviations, and blockers.
2. Update `STATE.md` to Stage 3 complete or blocked, never merged.
3. Create `04-return-packet.md` and `04-validation-report.md` only at Stage 4 handoff time if the workflow expects Stage 3 to prepare them; otherwise record where evidence lives.
4. Run the full validation ladder from `00-plan-index.md`.
5. Leave branch/worktree unmerged and ready for Stage 4/5 review.
