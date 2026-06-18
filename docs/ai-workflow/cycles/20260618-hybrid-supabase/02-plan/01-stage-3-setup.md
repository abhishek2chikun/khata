# Task 01: Create Stage 3 Worktree And Safety Audit

## Outcome

Create the implementation branch/worktree from the clean Stage 2 planning commit and prove the recovery branch and preserved user files are understood before any source change.

## Why This Task Exists

The hybrid migration touches the whole runtime. Stage 3 must start isolated from `main`, and cleanup must be reversible through `main_backup`.

## Dependencies

- Stage 2 planning commit on `main`.
- `origin/main_backup` exists.

## Repository Evidence

- Planning checkout: `/Users/abhishek/python_venv/khata_app`.
- Safety branch recorded in `STATE.md`.
- Untracked root `MASTER CATALOG.xlsx` exists in the planning checkout and must be intentionally adopted in Task 03.

## Read Before Editing

1. `../STATE.md`
2. `implementation_guide.md`
3. `00-plan-index.md`
4. `../02-design.md`

## Scope

### Change

- Create feature worktree and branch.
- Create `03-implementation-log.md` only after entering Stage 3.
- Update `STATE.md` to record Stage 3 baseline/worktree details.

### Preserve

- `main_backup` branch and remote branch.
- Existing planning docs.
- `MASTER CATALOG.xlsx` until Task 03 intentionally moves/copies/tracks it.

### Explicitly out of scope

- Source code, migrations, dependencies, generated assets, and cleanup.

## Contracts And Invariants

- Feature branch: `codex/hybrid-supabase`.
- Worktree: `/Users/abhishek/python_venv/khata_app/.worktrees/hybrid-supabase`.
- Implementation starts from the Stage 2 planning commit HEAD.
- No merge to `main`.

## Implementation Guidance

Run the baseline commands from `00-plan-index.md`. If `main` is dirty with unrelated changes, stop and report. If only `MASTER CATALOG.xlsx` is present, preserve it for Task 03 and do not stage it in Task 01.

## Test-First Specification

Pre-change signal: no feature worktree exists for this cycle.

Assertions:

- `git worktree list` includes the new worktree.
- `git branch --show-current` inside the worktree is `codex/hybrid-supabase`.
- `git rev-parse HEAD` inside the worktree equals the Stage 2 planning commit.
- `git ls-remote --heads origin main_backup` returns the safety branch.

## Validation Ladder

```bash
git status --short
git rev-parse HEAD
git ls-remote --heads origin main_backup
git worktree list
```

Expected evidence: clean feature worktree, correct branch, safety branch visible.

## Review Checklist

- Worktree was created from the planning commit.
- No product files changed.
- Stage 3 log/state were updated only after Stage 3 began.

## Allowed Adaptation

If `.worktrees/hybrid-supabase` already exists and points to the correct branch and commit, reuse it after recording evidence.

## Stop And Escalate If

- `main_backup` is missing.
- The planning checkout contains unrelated dirty files besides the known workbook.
- The worktree already exists but points to a different branch or unknown changes.

## Commit Checkpoint

No commit required for setup alone unless Stage 3 state/log files are created. If committed, include only workflow Stage 3 setup artifacts.

## Done When

The feature worktree is ready, safety branch is verified, and Stage 3 records its baseline before product changes.

## Handoff Update

Add to `03-implementation-log.md`: worktree path, branch, baseline SHA, status output, `main_backup` SHA, preserved untracked files, and next task.

Update `STATE.md`: current stage `3-implementation`, current owner `Stage 3 fresh SLM`, implementation baseline SHA, feature worktree status, and current task `Task 02`.
