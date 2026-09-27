"""Numbered contact sheet of tileable textures: each one alone (2x) and tiled 3x3 (1x),
so seams and repetition can be judged.

Usage: uv run --with pillow python3 tools/texture_sheet.py OUT.png TEXTURE.png [TEXTURE.png ...] [--columns 2]
The label is the file name without extension (e.g. "07_roccia_parete").
"""

import argparse
from pathlib import Path

from PIL import Image, ImageDraw

BACKGROUND = (24, 22, 30)
TEXT = (235, 228, 214)
LABEL_HEIGHT = 22
GAP = 16


def cell(path):
    tile = Image.open(path).convert("RGB")
    w, h = tile.size
    single = tile.resize((w * 2, h * 2), Image.NEAREST)
    tiled = Image.new("RGB", (w * 3, h * 3))
    for i in range(3):
        for j in range(3):
            tiled.paste(tile, (i * w, j * h))
    width = single.width + 8 + tiled.width
    height = LABEL_HEIGHT + max(single.height, tiled.height)
    out = Image.new("RGB", (width, height), BACKGROUND)
    draw = ImageDraw.Draw(out)
    colors = len(tile.getcolors(1 << 16) or [])
    draw.text((2, 4), f"{Path(path).stem}   {w}x{h}, {colors} colori", fill=TEXT)
    out.paste(single, (0, LABEL_HEIGHT))
    out.paste(tiled, (single.width + 8, LABEL_HEIGHT))
    return out


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("output")
    parser.add_argument("textures", nargs="+")
    parser.add_argument("--columns", type=int, default=2)
    args = parser.parse_args()
    cells = [cell(p) for p in args.textures]
    cw = max(c.width for c in cells)
    ch = max(c.height for c in cells)
    rows = (len(cells) + args.columns - 1) // args.columns
    sheet = Image.new("RGB", (args.columns * (cw + GAP) + GAP, rows * (ch + GAP) + GAP), BACKGROUND)
    for index, c in enumerate(cells):
        x = GAP + (index % args.columns) * (cw + GAP)
        y = GAP + (index // args.columns) * (ch + GAP)
        sheet.paste(c, (x, y))
    sheet.save(args.output)
    print(f"{args.output}: {len(cells)} textures, {sheet.width}x{sheet.height}")


if __name__ == "__main__":
    main()
