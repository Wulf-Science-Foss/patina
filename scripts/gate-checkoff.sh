#!/usr/bin/env bash
# gate-checkoff.sh — Tick phase gate checklist and flip status flags on merge to main.
# Source of truth for when work is done; never run by hand during development.
# Idempotent: safe to run multiple times on the same phase.
#
# Usage:
#   ./scripts/gate-checkoff.sh --branch <branch-name> --pr-number <N> [--dry-run]
#
# ACC-GC-001 through ACC-GC-005 are exercised by CI on merge to main.

set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

DRY_RUN=0
BRANCH_NAME=""
PR_NUMBER=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)    DRY_RUN=1;           shift   ;;
    --branch)     BRANCH_NAME="$2";   shift 2 ;;
    --pr-number)  PR_NUMBER="$2";     shift 2 ;;
    *) echo "Unknown option: $1" >&2; exit 1  ;;
  esac
done

if [[ -z "$BRANCH_NAME" ]]; then
  echo "ERROR: --branch is required" >&2
  exit 1
fi

# REQ-GC-002: extract phase number from branch name.
# Matches <type>/phase-N or <type>/phase-N--<change>.
PHASE_NUM=""
if [[ "$BRANCH_NAME" =~ [^/]+/phase-([0-9]+) ]]; then
  PHASE_NUM="${BASH_REMATCH[1]}"
fi

# REQ-GC-003: non-phase branches are a no-op.
if [[ -z "$PHASE_NUM" ]]; then
  echo "Branch '${BRANCH_NAME}' has no phase number — nothing to check off."
  exit 0
fi

echo "Phase:  ${PHASE_NUM}"
echo "Branch: ${BRANCH_NAME}"
[[ -n "$PR_NUMBER" ]] && echo "PR:     #${PR_NUMBER}"

# REQ-GC-004: find roadmap file.
ROADMAP_FILE=""
for f in "${REPO_ROOT}/docs/roadmap/phase-${PHASE_NUM}-"*.md; do
  [[ -f "$f" ]] && ROADMAP_FILE="$f" && break
done

if [[ -z "$ROADMAP_FILE" ]]; then
  echo "ERROR: no roadmap file found for phase ${PHASE_NUM}" >&2
  exit 1
fi

echo "Roadmap: ${ROADMAP_FILE}"

if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "[dry-run] would tick all checkboxes in ${ROADMAP_FILE}"
  echo "[dry-run] would set Status: COMPLETE in ${ROADMAP_FILE}"
  echo "[dry-run] would update CLAUDE.md Phase ${PHASE_NUM} row to COMPLETE"
  exit 0
fi

# REQ-GC-005: tick all unchecked boxes in the roadmap file.
sed -i 's/- \[ \]/- [x]/g' "$ROADMAP_FILE"

# REQ-GC-006: flip the Status flag in the roadmap file.
sed -i 's/^\*\*Status:\*\* TODO/**Status:** COMPLETE/' "$ROADMAP_FILE"

# REQ-GC-007: update the CLAUDE.md roadmap table row for this phase.
CLAUDE_MD="${REPO_ROOT}/CLAUDE.md"
sed -i "/Phase ${PHASE_NUM} /s/| TODO |/| COMPLETE |/" "$CLAUDE_MD"

# REQ-GC-010: idempotency — skip commit if nothing changed.
cd "$REPO_ROOT"
if git diff --quiet "$ROADMAP_FILE" "$CLAUDE_MD"; then
  echo "No changes (already COMPLETE). Nothing to commit."
  exit 0
fi

# REQ-GC-008 / REQ-GC-009: commit as CI bot.
PR_REF=""
[[ -n "$PR_NUMBER" ]] && PR_REF=" of PR #${PR_NUMBER}"

git config user.name  "github-actions[bot]"
git config user.email "github-actions[bot]@users.noreply.github.com"
git add "$ROADMAP_FILE" "$CLAUDE_MD"
git commit -m "chore(ci): check off Phase ${PHASE_NUM} gate on merge${PR_REF} [skip ci]"

echo "Gate check-off complete for Phase ${PHASE_NUM}."
