"""Environment palette v2 (bible element 51): palette v1 plus intermediate tones, 64 colors.

Only for environment textures (terrain, rock, plants, 3D models). Characters, creatures
and the interface stay on palette v1.

Built from palette v1:
  - every ramp of v1 gets the OKLab midpoint between each pair of neighbouring colors
    (25 new tones), so materials can use more shades without leaving the v1 hues;
  - 7 hue variants for richer environments: cool teal grass, yellow moss, red-brown
    path earth and a deep undergrowth green.

Outputs (same formats as v1):
  assets/palette/palette_v2_env.gpl, palette_v2_env.png (64x1), palette_v2_env_preview.png

Usage: uv run --with pillow python3 tools/palette_v2.py
"""

import sys
from pathlib import Path

from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).resolve().parent))
from palette_remap import oklab  # noqa: E402
from palette_v1 import PALETTE as PALETTE_V1  # noqa: E402

# Ramps of v1 that get midpoints, as (new group, v1 group, v1 color names in ramp order).
RAMPS = [
    ("luce", "luce", None),
    ("ombra", "ombra", None),
    ("crepuscolo verde", "crepuscolo", ["oliva scuro", "oliva", "foglia", "muschio chiaro"]),
    ("crepuscolo terra", "crepuscolo", ["terra scura", "terra", "pietra calda", "pietra chiara"]),
    ("notte", "notte", None),
    ("giorno", "giorno", None),
]

# Hand-picked hue variants (group, name, hex).
VARIANTS = [
    ("varianti", "sottobosco", "2A3020"),
    ("varianti", "verde acqua scuro", "2F5A4E"),
    ("varianti", "verde acqua", "4F8A72"),
    ("varianti", "muschio dorato", "9C9A3C"),
    ("varianti", "muschio giallo", "C2BE5E"),
    ("varianti", "sentiero rosso scuro", "6B3326"),
    ("varianti", "sentiero rosso", "9A5236"),
]

OUT = Path(__file__).resolve().parent.parent / "assets" / "palette"


def rgb(hex_code):
    return tuple(int(hex_code[i : i + 2], 16) for i in (0, 2, 4))


def linear_to_srgb(c):
    c = max(0.0, min(1.0, c))
    return 12.92 * c if c <= 0.0031308 else 1.055 * c ** (1 / 2.4) - 0.055


def oklab_to_rgb(lab):
    lightness, a, b = lab
    l = (lightness + 0.3963377774 * a + 0.2158037573 * b) ** 3
    m = (lightness - 0.1055613458 * a - 0.0638541728 * b) ** 3
    s = (lightness - 0.0894841775 * a - 1.2914855480 * b) ** 3
    r = 4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s
    g = -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s
    bl = -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s
    return tuple(round(linear_to_srgb(c) * 255) for c in (r, g, bl))


def midpoint(hex_a, hex_b):
    lab_a, lab_b = oklab(rgb(hex_a)), oklab(rgb(hex_b))
    r, g, b = oklab_to_rgb(tuple((x + y) / 2 for x, y in zip(lab_a, lab_b)))
    return f"{r:02X}{g:02X}{b:02X}"


def build():
    palette = []
    for group, v1_group, names in RAMPS:
        ramp = [(name, code) for g, name, code in PALETTE_V1 if g == v1_group and (names is None or name in names)]
        for index, (name, code) in enumerate(ramp):
            palette.append((group, name, code))
            if index + 1 < len(ramp):
                next_name, next_code = ramp[index + 1]
                palette.append((group, f"tra {name} e {next_name}", midpoint(code, next_code)))
    palette += [e for e in PALETTE_V1 if e[0] == "accento"]
    palette += VARIANTS
    return palette


def main():
    palette = build()
    OUT.mkdir(parents=True, exist_ok=True)
    lines = ["GIMP Palette", "Name: The Last Caravan v2 ambienti", "Columns: 8", "#"]
    for group, name, code in palette:
        r, g, b = rgb(code)
        lines.append(f"{r:3d} {g:3d} {b:3d}\t{group} - {name}")
    (OUT / "palette_v2_env.gpl").write_text("\n".join(lines) + "\n")

    strip = Image.new("RGB", (len(palette), 1))
    for i, (_, _, code) in enumerate(palette):
        strip.putpixel((i, 0), rgb(code))
    strip.save(OUT / "palette_v2_env.png")

    cell, label, left, columns = 56, 16, 130, 15
    groups = list(dict.fromkeys(group for group, _, _ in palette))
    preview = Image.new("RGB", (left + columns * cell, len(groups) * (cell + label)), (24, 22, 30))
    draw = ImageDraw.Draw(preview)
    for row, group in enumerate(groups):
        y = row * (cell + label)
        draw.text((6, y + cell // 2 - 6), group, fill=(235, 228, 214))
        for col, (_, name, code) in enumerate(e for e in palette if e[0] == group):
            x = left + col * cell
            draw.rectangle([x + 2, y + 2, x + cell - 3, y + cell - 3], fill=rgb(code))
            # Midpoints are marked with a small dot, v1 colors are plain.
            if name.startswith("tra "):
                draw.rectangle([x + cell // 2 - 2, y + cell - 10, x + cell // 2 + 1, y + cell - 7], fill=(24, 22, 30))
            draw.text((x + 3, y + cell + 1), code, fill=(235, 228, 214))
    preview.save(OUT / "palette_v2_env_preview.png")
    print(f"{len(palette)} colors written to {OUT}")


if __name__ == "__main__":
    main()
