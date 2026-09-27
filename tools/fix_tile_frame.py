"""Remove the thin uniform frame some generators draw around a tile, so it repeats without a seam.

On each side, an edge row/column is treated as frame (at most --max-frame lines per side) when
one color covers at least --uniformity of it, or when its average color is an outlier compared
with the inner lines (more than --outlier standard deviations away). Frame lines are cropped. No resampling: the
result is a few pixels smaller, which the triplanar shader handles (it reads the real size).

Usage: uv run --with pillow python3 tools/fix_tile_frame.py IN.png OUT.png [--uniformity 0.85] [--max-frame 3] [--outlier 3]
"""

import argparse
from collections import Counter
from statistics import mean, pstdev

from PIL import Image


def uniformity(pixels):
    return Counter(pixels).most_common(1)[0][1] / len(pixels)


def get_line(image, side, i):
    w, h = image.size
    if side == "top":
        return [image.getpixel((x, i)) for x in range(w)]
    if side == "bottom":
        return [image.getpixel((x, h - 1 - i)) for x in range(w)]
    if side == "left":
        return [image.getpixel((i, y)) for y in range(h)]
    return [image.getpixel((w - 1 - i, y)) for y in range(h)]


def luminance(pixels):
    return mean(0.299 * r + 0.587 * g + 0.114 * b for r, g, b in pixels)


def frame_width(image, side, threshold, limit, outlier):
    count = image.size[1] if side in ("top", "bottom") else image.size[0]
    inner = [luminance(get_line(image, side, i)) for i in range(limit + 1, count - limit - 1)]
    center, spread = mean(inner), max(pstdev(inner), 1.0)
    width = 0
    for i in range(limit):
        line = get_line(image, side, i)
        is_frame = uniformity(line) >= threshold or abs(luminance(line) - center) > outlier * spread
        if not is_frame:
            break
        width += 1
    return width


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("input")
    parser.add_argument("output")
    parser.add_argument("--uniformity", type=float, default=0.85)
    parser.add_argument("--max-frame", type=int, default=3)
    parser.add_argument("--outlier", type=float, default=3.0)
    args = parser.parse_args()
    image = Image.open(args.input).convert("RGB")
    sides = {s: frame_width(image, s, args.uniformity, args.max_frame, args.outlier) for s in ("top", "bottom", "left", "right")}
    w, h = image.size
    fixed = image.crop((sides["left"], sides["top"], w - sides["right"], h - sides["bottom"]))
    fixed.save(args.output)
    print(f"{args.output}: frame {sides}, {w}x{h} -> {fixed.width}x{fixed.height}")


if __name__ == "__main__":
    main()
