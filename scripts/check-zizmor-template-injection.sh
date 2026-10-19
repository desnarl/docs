#!/usr/bin/env bash
# Fails on every zizmor `template-injection` finding (pedantic persona).
# The regular persona misses ${{ github.sha }} or ${{ github.repository }} in run:
# and pedantic's other rules are noise, so we filter pedantic JSON by ident.
# No allow-list: fix the line (env: or a default runner variable).
# Input: zizmor JSON on stdin, or workflow paths as args (runs ZIZMOR_BIN/zizmor).
# Exit 0 clean, 1 findings (file:line each), 2 unusable input or zizmor failure.

set -uo pipefail

fail() { echo "check-zizmor-template-injection: $1" >&2; exit 2; }

if [ "$#" -gt 0 ]; then
  ZIZMOR="${ZIZMOR_BIN:-zizmor}"
  INPUT="$("$ZIZMOR" --persona=pedantic --format=json --offline --collect=workflows --no-exit-codes -- "$@")" \
    || fail "zizmor failed to run"
else
  INPUT="$(cat)"
fi

printf '%s' "$INPUT" | python3 -I -c '
import json
import sys

def die(msg):
    print("check-zizmor-template-injection: " + msg, file=sys.stderr)
    sys.exit(2)

raw = sys.stdin.read()
if not raw.strip():
    die("empty input, expected zizmor JSON")
try:
    findings = json.loads(raw)
except ValueError as err:
    die("unparseable zizmor JSON: " + str(err))
if not isinstance(findings, list):
    die("expected a JSON array of zizmor findings")

def where(finding):
    for loc in finding.get("locations") or []:
        if not isinstance(loc, dict):
            continue
        symbolic = loc.get("symbolic") or {}
        if symbolic.get("kind") != "Primary":
            continue
        try:
            path = symbolic["key"]["Local"]["verbatim_path"]
            row = loc["concrete"]["location"]["start_point"]["row"]
        except (KeyError, TypeError):
            break
        if isinstance(path, str) and isinstance(row, int):
            return path + ":" + str(row + 1)
        break
    die("template-injection finding has no usable Primary location")

hits = []
for finding in findings:
    if not isinstance(finding, dict) or "ident" not in finding:
        die("array element is not a zizmor finding (no ident)")
    if finding["ident"] == "template-injection":
        hits.append(where(finding))

for hit in hits:
    print(hit + ": template-injection: move the expression into env: or use a default runner variable")
sys.exit(1 if hits else 0)
'
