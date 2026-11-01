#!/usr/bin/env bash
# Failing-test spec for scripts/check-zizmor-template-injection.sh: fails on
# zizmor `template-injection` findings only. Stdin mode reads zizmor
# `--format=json` output; path-args mode runs zizmor (pedantic persona) itself.
# Exit 0 = none, 1 = findings (prints file:line), 2 = bad input or zizmor failure.

set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${DIR}/assert-helpers.sh"
SCRIPT="${DIR}/../check-zizmor-template-injection.sh"

OUT=""
STATUS=0
run_stdin() {
  OUT=$(printf '%s' "$1" | bash "$SCRIPT" 2>&1)
  STATUS=$?
}

# finding <ident> <file> <zero-based-row> [ignored]: realistic zizmor shape,
# with a Hidden location on a different row and a Related one after Primary.
finding() {
  local ident="$1" file="$2" row="$3" ignored="${4:-false}"
  local key="{\"Local\":{\"verbatim_path\":\"${file}\"}}"
  printf '{"ident":"%s","desc":"d","url":"u","determinations":{"confidence":"High","severity":"Low","persona":"Pedantic"},' "$ident"
  printf '"locations":['
  printf '{"symbolic":{"key":%s,"annotation":"this step","kind":"Hidden"},' "$key"
  printf '"concrete":{"location":{"start_point":{"row":0,"column":8},"end_point":{"row":1,"column":0}},"feature":"run","comments":[]}},'
  printf '{"symbolic":{"key":%s,"annotation":"x","kind":"Primary"},' "$key"
  printf '"concrete":{"location":{"start_point":{"row":%s,"column":23},"end_point":{"row":%s,"column":33}},"feature":"f","comments":[]}},' "$row" "$row"
  printf '{"symbolic":{"key":%s,"annotation":"y","kind":"Related"},' "$key"
  printf '"concrete":{"location":{"start_point":{"row":90,"column":1},"end_point":{"row":90,"column":2}},"feature":"g","comments":[]}}'
  printf '],"ignored":%s,"fixes":[]}' "$ignored"
}

echo "template-injection findings fail"
run_stdin "[$(finding template-injection bad.yml 7)]"
assert_exit_code 1 "$STATUS" "single finding exits 1"
assert_contains "$OUT" "bad.yml:8" "prints file:line (1-based, Primary location)"
assert_not_contains "$OUT" "bad.yml:1" "does not print the Hidden location row"
assert_not_contains "$OUT" "bad.yml:91" "does not print the Related location row"

run_stdin "[$(finding template-injection a.yml 2),$(finding template-injection dir/b.yml 11)]"
assert_exit_code 1 "$STATUS" "multiple findings exit 1"
assert_contains "$OUT" "a.yml:3" "lists first finding"
assert_contains "$OUT" "dir/b.yml:12" "lists second finding"

run_stdin "[$(finding template-injection bad.yml 7 true)]"
assert_exit_code 1 "$STATUS" "ignored:true still fails (no allow-list)"
assert_contains "$OUT" "bad.yml:8" "ignored finding is still listed"

echo "no template-injection findings pass"
run_stdin "[$(finding anonymous-definition w.yml 0),$(finding concurrency-limits w.yml 4)]"
assert_exit_code 0 "$STATUS" "only other idents exits 0"
run_stdin "[]"
assert_exit_code 0 "$STATUS" "empty array exits 0"

run_stdin "[$(finding concurrency-limits w.yml 4),$(finding template-injection bad.yml 7),$(finding anonymous-definition w.yml 0)]"
assert_exit_code 1 "$STATUS" "mixed findings exit 1"
assert_contains "$OUT" "bad.yml:8" "mixed: lists the template-injection finding"
assert_not_contains "$OUT" "w.yml" "mixed: does not list other idents"

echo "bad input exits 2 loudly"
BAD_INPUTS=("" "   
	" "{not json" '{"ident":"template-injection"}' '"str"' '[{"desc":"no ident"}]' '[1]')
BAD_NAMES=("empty" "whitespace-only" "malformed JSON" "non-array JSON (object)" "non-array JSON (string)" "element without ident" "non-object element")
for i in "${!BAD_INPUTS[@]}"; do
  run_stdin "${BAD_INPUTS[$i]}"
  assert_exit_code 2 "$STATUS" "${BAD_NAMES[$i]} exits 2"
  assert_not_contains "$OUT" "bad.yml:" "${BAD_NAMES[$i]} reports no findings"
done
run_stdin ""
assert_not_contains "$OUT" "No such file" "script exists"
assert_contains "$OUT" "zizmor" "error message is printed and names zizmor"

echo "path-args mode (real zizmor)"
if command -v zizmor >/dev/null 2>&1; then
  TMP="$(mktemp -d)"
  trap 'rm -rf "$TMP"' EXIT
  HEAD='name: t
on: push
permissions: {}
jobs:
  a:
    runs-on: ubuntu-latest
    steps:
'
  printf '%s      - run: echo "${{ github.sha }}"\n' "$HEAD" > "${TMP}/bad.yml"
  printf '%s      - env:\n          SHA: ${{ github.sha }}\n        run: echo "$SHA"\n' "$HEAD" > "${TMP}/good.yml"

  OUT=$(bash "$SCRIPT" "${TMP}/bad.yml" 2>&1); STATUS=$?
  assert_exit_code 1 "$STATUS" "inline expression in run: exits 1"
  assert_contains "$OUT" "bad.yml:8" "names the offending line"

  OUT=$(bash "$SCRIPT" "${TMP}/good.yml" 2>&1); STATUS=$?
  assert_exit_code 0 "$STATUS" "env: form exits 0"

  printf '#!/usr/bin/env bash\necho boom >&2\nexit 3\n' > "${TMP}/fail-stub"
  chmod +x "${TMP}/fail-stub"
  OUT=$(ZIZMOR_BIN="${TMP}/fail-stub" bash "$SCRIPT" "${TMP}/good.yml" 2>&1); STATUS=$?
  assert_exit_code 2 "$STATUS" "failing zizmor binary exits 2"

  printf '#!/usr/bin/env bash\necho "not json"\n' > "${TMP}/junk-stub"
  chmod +x "${TMP}/junk-stub"
  OUT=$(ZIZMOR_BIN="${TMP}/junk-stub" bash "$SCRIPT" "${TMP}/good.yml" 2>&1); STATUS=$?
  assert_exit_code 2 "$STATUS" "unparseable zizmor output exits 2"
else
  echo "  note: zizmor not on PATH; skipping path-args mode cases"
fi

report_and_exit
