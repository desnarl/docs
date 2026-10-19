#!/usr/bin/env bash
# Runs every *.test.sh file in this directory and reports a combined
# pass/fail summary. Mirrors .claude/hooks/tests/run-hook-tests.sh.

set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

FAILED=0
for test_file in "${DIR}"/*.test.sh; do
  [ -e "$test_file" ] || continue
  echo "=== $(basename "$test_file") ==="
  if ! bash "$test_file"; then
    FAILED=1
  fi
  echo ""
done

if [ "$FAILED" -ne 0 ]; then
  echo "Script tests FAILED"
  exit 1
fi

echo "All script tests passed"
exit 0
