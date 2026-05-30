# Specification: CI Gate Check-off
Version: 0.1.0
Status: APPROVED

## Purpose

Defines the `gate-checkoff.yaml` Forgejo Actions workflow and its backing
script `scripts/gate-checkoff.sh`. When a feature branch merges to `main`,
the workflow ticks all phase gate checklist boxes and flips status flags in
the roadmap file and the CLAUDE.md roadmap table for the merged phase.

The phase gate checklists and roadmap status flags are **never updated by
hand** during development — an unchecked checklist on a working branch is
the correct state. This workflow is the sole authority for marking a phase
done.

The script is idempotent: running it multiple times on the same phase
produces the same result.

## Requirements

REQ-GC-001: The workflow SHALL trigger only when a PR is merged to `main`
            (not on every PR event).

REQ-GC-002: The script SHALL determine the phase number from the merged
            branch name using the pattern `<type>/phase-N` (e.g.
            `docs/phase-0`, `feat/phase-1`).

REQ-GC-003: If no phase number is found in the branch name, the script
            SHALL exit with code 0 and log a message. It SHALL NOT fail the
            build for non-phase branches (e.g. `chore/gate-checkoff`).

REQ-GC-004: The script SHALL locate the roadmap file for the phase by
            globbing `docs/roadmap/phase-N-*.md`. If no file is found, it
            SHALL exit with a non-zero code.

REQ-GC-005: The script SHALL replace every `- [ ]` with `- [x]` in the
            roadmap file.

REQ-GC-006: The script SHALL replace `**Status:** TODO` with
            `**Status:** COMPLETE` in the roadmap file.

REQ-GC-007: The script SHALL update the CLAUDE.md roadmap table: for the
            row matching `Phase N`, it SHALL replace `| TODO |` with
            `| COMPLETE |`.

REQ-GC-008: The script SHALL commit the changes to `main` with a standard
            commit message referencing the merged PR number and phase.

REQ-GC-009: All changes SHALL be committed as a single atomic commit by the
            CI bot identity.

REQ-GC-010: The script SHALL be idempotent — running it again on a fully
            checked phase SHALL make no further changes and exit 0.

## Data Model

**Inputs:**
- Merged branch name (from `github.event.pull_request.head.ref`)
- Merged PR number (from `github.event.pull_request.number`)
- Repository working tree (checked out at `main` post-merge)

**Files modified:**
- `docs/roadmap/phase-N-*.md` — checkboxes and Status flag
- `CLAUDE.md` — roadmap table Status column

**Pattern: phase number extraction**

Branch name format: `<type>/phase-<N>` or `<type>/phase-<N>--<change>`
Regex: `[^/]+/phase-([0-9]+)`

**Pattern: checkbox ticking**

```
- [ ]  →  - [x]
```

Applied via `sed` to the roadmap file only. Does not touch other files.

**Pattern: status flag**

```
**Status:** TODO  →  **Status:** COMPLETE
```

Applied to the roadmap file only.

**Pattern: CLAUDE.md table**

The roadmap table row has the form:

```
| Phase N — <title> | [file](path) | TODO |
```

The last column `TODO` is replaced with `COMPLETE` for the matching row.

## Behaviour

1. Extract phase number N from `PR_BRANCH`. If none, exit 0.
2. Find `ROADMAP_FILE = docs/roadmap/phase-N-*.md`. If not found, exit 1.
3. Tick all `- [ ]` → `- [x]` in `ROADMAP_FILE`.
4. Replace `**Status:** TODO` → `**Status:** COMPLETE` in `ROADMAP_FILE`.
5. In `CLAUDE.md`, update the row containing `Phase N` to change the status
   column from `TODO` to `COMPLETE`.
6. If no files changed (already COMPLETE), exit 0 without committing.
7. Configure git identity to CI bot (`github-actions[bot]`).
8. Stage `ROADMAP_FILE` and `CLAUDE.md`.
9. Commit: `chore(ci): check off Phase N gate on merge of PR #<N> [skip ci]`.

The `[skip ci]` trailer prevents the commit from re-triggering CI workflows.

## Acceptance Criteria

ACC-GC-001: Given a PR merging branch `docs/phase-0` to `main`, when the
            workflow runs, then `docs/roadmap/phase-0-prior-art.md` has all
            `- [ ]` replaced with `- [x]` and `**Status:** TODO` replaced
            with `**Status:** COMPLETE`.

ACC-GC-002: Given ACC-GC-001 has run, when the workflow runs again, then no
            files are changed and the commit step is skipped.

ACC-GC-003: Given a PR merging branch `chore/gate-checkoff` (no phase
            number), when the workflow runs, then no files are changed and
            the workflow exits 0.

ACC-GC-004: Given ACC-GC-001 has run, when `milestone-sync` runs, then
            Phase 0's milestone is closed (all items checked).

ACC-GC-005: Given a PR merging branch `feat/phase-1`, when the workflow
            runs, then `docs/roadmap/phase-1-core-domain.md` is updated and
            `CLAUDE.md` table row for Phase 1 shows `COMPLETE`.

## Out of Scope

- Flipping spec Status from `DRAFT` → `APPROVED` (separate workflow,
  post-MVP)
- Updating prior-art doc Status flags (already set by authors during work)
- Partial check-off (a phase is either complete or not; partial credit is
  tracked by milestone-sync)
- Non-phase branches other than the graceful no-op exit

## References

- [`docs/roadmap/`](../roadmap/) — phase gate checklists
- [`docs/specs/ci-milestone-sync.spec.md`](ci-milestone-sync.spec.md) —
  sibling CI spec; milestone-sync reads the checkboxes this workflow writes
- [`scripts/milestone-sync.sh`](../../scripts/milestone-sync.sh) —
  reference for script conventions
- IEEE 828-2012 §6.3 — configuration status accounting (automated
  check-off is the status accounting record for the phase gate)
