#!/usr/bin/env bash
set -eu

# Load credentials
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# shellcheck source=../.env
source "${SCRIPT_DIR}/../.env"

usage() {
  echo "Usage: $(basename "$0") --title <title> [--head <branch>] [--base <branch>] [--body <text>]"
  echo ""
  echo "  --title  PR title (required)"
  echo "  --head   source branch (default: current branch)"
  echo "  --base   target branch (default: main)"
  echo "  --body   PR description (default: empty)"
  exit 1
}

TITLE=""
HEAD=$(git symbolic-ref --short HEAD)
BASE="main"
BODY=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --title) TITLE="$2"; shift 2 ;;
    --head)  HEAD="$2";  shift 2 ;;
    --base)  BASE="$2";  shift 2 ;;
    --body)  BODY="$2";  shift 2 ;;
    *) usage ;;
  esac
done

[ -z "$TITLE" ] && usage

PAYLOAD=$(jq -n \
  --arg title "$TITLE" \
  --arg head  "$HEAD" \
  --arg base  "$BASE" \
  --arg body  "$BODY" \
  '{"title":$title,"head":$head,"base":$base,"body":$body}')

RESPONSE=$(curl -s -X POST \
  "${FORGEJO_URL}/api/v1/repos/${FORGEJO_OWNER}/${FORGEJO_REPO}/pulls" \
  -H "Authorization: token ${FORGEJO_TOKEN}" \
  -H "Content-Type: application/json" \
  --data-binary "$PAYLOAD")

URL=$(printf '%s' "$RESPONSE" | jq -r '.html_url // empty')

if [ -n "$URL" ]; then
  echo "PR created: $URL"
else
  echo "Error: $RESPONSE" >&2
  exit 1
fi
