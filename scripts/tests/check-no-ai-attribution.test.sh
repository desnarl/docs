#!/usr/bin/env bash
# Failing-test spec for checklist 2.19.1 — scripts/check-no-ai-attribution.sh
# gains a text mode: `bash scripts/check-no-ai-attribution.sh --text`, reading
# PR_TITLE and PR_BODY from the ENVIRONMENT (never argv, so attacker-controlled
# PR text is never parsed as shell), unset/empty tolerated. Same PATTERN as the
# commit mode, plus `claude.ai/code/session_`. Commit mode must be unchanged.
#
# Self-contained assert helpers, same reason as the other scripts/tests/*.sh.
# Run directly: bash scripts/tests/check-no-ai-attribution.test.sh

set -uo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${DIR}/../.." && pwd)"
SCRIPT="${REPO_ROOT}/scripts/check-no-ai-attribution.sh"

TESTS_RUN=0
TESTS_FAILED=0

pass() { echo "  ok: $1"; }
fail() { echo "  FAIL: $1"; TESTS_FAILED=$((TESTS_FAILED + 1)); }

# assert_status <expected> <actual> <desc>
assert_status() {
  TESTS_RUN=$((TESTS_RUN + 1))
  if [ "$2" = "$1" ]; then pass "$3"; else fail "$3 (expected exit $1, got $2)"; fi
}

# assert_out_contains <output> <needle> <desc>
assert_out_contains() {
  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ "$1" == *"$2"* ]]; then pass "$3"; else fail "$3 (output lacked: $2)"; fi
}

assert_out_lacks() {
  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ "$1" != *"$2"* ]]; then pass "$3"; else fail "$3 (output contained: $2)"; fi
}

OUT=""
STATUS=0
# run_text <title-or-UNSET> <body-or-UNSET>: runs text mode with env only.
run_text() {
  local -a envs=()
  [ "$1" != "UNSET" ] && envs+=("PR_TITLE=$1")
  [ "$2" != "UNSET" ] && envs+=("PR_BODY=$2")
  OUT=$(cd "$REPO_ROOT" && env -u PR_TITLE -u PR_BODY ${envs[@]+"${envs[@]}"} bash "$SCRIPT" --text 2>&1)
  STATUS=$?
}

echo "text mode: title"
run_text "Co-Authored-By: Claude <noreply@anthropic.com>" "clean body"
assert_status 1 "$STATUS" "attribution in the title fails"
assert_out_contains "$OUT" "title" "error names the title field"
assert_out_contains "$OUT" "AI-tool attribution" "error keeps the 'AI-tool attribution' phrase"
assert_out_lacks "$OUT" "CLAUDE.md" "error text does not mention the agent-instructions file"
run_text "Generated with Claude Code" ""
assert_status 1 "$STATUS" "'Generated with ... Claude Code' title fails (empty body)"
run_text "Fix thing (see anthropic.com)" ""
assert_status 1 "$STATUS" "anthropic.com address in the title fails"

echo "text mode: body"
run_text "Clean title" "Summary

