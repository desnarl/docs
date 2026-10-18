#!/usr/bin/env bash
# Guard for checklist 2.20.36 (docs half) — /.well-known/tdmrep.json on
# docs.desnarl.com. The content is copied unchanged from the engine repo's root
# tdmrep.json; the exact policy is pending counsel's question 4 (2.20.7), so
# this test pins the current content rather than the intent.
#
# Checks the source file, its Cloudflare Pages Content-Type rule, and (when a
# build exists) that Docusaurus carried the dotfolder into build/.
# Run directly: bash scripts/tests/tdmrep.test.sh

set -uo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${DIR}/../.." && pwd)"
FILE="${ROOT}/static/.well-known/tdmrep.json"
HEADERS="${ROOT}/static/_headers"
BUILT="${ROOT}/build/.well-known/tdmrep.json"

TESTS_RUN=0
TESTS_FAILED=0
check() { # check <exit-code> <desc>
  TESTS_RUN=$((TESTS_RUN + 1))
  if [ "$1" -eq 0 ]; then echo "  ok: $2"; else echo "  FAIL: $2"; TESTS_FAILED=$((TESTS_FAILED + 1)); fi
}

# The reservation, whitespace-insensitive.
EXPECTED='[{"location":"/*","tdm-reservation":1}]'
normalise() { tr -d ' \t\r\n' < "$1"; }

echo "static/.well-known/tdmrep.json"
[ -f "$FILE" ]; check $? "file exists"
[ "$(normalise "$FILE" 2>/dev/null)" = "$EXPECTED" ]; check $? "content is the TDM reservation for /*"

echo "static/_headers"
awk '/^\/\.well-known\/tdmrep\.json$/{p=1;next} p&&/^[^ \t]/{p=0} p' "$HEADERS" 2>/dev/null \
  | grep -qiE '^[ \t]+Content-Type:[ \t]*application/json'
check $? "tdmrep.json is served with a JSON Content-Type"

echo "build output (skipped if not built)"
if [ -d "${ROOT}/build" ]; then
  [ "$(normalise "$BUILT" 2>/dev/null)" = "$EXPECTED" ]; check $? "build/.well-known/tdmrep.json matches"
  [ -f "${ROOT}/build/_headers" ]; check $? "build/_headers present"
else
  echo "  skip: no build/ directory"
fi

echo "${TESTS_RUN} checks, ${TESTS_FAILED} failed"
[ "$TESTS_FAILED" -eq 0 ]
