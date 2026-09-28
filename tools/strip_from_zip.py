"""Horizontal animation strips (64x64 cells, feet on row 60) from an
extracted PixelLab character zip, for NpcSprite (frame_count cells).

Every frame is placed centred, all frames of a strip on the same baseline
(the lowest opaque row among them), so the character does not bob.

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


def main() -> int:
    root = Path(sys.argv[1]) / "Idle" / "animations" / sys.argv[2]
    prefix = sys.argv[3]
    dirs = sys.argv[4:] or sorted(p.name for p in root.iterdir() if p.is_dir())
    for d in dirs:
        frames = [Image.open(p).convert("RGBA") for p in sorted((root / d).glob("*.png"))]
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
