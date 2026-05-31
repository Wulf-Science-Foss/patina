#!/usr/bin/env bash
# commit-and-push.sh — Create a branch, commit changed files, and push it.
# Called exclusively by CI scripts (gate-checkoff.sh, etc.).
# Never run this directly during development.
#
# Usage:
#   bash scripts/commit-and-push.sh \
#     --branch <new-branch-name> \
#     --message "<commit message>" \
#     -- <file1> [file2 ...]
#
# Behaviour:
#   - Exits 0 without creating a branch or commit when none of the listed
#     files have changed relative to HEAD.
#   - Creates the branch from the current HEAD (must be on main when called).
#   - Signs the commit with ~/.ssh/signing_key when that file is present
#     (populated in CI by the prepare-ssh-signing action).
#   - Pushes the branch to origin.
#
# Security note:
#   Only invoke from workflows that run on merged PR events (not open PRs).
#   The checkout token must be scoped to content:write for this repository only.

set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

BRANCH_NAME=""
COMMIT_MSG=""
FILES=()
PARSE_FILES=0

while [[ $# -gt 0 ]]; do
  if [[ "$PARSE_FILES" -eq 1 ]]; then
    FILES+=("$1")
    shift
  else
    case "$1" in
      --branch)  BRANCH_NAME="$2"; shift 2 ;;
      --message) COMMIT_MSG="$2";  shift 2 ;;
      --)        PARSE_FILES=1;    shift   ;;
      *)         echo "ERROR: unknown option: $1" >&2; exit 1 ;;
    esac
  fi
done

if [[ -z "$BRANCH_NAME" ]]; then
  echo "ERROR: --branch is required" >&2; exit 1
fi
if [[ -z "$COMMIT_MSG" ]]; then
  echo "ERROR: --message is required" >&2; exit 1
fi
if [[ "${#FILES[@]}" -eq 0 ]]; then
  echo "ERROR: at least one file path required after --" >&2; exit 1
fi

cd "$REPO_ROOT"

if git diff --quiet -- "${FILES[@]}"; then
  echo "No changes detected — nothing to commit."
  exit 0
fi

git config user.name  "patina-ci[bot]"
git config user.email "ci@wulf.science"

# Use SSH signing when the CI key is present (set up by prepare-ssh-signing).
if [[ -f ~/.ssh/signing_key ]]; then
  git config gpg.format ssh
  git config user.signingkey ~/.ssh/signing_key
  git config commit.gpgsign true
  git config gpg.ssh.allowedSignersFile ~/.ssh/allowed_signers
fi

git checkout -b "$BRANCH_NAME"
git add -- "${FILES[@]}"
git commit -m "$COMMIT_MSG"
git push origin "$BRANCH_NAME"

echo "Branch '${BRANCH_NAME}' committed and pushed."
