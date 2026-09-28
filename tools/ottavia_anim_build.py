"""Clean new Ottavia animations (phase 4a, step 2) with the v1 pipeline.

Input:  a PixelLab character zip, extracted: <zipdir>/Idle/animations/<anim>/<direction>/frame_NNN.png
Output: source-assets/pixellab/2026-09-28-ottavia-anim/clean/<anim>/<dir>/<NN>.png (checked frames)
        docs/screenshots/asset/personaggi/ottavia-v1/<gif_dir>/<anim>_griglia.gif (4x2 grid, 4x)
        docs/screenshots/asset/personaggi/ottavia-v1/<gif_dir>/tutte_griglia.gif (every animation, one row each)
        report printed to stdout (clipped pixels per animation: what falls outside the 64x64 cell)

Same checks as tools/ottavia_v1_build.py (palette of the approved rotations,
binary alpha, unified outline, centre crop to 64x64).

Usage: uv run --with pillow python3 tools/ottavia_anim_build.py <zipdir> <gif_dir_name> anim[:ms] ...
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import ottavia_v1_build as v1  # noqa: E402

ROOT = v1.ROOT
OUT_DIR = ROOT / "source-assets/pixellab/2026-09-28-ottavia-anim"
GIF_ROOT = ROOT / "docs/screenshots/asset/personaggi/ottavia-v1"
DEFAULT_MS = 100


def main() -> int:
    zip_dir = Path(sys.argv[1])
    gif_dir = GIF_ROOT / sys.argv[2]
    gif_dir.mkdir(parents=True, exist_ok=True)
    specs = [arg.split(":") for arg in sys.argv[3:]]
    pal = sorted(v1.master_palette())
    cache: dict = {}
    report: dict = {}
    rows: list[tuple[str, int, list[list[Image.Image]]]] = []
    for spec in specs:
        anim = spec[0]
        ms = int(spec[1]) if len(spec) > 1 else DEFAULT_MS
        src_root = zip_dir / "Idle" / "animations" / anim
        dirs = [d for d in v1.DIRS if (src_root / v1.PIXELLAB_DIR[d]).is_dir()]
        clipped = 0
        per_dir: list[list[Image.Image]] = []
        for d in dirs:
            out = OUT_DIR / "clean" / anim / d
            out.mkdir(parents=True, exist_ok=True)
            frames = []
            for i, path in enumerate(sorted((src_root / v1.PIXELLAB_DIR[d]).glob("*.png"))):
                im, stats = v1.clean_frame(Image.open(path), pal, cache)
                im.save(out / f"{i:02d}.png")
                clipped += stats["clipped"]
                frames.append(im)
            per_dir.append(frames)
        report[anim] = {"directions": dirs, "frames": len(per_dir[0]) if per_dir else 0, "clipped_pixels": clipped}
        rows.append((anim, ms, per_dir))
        n = min(len(f) for f in per_dir)
        grid = []
        for i in range(n):
            g = Image.new("RGBA", (64 * 4, 64 * ((len(per_dir) + 3) // 4)), (0, 0, 0, 0))
            for k, frames in enumerate(per_dir):
                g.alpha_composite(frames[i], ((k % 4) * 64, (k // 4) * 64))
            grid.append(g)
        v1.save_gif(grid, ms, gif_dir / f"{anim}_griglia.gif")
    # Every animation in one GIF: one row per animation, eight directions per row.
    longest = max(len(r[2][0]) for r in rows)
    sheet = []
    for i in range(longest):
        g = Image.new("RGBA", (64 * 8, 64 * len(rows)), (0, 0, 0, 0))
        for r, (_, _, per_dir) in enumerate(rows):
            for k, frames in enumerate(per_dir):
                g.alpha_composite(frames[i % len(frames)], (k * 64, r * 64))
        sheet.append(g)
    v1.save_gif(sheet, DEFAULT_MS, gif_dir / "tutte_griglia.gif")
    print(json.dumps(report, indent=1))
    return 0


if __name__ == "__main__":
    sys.exit(main())
