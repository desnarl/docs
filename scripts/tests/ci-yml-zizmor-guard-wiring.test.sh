#!/usr/bin/env bash
# Failing-test spec for checklist 2.20.39: the zizmor job in ci.yml installs the
# pinned zizmor binary, then runs the template-injection guard and the script
# tests, and neither step can be skipped or made non-blocking. A static text spec
# on the workflow file.
# Run directly: bash scripts/tests/ci-yml-zizmor-guard-wiring.test.sh

set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${DIR}/assert-helpers.sh"
CI_YML="${DIR}/../../.github/workflows/ci.yml"

# zizmor_job: the `zizmor:` job's lines only, comments dropped.
zizmor_job() {
  awk '
    /^  [A-Za-z0-9_-]+:/ { on = ($0 ~ /^  zizmor:/) }
    on { print }' "$CI_YML" | grep -v '^ *#'
}
# step_block <name>: the zizmor job's step whose `- name:` is exactly <name>.
step_block() {
  zizmor_job | awk -v n="$1" '
    /^      - / { if (on) exit; on = ($0 ~ ("name: " n "$")) }
    on { print }'
}
step_line() { zizmor_job | grep -nE "^      - name: $1\$" | head -1 | cut -d: -f1; }

check_step() { # check_step <name> <run-command>
  local name="$1" cmd="$2" block
  block="$(step_block "$name")"
  echo "ci.yml zizmor job: step '${name}'"
  assert_contains "$block" "- name: ${name}" "the step exists"
  assert_contains "$block" "run: ${cmd}" "the step runs: ${cmd}"
  assert_contains "$block" 'if: ${{ !cancelled() }}' "the step runs even when an earlier step failed"
  assert_not_contains "$block" "continue-on-error" "the step is blocking"
}

echo "ci.yml zizmor job: step 'Install zizmor'"
INSTALL="$(step_block 'Install zizmor')"
assert_contains "$INSTALL" "- name: Install zizmor" "the install step exists"
assert_contains "$INSTALL" 'ZIZMOR_VERSION: "1.30.1"' "the release is pinned"
assert_contains "$INSTALL" "ZIZMOR_SHA256:" "the download is checksum-pinned"
assert_contains "$INSTALL" 'sha256sum -c -' "the checksum is verified"
assert_contains "$INSTALL" 'echo "${RUNNER_TEMP}/bin" >> "$GITHUB_PATH"' "zizmor is put on PATH"
assert_not_contains "$INSTALL" "continue-on-error" "the install step is blocking"

check_step "zizmor template-injection guard" 'bash scripts/check-zizmor-template-injection.sh .'
check_step "Script tests" 'bash scripts/tests/run-script-tests.sh'

echo "ci.yml zizmor job: ordering"
INSTALL_LINE="$(step_line 'Install zizmor')"
GUARD_LINE="$(step_line 'zizmor template-injection guard')"
TESTS_LINE="$(step_line 'Script tests')"
[ -n "$INSTALL_LINE" ] && [ -n "$GUARD_LINE" ] && [ "$GUARD_LINE" -gt "$INSTALL_LINE" ]
assert_exit_code 0 "$?" "the guard step comes after the install step"
[ -n "$TESTS_LINE" ] && [ -n "$INSTALL_LINE" ] && [ "$TESTS_LINE" -gt "$INSTALL_LINE" ]
assert_exit_code 0 "$?" "the script tests come after the install step"

report_and_exit
