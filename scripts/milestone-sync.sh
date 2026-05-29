#!/usr/bin/env bash
# milestone-sync.sh — Sync Forgejo milestones from phase roadmap checklists.
# Source of truth: docs/roadmap/phase-*.md (## Phase Gate Checklist sections).
# Idempotent: safe to run multiple times.
#
# Usage:
#   ./scripts/milestone-sync.sh [--pr-number N] [--dry-run]
#
# Credentials: reads FORGEJO_TOKEN, FORGEJO_URL, FORGEJO_OWNER, FORGEJO_REPO
# from the environment (CI) or from .env (local dev).

set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

DRY_RUN=0
PR_NUMBER=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)      DRY_RUN=1;          shift   ;;
    --pr-number)    PR_NUMBER="$2";     shift 2 ;;
    *) echo "Unknown option: $1" >&2;   exit 1  ;;
  esac
done

if [ -z "${FORGEJO_TOKEN:-}" ]; then
  # shellcheck source=../.env
  source "${REPO_ROOT}/.env"
fi

API="${FORGEJO_URL}/api/v1"
REPO_PATH="${FORGEJO_OWNER}/${FORGEJO_REPO}"

api_get() {
  curl -sf \
    -H "Authorization: token ${FORGEJO_TOKEN}" \
    "${API}/$1"
}

api_post() {
  local path="$1" data="$2" response http_code
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "[dry-run] POST ${path}: ${data}" >&2
    echo '{}'
    return
  fi
  response=$(curl -s -w '\n__HTTP_%{http_code}' -X POST \
    -H "Authorization: token ${FORGEJO_TOKEN}" \
    -H "Content-Type: application/json" \
    --data-binary "$data" \
    "${API}/${path}")
  http_code=$(printf '%s' "$response" | grep -o '__HTTP_[0-9]*' | grep -o '[0-9]*')
  body=$(printf '%s' "$response" | sed '$d')
  if [ "$http_code" -lt 200 ] || [ "$http_code" -ge 300 ]; then
    echo "ERROR: POST ${path} returned HTTP ${http_code}: ${body}" >&2
    exit 1
  fi
  printf '%s' "$body"
}

api_patch() {
  local path="$1" data="$2" response http_code
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "[dry-run] PATCH ${path}: ${data}" >&2
    return
  fi
  response=$(curl -s -w '\n__HTTP_%{http_code}' -X PATCH \
    -H "Authorization: token ${FORGEJO_TOKEN}" \
    -H "Content-Type: application/json" \
    --data-binary "$data" \
    "${API}/${path}")
  http_code=$(printf '%s' "$response" | grep -o '__HTTP_[0-9]*' | grep -o '[0-9]*')
  body=$(printf '%s' "$response" | sed '$d')
  if [ "$http_code" -lt 200 ] || [ "$http_code" -ge 300 ]; then
    echo "ERROR: PATCH ${path} returned HTTP ${http_code}: ${body}" >&2
    exit 1
  fi
}

# Pre-flight: verify API reachability and credentials
echo "API:  ${API}"
echo "Repo: ${REPO_PATH}"
REPO_CHECK=$(api_get "repos/${REPO_PATH}" 2>&1) || {
  echo "ERROR: could not reach ${API}/repos/${REPO_PATH}" >&2
  echo "Response: ${REPO_CHECK}" >&2
  exit 1
}
echo "Repo confirmed: $(printf '%s' "$REPO_CHECK" | jq -r '.full_name')"
echo ""

ALL_MILESTONES=$(api_get "repos/${REPO_PATH}/milestones?state=all&limit=50")

find_milestone() {
  printf '%s' "$ALL_MILESTONES" \
    | jq -r --arg t "$1" '.[] | select(.title == $t) | {id: .id, state: .state} | @json' \
    | head -1
}

COMMENT_BODY="### Milestone Progress

Phase gate checklist status:
"

for ROADMAP_FILE in $(ls "${REPO_ROOT}/docs/roadmap/phase-"*.md | sort); do
  PHASE_TITLE=$(grep -m1 '^# ' "$ROADMAP_FILE" | sed 's/^# //')

  read -r CHECKED TOTAL <<< "$(awk '
    /^## Phase Gate Checklist/ { in_s=1; next }
    in_s && /^## /             { exit }
    in_s && /^[[:space:]]*- \[[ x]\]/ { total++ }
    in_s && /^[[:space:]]*- \[x\]/    { checked++ }
    END { print checked+0, total+0 }
  ' "$ROADMAP_FILE")"

  [ "$TOTAL" -eq 0 ] && continue

  WANT_STATE="open"
  [ "$CHECKED" -ge "$TOTAL" ] && WANT_STATE="closed"
  DESC="Progress: ${CHECKED}/${TOTAL} phase gate checklist items complete."

  EXISTING=$(find_milestone "$PHASE_TITLE")

  if [ -z "$EXISTING" ] || [ "$EXISTING" = "null" ]; then
    echo "Creating milestone '${PHASE_TITLE}' (${CHECKED}/${TOTAL})"
    CREATED=$(api_post "repos/${REPO_PATH}/milestones" \
      "$(jq -n --arg t "$PHASE_TITLE" --arg d "$DESC" '{"title":$t,"description":$d}')")
    MILESTONE_ID=$(printf '%s' "$CREATED" | jq -r '.id // empty')
    echo "  → API returned id=${MILESTONE_ID}"
  else
    MILESTONE_ID=$(printf '%s' "$EXISTING" | jq -r '.id')
    CURRENT_STATE=$(printf '%s' "$EXISTING" | jq -r '.state')
    echo "Found milestone '${PHASE_TITLE}' (${CHECKED}/${TOTAL}, currently ${CURRENT_STATE})"
  fi

  if [ -n "$MILESTONE_ID" ] && [ "$MILESTONE_ID" != "null" ]; then
    api_patch "repos/${REPO_PATH}/milestones/${MILESTONE_ID}" \
      "$(jq -n --arg d "$DESC" --arg s "$WANT_STATE" '{"description":$d,"state":$s}')"
    echo "  → state=${WANT_STATE}"
  fi

  STATUS_MARK="[ ]"
  [ "$WANT_STATE" = "closed" ] && STATUS_MARK="[x]"
  COMMENT_BODY="${COMMENT_BODY}
- ${STATUS_MARK} **${PHASE_TITLE}**: ${CHECKED}/${TOTAL} items"
done

if [ -n "$PR_NUMBER" ]; then
  api_post "repos/${REPO_PATH}/issues/${PR_NUMBER}/comments" \
    "$(jq -n --arg b "$COMMENT_BODY" '{"body":$b}')" \
    > /dev/null
  echo "Posted progress comment on PR #${PR_NUMBER}."
fi