Generated with [Claude Code](https://claude.com/claude-code)"
assert_status 1 "$STATUS" "attribution in the body fails"
assert_out_contains "$OUT" "body" "error names the body field"
assert_out_lacks "$OUT" "CLAUDE.md" "body error text does not mention the agent-instructions file"
run_text "Clean title" "line one
line two
line three
Co-authored-by: Claude Opus <x@y.z>"
assert_status 1 "$STATUS" "hit on a later line of a multi-line body fails"

echo "text mode: session link"
run_text "Clean title" "https://claude.ai/code/session_01AbCdEf"
assert_status 1 "$STATUS" "claude.ai/code/session_ link in the body fails"
run_text "https://claude.ai/code/session_01AbCdEf" "clean"
assert_status 1 "$STATUS" "claude.ai/code/session_ link in the title fails"

echo "text mode: clean / empty / unset"
run_text "Add the thing (2.19.1)" "Adds a text mode.

- bullet one
- bullet two"
assert_status 0 "$STATUS" "clean title and body pass"
run_text "Clean title" ""
assert_status 0 "$STATUS" "empty body passes"
run_text "Clean title" "UNSET"
assert_status 0 "$STATUS" "unset PR_BODY (null body on a PR with no description) passes"
run_text "UNSET" "UNSET"
assert_status 0 "$STATUS" "both unset pass"
run_text "UNSET" "Co-Authored-By: Claude"
assert_status 1 "$STATUS" "unset title does not mask a body hit"

echo "text mode: title and body checked independently"
run_text "Co-Authored-By: Claude" "Generated with Claude Code"
assert_status 1 "$STATUS" "hit in both fails"
assert_out_contains "$OUT" "title" "both-hit output names the title"
assert_out_contains "$OUT" "body" "both-hit output names the body"
run_text "Clean title" "anthropic.com"
assert_out_lacks "$OUT" "PR title" "body-only hit does not blame the title"

echo "text mode: CRLF"
run_text "Clean title" $'Summary\r\n\r\nCo-Authored-By: Claude\r\n'
assert_status 1 "$STATUS" "CRLF body with a hit fails"
run_text "Clean title" $'Summary\r\n\r\nNothing to see\r\n'
assert_status 0 "$STATUS" "clean CRLF body passes"

echo "text mode: shell metacharacters never executed"
CANARY="$(mktemp -d)/canary"
META='Uses `touch '"$CANARY"'` and $(touch '"$CANARY"') ; touch '"$CANARY"' | cat && "quoted" '"'"'single'"'"' ${HOME} $PATH \ * ? > /dev/null'
run_text "Clean \`title\` \$(touch $CANARY)" "$META"
assert_status 0 "$STATUS" "clean body/title full of metacharacters and backticks pass"
TESTS_RUN=$((TESTS_RUN + 1))
if [ ! -e "$CANARY" ]; then pass "nothing in the body/title was executed"; else fail "metacharacter content was executed (canary created)"; fi
run_text "Clean title" "$META
Co-Authored-By: Claude"
assert_status 1 "$STATUS" "metacharacter body that also contains a hit still fails"
TESTS_RUN=$((TESTS_RUN + 1))
if [ ! -e "$CANARY" ]; then pass "nothing executed on the failing path either"; else fail "metacharacter content executed on failing path"; fi

echo "text mode: workflow-command injection via matched output"
run_text "Clean title" $'::add-mask::secret\n::error::fake anthropic.com\n::set-output name=x::y anthropic.com'
assert_status 1 "$STATUS" "body with leading '::' lines containing a hit fails"
BAD_LINES=$(printf '%s\n' "$OUT" | grep -c -E '^::' || true)
TESTS_RUN=$((TESTS_RUN + 1))
if [ "${BAD_LINES:-0}" -le 1 ]; then pass "at most the script's own ::error:: line begins with '::'"; else fail "echoed body lines begin with '::' ($BAD_LINES lines)"; fi
TESTS_RUN=$((TESTS_RUN + 1))
if printf '%s\n' "$OUT" | grep -qE '^::(add-mask|set-output|warning|notice|debug|stop-commands)'; then fail "an injected workflow command starts a line"; else pass "no injected workflow command starts a line"; fi

echo "commit mode unchanged"
REPO="$(mktemp -d)"
git -C "$REPO" init -q -b main
git -C "$REPO" config user.email t@example.com
git -C "$REPO" config user.name t
git -C "$REPO" config commit.gpgsign false
git -C "$REPO" commit -q --allow-empty -m "base"
BASE=$(git -C "$REPO" rev-parse HEAD)
git -C "$REPO" commit -q --allow-empty -m "clean commit"
OUT=$(cd "$REPO" && bash "$SCRIPT" "${BASE}..HEAD" 2>&1); STATUS=$?
assert_status 0 "$STATUS" "clean commit range passes"
assert_out_contains "$OUT" "No AI-tool attribution found" "clean range prints the success line"
git -C "$REPO" commit -q --allow-empty -m "bad commit" -m "Co-Authored-By: Claude <noreply@anthropic.com>"
OUT=$(cd "$REPO" && bash "$SCRIPT" "${BASE}..HEAD" 2>&1); STATUS=$?
assert_status 1 "$STATUS" "commit range with attribution fails"
assert_out_contains "$OUT" "::error::Commit " "commit-mode error keeps the ::error::Commit ... format"
assert_out_contains "$OUT" "contains AI-tool attribution" "commit-mode error keeps its message"
OUT=$(cd "$REPO" && bash "$SCRIPT" 2>&1); STATUS=$?
assert_status 1 "$STATUS" "no argument and no --text still errors with usage"

echo ""
echo "$((TESTS_RUN - TESTS_FAILED))/${TESTS_RUN} passed"
[ "$TESTS_FAILED" -gt 0 ] && exit 1
exit 0
