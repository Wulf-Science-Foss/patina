# Specification: CI Milestone Sync
Version: 0.2.0
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

## Data Model

Source of truth: `docs/roadmap/phase-N-*.md`, section `## Phase Gate Checklist`.
Checklist items: lines matching `^\s*- \[[ x]\]`.
Milestone title: the `# Phase N — ...` heading from the same file.

Forgejo API used:
- `GET  /api/v1/repos/{owner}/{repo}/milestones?state=all`
- `POST /api/v1/repos/{owner}/{repo}/milestones`
- `PATCH /api/v1/repos/{owner}/{repo}/milestones/{id}`
- `POST /api/v1/repos/{owner}/{repo}/issues/{index}/comments`

## Behaviour

1. Load credentials from environment (CI) or `.env` (local).
2. Fetch all existing milestones (open and closed).
3. For each `docs/roadmap/phase-*.md` in sorted order:
   a. Extract title from the `# Phase N — ...` heading.
   b. Count total and checked items in `## Phase Gate Checklist`.
   c. Skip the file if it has no checklist items.
   d. Find the matching Forgejo milestone by title; create it if absent.
   e. PATCH description and state to match checklist reality.
4. If `--pr-number N` was passed, post a full progress summary comment.

## Acceptance Criteria

ACC-CI-001: A phase with all items checked results in a closed milestone.
ACC-CI-002: A phase with partial items checked results in an open milestone with correct description.
ACC-CI-003: A phase milestone missing from Forgejo is created automatically.
ACC-CI-004: A closed milestone whose checklist is un-checked is reopened.
ACC-CI-005: Running the script twice produces no additional changes (idempotent).
ACC-CI-006: A PR comment is posted when --pr-number is supplied.

## Out of Scope

- Manual milestone management
- Parsing checklist state from PR bodies
- Milestones for non-phase work (bugs, chores)

## References

- Forgejo REST API docs
- [docs/roadmap/](../roadmap/) for phase gate checklists
