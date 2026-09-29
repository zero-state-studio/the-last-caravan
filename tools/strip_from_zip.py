"""Horizontal animation strips (64x64 cells, feet on row 60) from an
extracted PixelLab character zip, for NpcSprite (frame_count cells).

Every frame is placed centred, all frames of a strip on the same baseline
(the lowest opaque row among them), so the character does not bob.
Some generated frames come with an opaque flat background: when the four
corners of a frame are opaque and of one colour, that colour is flooded
away from the edges.

Usage: uv run --with pillow python3 tools/strip_from_zip.py <zipdir> <animation> <out_prefix> [dir ...]
  dir: pixellab directions (south, west, ...); default all found.
  Writes <out_prefix>_<short dir>.png (s, se, e, ne, n, nw, w, sw).
"""
from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image

SHORT = {"south": "s", "south-east": "se", "east": "e", "north-east": "ne",
         "north": "n", "north-west": "nw", "west": "w", "south-west": "sw"}
CELL = 64
BASELINE = 60
KEY_TOLERANCE = 10


def drop_flat_background(frame: Image.Image) -> Image.Image:
    """Clear an opaque flat background reaching the frame's edges."""
    width, height = frame.size
    pixels = frame.load()
    corners = [pixels[0, 0], pixels[width - 1, 0], pixels[0, height - 1], pixels[width - 1, height - 1]]
    if any(corner[3] < 255 for corner in corners):
        return frame
    key = corners[0]
    if any(max(abs(corner[i] - key[i]) for i in range(3)) > KEY_TOLERANCE for corner in corners):
        return frame
    frame = frame.copy()
    pixels = frame.load()
    stack = [(x, y) for x in range(width) for y in (0, height - 1)] + [(x, y) for x in (0, width - 1) for y in range(height)]
    seen = set()
    while stack:
        x, y = stack.pop()
        if (x, y) in seen or not (0 <= x < width and 0 <= y < height):
            continue
        seen.add((x, y))
        pixel = pixels[x, y]
        if pixel[3] == 0 or max(abs(pixel[i] - key[i]) for i in range(3)) > KEY_TOLERANCE:
            continue
        pixels[x, y] = (0, 0, 0, 0)
        stack.extend([(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)])
    return frame


def main() -> int:
    root = Path(sys.argv[1]) / "Idle" / "animations" / sys.argv[2]
    prefix = sys.argv[3]
    dirs = sys.argv[4:] or sorted(p.name for p in root.iterdir() if p.is_dir())
    for d in dirs:
        frames = [drop_flat_background(Image.open(p).convert("RGBA")) for p in sorted((root / d).glob("*.png"))]
        if not frames:
            print(f"missing {d}")
            continue
        bottom = max(f.getbbox()[3] for f in frames if f.getbbox())
        strip = Image.new("RGBA", (CELL * len(frames), CELL), (0, 0, 0, 0))
        for index, frame in enumerate(frames):
            strip.alpha_composite(frame, (index * CELL + CELL // 2 - frame.width // 2, BASELINE + 1 - bottom))
        out = Path(f"{prefix}_{SHORT[d]}.png")
        out.parent.mkdir(parents=True, exist_ok=True)
        strip.save(out)
        print(f"{out}: {len(frames)} frames")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
