"""Remap an image to the base palette v1 (bible element 51), without dithering.

Each pixel becomes the palette color closest in OKLab (a perceptual color space),
so hue shifts stay small. Transparent pixels (alpha < 128) stay transparent.

Usage: uv run --with pillow python3 tools/palette_remap.py IN.png OUT.png [--palette assets/palette/palette_v1.png]
"""

import argparse
from pathlib import Path

from PIL import Image

DEFAULT_PALETTE = Path(__file__).resolve().parent.parent / "assets" / "palette" / "palette_v1.png"


def srgb_to_linear(c):
    c /= 255.0
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def oklab(rgb):
    r, g, b = (srgb_to_linear(float(v)) for v in rgb)
    l = 0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b
    m = 0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b
    s = 0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b
    l, m, s = l ** (1 / 3), m ** (1 / 3), s ** (1 / 3)
    return (
        0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
        1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
        0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s,
    )


def load_palette(path):
    strip = Image.open(path).convert("RGB")
    return [strip.getpixel((x, y)) for y in range(strip.height) for x in range(strip.width)]


def remap(image, palette):
    labs = [oklab(c) for c in palette]
    cache = {}
    src = image.convert("RGBA")
    out = Image.new("RGBA", src.size)
    for y in range(src.height):
        for x in range(src.width):
            r, g, b, a = src.getpixel((x, y))
            if a < 128:
                out.putpixel((x, y), (0, 0, 0, 0))
                continue
            key = (r, g, b)
            if key not in cache:
                lab = oklab(key)
                best = min(range(len(palette)), key=lambda i: sum((lab[k] - labs[i][k]) ** 2 for k in range(3)))
                cache[key] = palette[best]
            out.putpixel((x, y), cache[key] + (255,))
    return out


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("input")
    parser.add_argument("output")
    parser.add_argument("--palette", default=str(DEFAULT_PALETTE))
    args = parser.parse_args()
    result = remap(Image.open(args.input), load_palette(args.palette))
    if result.getchannel("A").getextrema() == (255, 255):
        result = result.convert("RGB")
    result.save(args.output)


if __name__ == "__main__":
    main()
