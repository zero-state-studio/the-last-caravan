"""Garment masks for the generic crowd sprites (121): which pixels are
clothes, so the sprite shader can dye them in a trade colour.

Usage: uv run --with pillow python tools/crowd_garment_masks.py [folder]
  folder: default assets/sprites/folla. For every <name>.png (not *_mask)
  writes <name>_mask.png, same size: white where the pixel is clothing.

Clothing is decided by place, since skin and cloth share their tones:
every opaque, non-outline pixel between the head band (top of the figure:
face and hair; deeper for the short children) and the boots band (bottom),
except the hands: skin-toned pixels at the side ends of each row in the
arms' height.
"""

import colorsys
import sys
from pathlib import Path

from PIL import Image

CELL = 64
HEAD_SHARE = 0.23
CHILD_HEAD_SHARE = 0.35
CHILD_MAX_PIXELS = 46
BOOTS_SHARE = 0.08
OUTLINE_VALUE = 0.16
HAND_PIXELS = 4
ARMS_FROM = 0.35
ARMS_TO = 0.62


def _cells(rgba: Image.Image):
    """(x0, x1, top, bottom) of the figure in each 64-pixel cell."""
    width, height = rgba.size
    alpha = rgba.getchannel("A").load()
    for cell_x in range(0, width, CELL):
        x1 = min(cell_x + CELL, width)
        rows = [y for y in range(height) if any(alpha[x, y] > 128 for x in range(cell_x, x1))]
        if rows:
            yield cell_x, x1, min(rows), max(rows)


def _skin_like(r: int, g: int, b: int) -> bool:
    h, s, v = colorsys.rgb_to_hsv(r / 255.0, g / 255.0, b / 255.0)
    return (h < 0.12 or h > 0.97) and s > 0.25 and v > 0.4


def mask_for(image: Image.Image) -> Image.Image:
    rgba = image.convert("RGBA")
    width, height = rgba.size
    pixels = rgba.load()
    mask = Image.new("L", (width, height), 0)
    out = mask.load()
    for x0, x1, top, bottom in _cells(rgba):
        tall = bottom - top
        head_end = top + tall * (CHILD_HEAD_SHARE if tall < CHILD_MAX_PIXELS else HEAD_SHARE)
        boots_start = bottom - tall * BOOTS_SHARE
        for y in range(top, bottom + 1):
            if y < head_end or y > boots_start:
                continue
            row = [x for x in range(x0, x1) if pixels[x, y][3] > 128]
            if not row:
                continue
            arms = top + tall * ARMS_FROM <= y <= top + tall * ARMS_TO
            for x in row:
                r, g, b, a = pixels[x, y]
                if max(r, g, b) / 255.0 < OUTLINE_VALUE:
                    continue
                at_side = x - row[0] < HAND_PIXELS or row[-1] - x < HAND_PIXELS
                if arms and at_side and _skin_like(r, g, b):
                    continue
                out[x, y] = 255
    return mask


def main() -> None:
    folder = Path(sys.argv[1] if len(sys.argv) > 1 else "assets/sprites/folla")
    for path in sorted(folder.glob("*.png")):
        if path.stem.endswith("_mask"):
            continue
        mask_for(Image.open(path)).save(path.with_name(path.stem + "_mask.png"))
        print(path.name)


if __name__ == "__main__":
    main()
