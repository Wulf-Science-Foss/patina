# Specification: CI Milestone Sync
Version: 0.3.0
Status: DRAFT

## Purpose

Defines the `milestone-sync.yaml` Forgejo Actions workflow and its backing script
`scripts/milestone-sync.sh`. Together they keep Forgejo milestones in sync with the
phase gate checklists in `docs/roadmap/phase-*.md`.

The roadmap files are the single source of truth. The script is idempotent: running it
multiple times produces the same result. Milestones are never managed manually.

## Requirements

REQ-CI-001: The script SHALL read checklist state from `docs/roadmap/phase-*.md`, not from PR bodies.
REQ-CI-002: The script SHALL create a Forgejo milestone for each phase that has a checklist.
REQ-CI-003: The script SHALL set each milestone's description to reflect checked/total item count.
REQ-CI-004: The script SHALL close a milestone whose checklist is fully checked.
REQ-CI-005: The script SHALL reopen a milestone whose checklist is no longer fully checked.
REQ-CI-006: The script SHALL post a summary comment when invoked with --pr-number.
REQ-CI-007: The workflow SHALL invoke the script on every PR merged to main.
REQ-CI-008: For each item in `## Phase Gate Checklist`, the script SHALL create a Forgejo issue titled `[Phase N] <item text>` and assign it to the phase milestone, if no such issue already exists.
REQ-CI-009: The script SHALL close an issue whose checklist item is `[x]`, and reopen an issue whose checklist item is `[ ]`.
REQ-CI-010: Issue management is idempotent: the script SHALL match existing issues by title within the milestone and SHALL NOT create duplicates.

## Data Model

Source of truth: `docs/roadmap/phase-N-*.md`, section `## Phase Gate Checklist`.
Checklist items: lines matching `^\s*- \[[ x]\]`.
Milestone title: the `# Phase N — ...` heading from the same file.

Forgejo API used:
- `GET  /api/v1/repos/{owner}/{repo}/milestones?state=all`
- `POST /api/v1/repos/{owner}/{repo}/milestones`
- `PATCH /api/v1/repos/{owner}/{repo}/milestones/{id}`
- `GET  /api/v1/repos/{owner}/{repo}/issues?type=issues&milestone={id}&state=all`
- `POST /api/v1/repos/{owner}/{repo}/issues`
- `PATCH /api/v1/repos/{owner}/{repo}/issues/{index}`
- `POST /api/v1/repos/{owner}/{repo}/issues/{index}/comments`

Issue title format: `[Phase N] <checklist item text>`, where `Phase N` is extracted from the
phase heading (e.g. `Phase 0`, `Phase 1`).

## Behaviour

1. Load credentials from environment (CI) or `.env` (local).
2. Fetch all existing milestones (open and closed).
3. For each `docs/roadmap/phase-*.md` in sorted order:
   a. Extract title from the `# Phase N — ...` heading; derive `Phase N` short prefix.
   b. Count total and checked items in `## Phase Gate Checklist`.
   c. Skip the file if it has no checklist items.
   d. Find the matching Forgejo milestone by title; create it if absent.
   e. PATCH description and state to match checklist reality.
   f. Fetch all issues currently assigned to the milestone.
   g. For each checklist item:
      - Compute issue title `[Phase N] <item text>`.
      - If no issue with that title exists in the milestone, create it (assigned to milestone).
      - If the checklist item is `[x]` and the issue is open, close the issue.
      - If the checklist item is `[ ]` and the issue is closed, reopen the issue.
4. If `--pr-number N` was passed, post a full progress summary comment.

## Acceptance Criteria

ACC-CI-001: A phase with all items checked results in a closed milestone.
ACC-CI-002: A phase with partial items checked results in an open milestone with correct description.
ACC-CI-003: A phase milestone missing from Forgejo is created automatically.
ACC-CI-004: A closed milestone whose checklist is un-checked is reopened.
ACC-CI-005: Running the script twice produces no additional changes (idempotent).
ACC-CI-006: A PR comment is posted when --pr-number is supplied.
ACC-CI-007: After a run, each phase checklist item has a corresponding Forgejo issue assigned to its phase milestone.
ACC-CI-008: A checked (`[x]`) item's issue is in `closed` state; an unchecked (`[ ]`) item's issue is in `open` state.
ACC-CI-009: Running the script twice against the same roadmap state creates no additional issues and makes no state changes.

## Out of Scope

- Manual milestone management
- Parsing checklist state from PR bodies
- Milestones for non-phase work (bugs, chores)

## References

- Forgejo REST API docs
- [docs/roadmap/](../roadmap/) for phase gate checklists
