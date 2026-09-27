"""Build Ottavia v1 deliverables from raw PixelLab frames.

Input:  source-assets/pixellab/2026-09-27-ottavia-v1-anim/frames/<anim>/<dir>/<NN>.png (64x64 RGBA)
        source-assets/pixellab/2026-09-27-ottavia-v1-rotations/{,fixed/}<dir>.png (approved rotations)
Output: source-assets/pixellab/2026-09-27-ottavia-v1-anim/clean/<anim>/<dir>/<NN>.png (checked frames)
        docs/screenshots/<date>-ottavia-v1-gif/*.gif (preview GIFs, 4x)
        report printed to stdout

Checks (tasks 49, 36):
- alpha is binary (semi-transparent pixels snapped to 0/255)
- every colour belongs to the master palette taken from the approved rotations
  (off-palette pixels are remapped to the nearest master colour)
- outer contour: every opaque pixel touching transparency is dark; dark contour
  pixels are unified to the outline colour of the reference palette
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
ANIM_DIR = ROOT / "source-assets/pixellab/2026-09-27-ottavia-v1-anim"
ROT_DIR = ROOT / "source-assets/pixellab/2026-09-27-ottavia-v1-rotations"
SOUTH_DEF = ROOT / "source-assets/pixellab/2026-09-26-ottavia-v1-south/ottavia_south_v1_definitiva.png"

ANIMS = ["idle", "walk"]
DIRS = ["s", "se", "e", "ne", "n", "nw", "w", "sw"]
PIXELLAB_DIR = {"s": "south", "se": "south-east", "e": "east", "ne": "north-east",
                "n": "north", "nw": "north-west", "w": "west", "sw": "south-west"}
FRAME_MS = {"idle": 160, "walk": 100}
SIZE = 64

OUTLINE = (0x1E, 0x1A, 0x33)
REFERENCE_PALETTE = {
    "cappotto": (0x3B, 0x41, 0x63), "sbiadito": (0xB8, 0xAD, 0x98), "corda": (0xC9, 0xA9, 0x6E),
    "sciarpa": (0x2E, 0x5B, 0x5E), "capelli": (0x8A, 0x8C, 0x96), "lanterna": (0xFF, 0xC4, 0x6B),
    "contorno": OUTLINE,
}
DARK_LUMA = 60.0          # a contour pixel darker than this counts as outline
PALETTE_TOLERANCE = 0     # exact match with master palette required, otherwise remap
GIF_SCALE = 4
GIF_BG = (104, 108, 122)


def luma(c: tuple[int, int, int]) -> float:
    return 0.299 * c[0] + 0.587 * c[1] + 0.114 * c[2]


def dist2(a: tuple[int, int, int], b: tuple[int, int, int]) -> int:
    return (a[0] - b[0]) ** 2 + (a[1] - b[1]) ** 2 + (a[2] - b[2]) ** 2


def rotation_path(d: str) -> Path:
    name = PIXELLAB_DIR[d]
    fixed = ROT_DIR / "fixed" / f"{name}.png"
    return fixed if fixed.exists() else ROT_DIR / f"{name}.png"


def master_palette() -> set[tuple[int, int, int]]:
    pal: set[tuple[int, int, int]] = {OUTLINE}
    for path in [SOUTH_DEF] + [rotation_path(d) for d in DIRS]:
        im = Image.open(path).convert("RGBA")
        pal.update(px[:3] for px in im.getdata() if px[3] >= 128)
    return pal


def center_crop(im: Image.Image) -> tuple[Image.Image, int]:
    """PixelLab v3 pads the canvas symmetrically; crop back to SIZE and count lost pixels."""
    im = im.convert("RGBA")
    ox, oy = (im.width - SIZE) // 2, (im.height - SIZE) // 2
    lost = sum(1 for y in range(im.height) for x in range(im.width)
               if im.getpixel((x, y))[3] and not (ox <= x < ox + SIZE and oy <= y < oy + SIZE))
    return im.crop((ox, oy, ox + SIZE, oy + SIZE)), lost


def clean_frame(im: Image.Image, pal: list[tuple[int, int, int]], cache: dict) -> tuple[Image.Image, dict]:
    im, lost = center_crop(im)
    w, h = im.size
    px = im.load()
    stats = {"clipped": lost, "semi_alpha": 0, "off_palette": 0, "light_contour": 0, "outline_unified": 0}
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if 0 < a < 255:
                stats["semi_alpha"] += 1
                a = 255 if a >= 128 else 0
            if a == 0:
                px[x, y] = (0, 0, 0, 0)
                continue
            c = (r, g, b)
            if c not in cache:
                cache[c] = min(pal, key=lambda p: dist2(p, c))
            if cache[c] != c:
                stats["off_palette"] += 1
            px[x, y] = cache[c] + (255,)
    for y in range(h):
        for x in range(w):
            if px[x, y][3] == 0:
                continue
            edge = any(not (0 <= x + dx < w and 0 <= y + dy < h) or px[x + dx, y + dy][3] == 0
                       for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))
            if not edge:
                continue
            c = px[x, y][:3]
            if luma(c) > DARK_LUMA:
                stats["light_contour"] += 1
            elif c != OUTLINE:
                px[x, y] = OUTLINE + (255,)
                stats["outline_unified"] += 1
    return im, stats


def save_gif(frames: list[Image.Image], ms: int, path: Path) -> None:
    out = []
    for f in frames:
        bg = Image.new("RGBA", f.size, GIF_BG + (255,))
        bg.alpha_composite(f)
        out.append(bg.convert("RGB").resize((f.width * GIF_SCALE, f.height * GIF_SCALE), Image.NEAREST))
    out[0].save(path, save_all=True, append_images=out[1:], duration=ms, loop=0, optimize=False)


def main() -> int:
    gif_dir = ROOT / sys.argv[1] if len(sys.argv) > 1 else ROOT / "docs/screenshots/ottavia-v1-gif"
    gif_dir.mkdir(parents=True, exist_ok=True)
    pal_set = master_palette()
    pal = sorted(pal_set)
    cache: dict = {}
    report: dict = {"master_palette_size": len(pal), "frames": {}}
    clean: dict[str, dict[str, list[Image.Image]]] = {}
    for anim in ANIMS:
        clean[anim] = {}
        for d in DIRS:
            src = sorted((ANIM_DIR / "frames" / anim / d).glob("*.png"))
            if not src:
                print(f"MISSING {anim}/{d}")
                return 1
            out_dir = ANIM_DIR / "clean" / anim / d
            out_dir.mkdir(parents=True, exist_ok=True)
            frames = []
            for i, p in enumerate(src):
                im, st = clean_frame(Image.open(p), pal, cache)
                im.save(out_dir / f"{i:02d}.png")
                frames.append(im)
                report["frames"][f"{anim}_{d}_{i:02d}"] = st
            clean[anim][d] = frames
            save_gif(frames, FRAME_MS[anim], gif_dir / f"ottavia_v1_{anim}_{d}.gif")
    # summary grids: 4 x 2, all directions animating together
    for anim in ANIMS:
        n = min(len(clean[anim][d]) for d in DIRS)
        grid_frames = []
        for i in range(n):
            g = Image.new("RGBA", (64 * 4, 64 * 2), (0, 0, 0, 0))
            for k, d in enumerate(DIRS):
                g.alpha_composite(clean[anim][d][i], ((k % 4) * 64, (k // 4) * 64))
            grid_frames.append(g)
        save_gif(grid_frames, FRAME_MS[anim], gif_dir / f"ottavia_v1_{anim}_griglia.gif")
    # colour usage vs reference palette
    used = set()
    for anim in ANIMS:
        for d in DIRS:
            for f in clean[anim][d]:
                used.update(px[:3] for px in f.getdata() if px[3])
    report["used_colours"] = len(used)
    report["reference_nearest"] = {
        k: "#%02X%02X%02X" % min(used, key=lambda c: dist2(c, v)) + f" (dist {min(dist2(c, v) for c in used) ** 0.5:.1f})"
        for k, v in REFERENCE_PALETTE.items()
    }
    tot = {k: sum(s[k] for s in report["frames"].values()) for k in
           ("clipped", "semi_alpha", "off_palette", "light_contour", "outline_unified")}
    report["totals"] = tot
    (ANIM_DIR / "clean" / "report.json").write_text(json.dumps(report, indent=1))
    print(json.dumps({k: v for k, v in report.items() if k != "frames"}, indent=1))
    worst = sorted(report["frames"].items(), key=lambda kv: -kv[1]["light_contour"])[:5]
    print("most light-contour frames:", worst)
    return 0


if __name__ == "__main__":
    sys.exit(main())
