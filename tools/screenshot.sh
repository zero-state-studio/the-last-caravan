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

"$GODOT" --path "$ROOT" --resolution "$RESOLUTION" \
	--script res://scripts/dev/screenshot_runner.gd -- "$SCENE" "$OUTPUT_ABS" "$FRAMES" "$@"
test -s "$OUTPUT_ABS"
