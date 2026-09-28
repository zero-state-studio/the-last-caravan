"""Build Ottavia's v2 spritesheet (19, 33): the v1 rows (idle, walk) plus the
phase 4a animations, one row per animation and direction.

Input:  assets/sprites/ottavia/ottavia_v1_sheet.png/.json, ottavia_v1_emission.png
        source-assets/pixellab/2026-09-28-ottavia-anim/clean/<anim>/<dir>/NN.png
Output: assets/sprites/ottavia/ottavia_v2_sheet.png   (COLUMNS x rows cells, 64x64)
        assets/sprites/ottavia/ottavia_v2_emission.png (white on the lantern glass)
        assets/sprites/ottavia/ottavia_v2_sheet.json
          "frames": one entry per cell, row-major, with "lantern": {x, y}
                    (cell pixels, the centre of the glass; empty cells copy the
                    last frame of their row), like the v1 data;
          "animations": {"<name>_<dir>": {"row", "frames", "ms", "loop"}}.

The glass is the topmost connected group of pixels in the lantern colours
(the same yellows appear on the buckle and the rope, lower down), as in
tools/lantern_mask.lua.

Usage: uv run --with pillow python3 tools/ottavia_sheet_v2.py
"""
from __future__ import annotations

import json
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SPRITES = ROOT / "assets/sprites/ottavia"
CLEAN = ROOT / "source-assets/pixellab/2026-09-28-ottavia-anim/clean"
SIZE = 64
COLUMNS = 12
DIRS = ["s", "se", "e", "ne", "n", "nw", "w", "sw"]
GLASS = {(0xFE, 0xF8, 0x8F), (0xFC, 0xBC, 0x3C), (0xFA, 0xCC, 0x69), (0xEC, 0xC0, 0x4E), (0xED, 0x9D, 0x2B)}
# name, frame duration (ms), loops
NEW_ANIMS = [
    ("run", 80, True), ("jump", 90, False), ("climb", 120, True), ("combo", 70, False),
    ("parry", 80, False), ("hurt", 80, False), ("breathless", 160, True),
    ("tie_rope", 120, False), ("give_hand", 140, False),
]


def glass_pixels(cell: Image.Image) -> list[tuple[int, int]]:
    px = cell.load()
    candidates = {(x, y) for y in range(SIZE) for x in range(SIZE) if px[x, y][3] and px[x, y][:3] in GLASS}
    groups = []
    while candidates:
        start = candidates.pop()
        group, todo = [start], [start]
        while todo:
            x, y = todo.pop()
            for dx in (-1, 0, 1):
                for dy in (-1, 0, 1):
                    n = (x + dx, y + dy)
                    if n in candidates:
                        candidates.remove(n)
                        group.append(n)
                        todo.append(n)
        groups.append(group)
    if not groups:
        return []
    return min(groups, key=lambda g: sum(p[1] for p in g) / len(g))


def main() -> int:
    v1_sheet = Image.open(SPRITES / "ottavia_v1_sheet.png").convert("RGBA")
    v1_mask = Image.open(SPRITES / "ottavia_v1_emission.png").convert("RGBA")
    v1_data = json.loads((SPRITES / "ottavia_v1_sheet.json").read_text())
    rows: list[tuple[str, list[Image.Image], list[dict] | None, int, bool]] = []
    # v1 rows: idle and walk, eight directions each, with their lantern points.
    for anim_index, (anim, ms) in enumerate((("idle", 160), ("walk", 100))):
        for d_index, d in enumerate(DIRS):
            row = anim_index * 8 + d_index
            cells = [v1_sheet.crop((c * SIZE, row * SIZE, (c + 1) * SIZE, (row + 1) * SIZE)) for c in range(8)]
            lanterns = [v1_data["frames"][row * 8 + c]["lantern"] for c in range(8)]
            rows.append((f"{anim}_{d}", cells, lanterns, ms, True))
    for anim, ms, loop in NEW_ANIMS:
        for d in DIRS:
            folder = CLEAN / anim / d
            if not folder.is_dir():
                continue
            cells = [Image.open(p).convert("RGBA") for p in sorted(folder.glob("*.png"))]
            rows.append((f"{anim}_{d}", cells, None, ms, loop))
    sheet = Image.new("RGBA", (COLUMNS * SIZE, len(rows) * SIZE), (0, 0, 0, 0))
    mask = Image.new("RGBA", sheet.size, (0, 0, 0, 0))
    frames: list[dict] = []
    animations: dict[str, dict] = {}
    missing_glass = 0
    for r, (name, cells, lanterns, ms, loop) in enumerate(rows):
        animations[name] = {"row": r, "frames": len(cells), "ms": ms, "loop": loop}
        last = {"x": 32.0, "y": 10.0}
        for c in range(COLUMNS):
            if c < len(cells):
                cell = cells[c]
                sheet.alpha_composite(cell, (c * SIZE, r * SIZE))
                if lanterns is not None:
                    last = lanterns[c]
                    region = v1_mask.crop((c * SIZE, (r) * SIZE, (c + 1) * SIZE, (r + 1) * SIZE))
                    mask.alpha_composite(region, (c * SIZE, r * SIZE))
                else:
                    glass = glass_pixels(cell)
                    if glass:
                        last = {"x": round(sum(p[0] for p in glass) / len(glass) + 0.5, 1),
                                "y": round(sum(p[1] for p in glass) / len(glass) + 0.5, 1)}
                        for x, y in glass:
                            mask.putpixel((c * SIZE + x, r * SIZE + y), (255, 255, 255, 255))
                    else:
                        missing_glass += 1
            frames.append({"filename": f"{name}_{c:02d}", "lantern": dict(last)})
    sheet.save(SPRITES / "ottavia_v2_sheet.png")
    mask.save(SPRITES / "ottavia_v2_emission.png")
    data = {"meta": {"cell": SIZE, "columns": COLUMNS, "rows": len(rows)}, "frames": frames, "animations": animations}
    (SPRITES / "ottavia_v2_sheet.json").write_text(json.dumps(data))
    print(f"{len(rows)} rows, sheet {sheet.size}, frames without glass: {missing_glass}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
