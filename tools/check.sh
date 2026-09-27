#!/usr/bin/env bash
# Headless check: imports resources, then runs tests/run_tests.gd
# (project settings, input map, translations, loads every scene and script)
# and every tests/test_*.gd script.
# Fails on non-zero exit codes and on any error line printed by Godot.
# Usage: tools/check.sh
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT="${GODOT_PATH:?GODOT_PATH is not set}"
LOG_DIR="$(mktemp -d)"
trap 'rm -rf "$LOG_DIR"' EXIT
ERROR_PATTERN='SCRIPT ERROR|Parse Error|ERROR:|Failed to load|FAIL:'
status=0

echo "== import"
"$GODOT" --headless --path "$ROOT" --import >"$LOG_DIR/import.log" 2>&1 || status=1
grep -E "$ERROR_PATTERN" "$LOG_DIR/import.log" && status=1

echo "== tests"
: >"$LOG_DIR/tests.log"
for test_script in run_tests.gd $(cd "$ROOT/tests" && ls test_*.gd 2>/dev/null); do
	"$GODOT" --headless --path "$ROOT" --script "res://tests/$test_script" >>"$LOG_DIR/tests.log" 2>&1 || status=1
done
grep -E "^TESTS:" "$LOG_DIR/tests.log"
grep -E "$ERROR_PATTERN" "$LOG_DIR/tests.log" && status=1

if [ "$status" -eq 0 ]; then
	echo "CHECK OK"
else
	echo "CHECK FAILED"
	echo "--- import log"; cat "$LOG_DIR/import.log"
	echo "--- tests log"; cat "$LOG_DIR/tests.log"
fi
exit "$status"
