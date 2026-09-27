#!/usr/bin/env bash
# Opens a scene in a real window (rendering needs a GPU, so not headless),
# waits some frames, saves a PNG and quits.
# Usage: tools/screenshot.sh <res://scene.tscn> <output.png> [frames=30] [WIDTHxHEIGHT=1280x800] [scene args...]
# Extra arguments are passed to the scene (read with OS.get_cmdline_user_args()),
# e.g. settings=/abs/path.json panel=1 for scenes/proto/diorama.tscn.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT="${GODOT_PATH:?GODOT_PATH is not set}"
SCENE="${1:?usage: tools/screenshot.sh <res://scene.tscn> <output.png> [frames] [WxH]}"
OUTPUT="${2:?usage: tools/screenshot.sh <res://scene.tscn> <output.png> [frames] [WxH]}"
FRAMES="${3:-30}"
RESOLUTION="${4:-1280x800}"
shift $(( $# < 4 ? $# : 4 ))

mkdir -p "$(dirname "$OUTPUT")"
OUTPUT_ABS="$(cd "$(dirname "$OUTPUT")" && pwd)/$(basename "$OUTPUT")"

# Shaders only compile on a real GPU, so this is also the check for shader
# errors: the run fails if Godot prints any error line.
LOG="$(mktemp)"
trap 'rm -f "$LOG"' EXIT
rm -f "$OUTPUT_ABS"
"$GODOT" --path "$ROOT" --resolution "$RESOLUTION" \
	--script res://scripts/dev/screenshot_runner.gd -- "$SCENE" "$OUTPUT_ABS" "$FRAMES" "$@" >"$LOG" 2>&1 || true
grep -E "saved" "$LOG" || true
if grep -E "ERROR|SCRIPT ERROR" "$LOG"; then
	echo "SCREENSHOT FAILED: errors above" >&2
	exit 1
fi
test -s "$OUTPUT_ABS"
