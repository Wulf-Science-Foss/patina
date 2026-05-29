# Specification: CI Milestone Sync
Version: 0.1.0
Status: DRAFT

## Purpose

Defines the `milestone-sync.yaml` Forgejo Actions workflow that parses phase gate
checklists from merged PR bodies and synchronises Forgejo milestones via the REST API.

## Requirements

REQ-CI-001: The workflow SHALL parse the phase gate checklist from a merged PR body.
REQ-CI-002: The workflow SHALL call the Forgejo API to update milestone progress.
REQ-CI-003: The workflow SHALL auto-close a milestone when all checklist items are checked.
REQ-CI-004: The workflow SHALL auto-create the next phase milestone on closure.
REQ-CI-005: The workflow SHALL post a milestone progress summary as a PR comment.

## Data Model

Inputs: PR body (markdown), Forgejo API token, repo owner/name.
Forgejo API: `GET/POST/PATCH /api/v1/repos/{owner}/{repo}/milestones`

## Behaviour

1. Trigger: PR merged to main
2. Parse checklist items from PR body
3. Determine current phase milestone
4. Calculate checked / total
5. PATCH milestone with updated progress
6. If all checked → close milestone, create next
7. POST PR comment with summary

## Acceptance Criteria

ACC-CI-001: Given a PR with all checklist items checked, when merged, the milestone is closed.
ACC-CI-002: Given a PR with partial checklist, when merged, milestone progress is updated.
ACC-CI-003: Given milestone closure, the next phase milestone is created automatically.
ACC-CI-004: Given any merge, a progress comment is posted to the PR.

## Out of Scope

- Manual milestone management
- Non-phase-gate PR bodies

## References

- Forgejo REST API docs
- [docs/roadmap/](../roadmap/) for phase gate checklists
