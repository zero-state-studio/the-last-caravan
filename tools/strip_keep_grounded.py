"""Remove the pieces of a strip frame that float free of the body (a disc or a
leaf the generator left in the air): in every 64x64 cell only the 8-connected
pixel groups reaching down to within `--near` rows of the feet (row 60) stay.

Usage: uv run --with pillow python3 tools/strip_keep_grounded.py STRIP.png [...] [--near 8]
"""
from __future__ import annotations

import argparse

from PIL import Image

CELL = 64
BASELINE = 60


def clean_cell(image: Image.Image, left: int, near: int) -> int:
    pixels = image.load()
    seen: set[tuple[int, int]] = set()
    removed = 0
    for sy in range(CELL):
        for sx in range(left, left + CELL):
            if (sx, sy) in seen or pixels[sx, sy][3] == 0:
                continue
            group = [(sx, sy)]
            seen.add((sx, sy))
            index = 0
            while index < len(group):
                x, y = group[index]
                index += 1
                for dx in (-1, 0, 1):
                    for dy in (-1, 0, 1):
                        nx, ny = x + dx, y + dy
                        if left <= nx < left + CELL and 0 <= ny < CELL and (nx, ny) not in seen and pixels[nx, ny][3] > 0:
                            seen.add((nx, ny))
                            group.append((nx, ny))
            if max(y for _, y in group) < BASELINE - near:
                for x, y in group:
                    pixels[x, y] = (0, 0, 0, 0)
                removed += len(group)
    return removed


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("strips", nargs="+")
    parser.add_argument("--near", type=int, default=8)
    args = parser.parse_args()
    for path in args.strips:
        image = Image.open(path).convert("RGBA")
        removed = sum(clean_cell(image, left, args.near) for left in range(0, image.width, CELL))
        image.save(path)
        print(f"{path}: {removed} floating pixels removed")


if __name__ == "__main__":
    main()
