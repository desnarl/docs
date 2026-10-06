#!/usr/bin/env bash
# Failing-test spec for checklist 2.19.1(b) — .github/workflows/ci.yml wiring of
# the no-ai-attribution job's PR title/body check. A static text spec on the
# workflow file, same pattern as ci-yml-no-write-network-wiring.test.sh.
# Run directly: bash scripts/tests/ci-yml-no-ai-attribution-wiring.test.sh

set -uo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CI_YML="$(cd "${DIR}/../.." && pwd)/.github/workflows/ci.yml"

TESTS_RUN=0
TESTS_FAILED=0
check() { # check <exit-code> <desc>
  TESTS_RUN=$((TESTS_RUN + 1))
  if [ "$1" -eq 0 ]; then echo "  ok: $2"; else echo "  FAIL: $2"; TESTS_FAILED=$((TESTS_FAILED + 1)); fi
}

# The `on: pull_request:` block (from its key to the next top-level/2-space key).
ON_PR=$(awk '/^on:/{o=1;next} o&&/^[^ #]/{o=0} o' "$CI_YML" \
  | awk '/^  pull_request:/{p=1;print;next} p&&/^  [^ ]/{p=0} p')
# The whole no-ai-attribution job (to the next 2-space job key).
JOB=$(awk '/^  no-ai-attribution:/{j=1;print;next} j&&/^  [A-Za-z0-9_-]+:/{j=0} j' "$CI_YML")

echo "ci.yml: pull_request trigger types"
printf '%s\n' "$ON_PR" | grep -qE 'types: *\[ *opened, *edited, *synchronize, *reopened *\]'
check $? "pull_request has types: [opened, edited, synchronize, reopened]"

echo "ci.yml: no-ai-attribution job"
[ -n "$JOB" ]; check $? "no-ai-attribution job exists"
printf '%s\n' "$JOB" | grep -qE 'check-no-ai-attribution\.sh --text'
check $? "job runs check-no-ai-attribution.sh --text"
printf '%s\n' "$JOB" | grep -qE 'PR_TITLE: \$\{\{ github\.event\.pull_request\.title \}\}'
check $? "PR_TITLE is set from github.event.pull_request.title"
printf '%s\n' "$JOB" | grep -qE 'PR_BODY: \$\{\{ github\.event\.pull_request\.body \}\}'
check $? "PR_BODY is set from github.event.pull_request.body"

# Within the job, the title/body expressions may appear only on an `env:`
# mapping line (KEY: ${{ ... }}), never inside a run: script body.
INLINE=$(awk '
  /^ +run: *[|>]/ { inrun=1; match($0,/^ */); ind=RLENGTH; next }
  /^ +run: / { if ($0 ~ /github\.event\.pull_request\.(title|body)/) print; next }
  inrun { match($0,/^ */); if (RLENGTH <= ind && $0 !~ /^ *$/) inrun=0 }
  inrun && /github\.event\.pull_request\.(title|body)/ { print }
' <<<"$JOB")
[ -z "$INLINE" ]
check $? "title/body expressions never appear inside a run: block"
printf '%s\n' "$JOB" | grep -E 'github\.event\.pull_request\.(title|body)' | grep -qvE '^ +PR_(TITLE|BODY): '
[ $? -ne 0 ] && printf '%s\n' "$JOB" | grep -qE 'github\.event\.pull_request\.title'
check $? "every title/body expression sits on an env: mapping line (and at least one exists)"

echo "ci.yml: text step guarded to pull_request events"
STEP=$(awk '
  /^      - / { if (cur ~ /--text/) { print cur; exit } cur=$0; next }
  { cur = cur "\n" $0 }
  END { if (cur ~ /--text/) print cur }' <<<"$JOB")
[ -n "$STEP" ]; check $? "a distinct step runs the --text check"
printf '%s\n' "$STEP" | grep -qE "if: .*github\.event_name == 'pull_request'"
check $? "the --text step is guarded with if: github.event_name == 'pull_request'"

echo ""
echo "$((TESTS_RUN - TESTS_FAILED))/${TESTS_RUN} passed"
[ "$TESTS_FAILED" -gt 0 ] && exit 1
exit 0
