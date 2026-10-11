#!/usr/bin/env bash
# Mechanized backstop for the project's non-negotiable "no AI attribution in
# commits or PRs" rule — added 2026-09-21 after the rule was violated twice
# in one desnarl/web + crossrepograph session despite being explicit and in
# context both times. Fails if any commit in the given git revision range
# contains AI-tool attribution in its message.
#
# Patterns matched, case-insensitive: a "Co-Authored-By:" trailer naming
# Claude, "Generated with ... Claude Code", or an @anthropic.com address
# (the strongest, lowest-false-positive signal, since it's not a word a
# human commit would plausibly contain for any other reason), or a
# claude.ai/code/session_ link (text mode only).
#
# Two modes:
#   check-no-ai-attribution.sh <git-rev-range>   commit messages in the range
#   check-no-ai-attribution.sh --text            PR_TITLE / PR_BODY from the
#       environment (never argv, so attacker-controlled text is never parsed
#       by a shell); unset or empty is treated as empty.

set -euo pipefail

MODE="${1:?usage: check-no-ai-attribution.sh <git-rev-range> | --text}"

PATTERN='(co-authored-by:.*claude|generated with.*claude code|anthropic\.com)'
TEXT_PATTERN="${PATTERN}|claude\.ai/code/session_"

# Check one PR text field; $1 = field name, $2 = its content. Matched lines are
# indented so an echoed line can never start with "::" and inject a workflow
# command.
check_text_field() {
  local field="$1" content="${2//$'\r'/}"
  if printf '%s\n' "$content" | grep -qiE -- "$TEXT_PATTERN"; then
    echo "::error::The PR ${field} contains AI-tool attribution, which is not allowed in this repo:"
    printf '%s\n' "$content" | grep -iE -- "$TEXT_PATTERN" | sed 's/^/    /' || true
    return 1
  fi
  return 0
}

if [ "$MODE" = "--text" ]; then
  FOUND=0
  check_text_field title "${PR_TITLE:-}" || FOUND=1
  check_text_field body "${PR_BODY:-}" || FOUND=1
  if [ "$FOUND" -eq 1 ]; then
    echo "Edit the offending text in the pull request description to remove the AI-tool attribution; no force-push is needed." >&2
    exit 1
  fi
  echo "No AI-tool attribution found in the PR title or body."
  exit 0
fi

RANGE="$MODE"

FOUND=0
while IFS= read -r sha; do
  [ -z "$sha" ] && continue
  msg=$(git log -1 --format=%B "$sha" 2>/dev/null || true)
  if printf '%s' "$msg" | grep -qiE "$PATTERN"; then
    echo "::error::Commit ${sha} contains AI-tool attribution, which is not allowed in this repo:"
    printf '%s\n' "$msg" | grep -iE "$PATTERN" || true
    FOUND=1
  fi
done < <(git log --format=%H "$RANGE" 2>/dev/null || true)

if [ "$FOUND" -eq 1 ]; then
  echo "One or more commits contain AI-tool attribution. Amend/rewrite them (and force-push if already pushed) before this can merge." >&2
  exit 1
fi

echo "No AI-tool attribution found in ${RANGE}."
