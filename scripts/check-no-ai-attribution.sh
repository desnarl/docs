#!/usr/bin/env bash
# Mechanized backstop for CLAUDE.md's non-negotiable "no AI attribution in
# commits or PRs" rule — added 2026-09-21 after the rule was violated twice
# in one Desnarl session despite being explicit and in context both times. Fails if any commit in the given git revision range
# contains AI-tool attribution in its message.
#
# Patterns matched, case-insensitive: a "Co-Authored-By:" trailer naming
# Claude, "Generated with ... Claude Code", or an @anthropic.com address
# (the strongest, lowest-false-positive signal, since it's not a word a
# human commit would plausibly contain for any other reason).
#
# Two modes:
#   check-no-ai-attribution.sh <git-rev-range>   commit messages in the range
#   check-no-ai-attribution.sh --text            PR title and body, read from
#                                                the PR_TITLE and PR_BODY
#                                                environment variables (never
#                                                argv, so PR text is never
#                                                parsed as shell); unset or
#                                                empty is fine. Also matches a
#                                                claude.ai/code/session_ link.

set -euo pipefail

PATTERN='(co-authored-by:.*claude|generated with.*claude code|anthropic\.com)'

if [ "${1:-}" = "--text" ]; then
  TEXT_PATTERN='(co-authored-by:.*claude|generated with.*claude code|anthropic\.com|claude\.ai/code/session_)'
  FOUND=0
  for field in title body; do
    case "$field" in
      title) text="${PR_TITLE:-}" ;;
      body) text="${PR_BODY:-}" ;;
    esac
    text=$(printf '%s' "$text" | tr -d '\r')
    if printf '%s' "$text" | grep -qiE "$TEXT_PATTERN"; then
      echo "::error::The PR ${field} contains AI-tool attribution, which is not allowed in this repo:"
      # Indent echoed lines so a line starting "::" cannot become a workflow command.
      printf '%s\n' "$text" | grep -iE "$TEXT_PATTERN" | sed 's/^/  /' || true
      FOUND=1
    fi
  done
  if [ "$FOUND" -eq 1 ]; then
    echo "AI-tool attribution found in the PR text. Edit it before this can merge." >&2
    exit 1
  fi
  echo "No AI-tool attribution found in the PR title or body."
  exit 0
fi

RANGE="${1:?usage: check-no-ai-attribution.sh <git-rev-range> | --text}"

FOUND=0
while IFS= read -r sha; do
  [ -z "$sha" ] && continue
  msg=$(git log -1 --format=%B "$sha" 2>/dev/null || true)
  if printf '%s' "$msg" | grep -qiE "$PATTERN"; then
    echo "::error::Commit ${sha} contains AI-tool attribution, which is not allowed in this repo (see CLAUDE.md):"
    printf '%s\n' "$msg" | grep -iE "$PATTERN" || true
    FOUND=1
  fi
done < <(git log --format=%H "$RANGE" 2>/dev/null || true)

if [ "$FOUND" -eq 1 ]; then
  echo "One or more commits contain AI-tool attribution. Amend/rewrite them (and force-push if already pushed) before this can merge." >&2
  exit 1
fi

echo "No AI-tool attribution found in ${RANGE}."
