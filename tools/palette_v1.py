"""Base palette v1 of the game (bible element 51), written to assets/palette/.

Outputs:
  assets/palette/palette_v1.gpl        GIMP/Aseprite palette (Aseprite: Palette > Load)
  assets/palette/palette_v1.png        32x1 strip, one pixel per color (also loadable by Aseprite)
  assets/palette/palette_v1_preview.png  enlarged swatches with group names and hex codes

Usage: uv run --with pillow python3 tools/palette_v1.py
"""

from pathlib import Path

from PIL import Image, ImageDraw

# (group, name, hex). Order matters: it is the order in Aseprite.
PALETTE = [
    # Warm light ramp: sunlit surfaces, from deep warm shadow to the sun's highlight.
    ("luce", "brace scura", "2B1B17"),
    ("luce", "bruno caldo", "4E2A1E"),
    ("luce", "terracotta", "7A3F22"),
    ("luce", "rame", "A85E2A"),
    ("luce", "arancio tramonto", "D48A3A"),
    ("luce", "oro", "EDB25A"),
    ("luce", "sole", "F7D58C"),
    ("luce", "riflesso", "FFF1CF"),
    # Cool shadow ramp: shadows and ambient light, blue-violet.
    ("ombra", "nero viola", "141125"),
    ("ombra", "contorno", "1E1A33"),
    ("ombra", "indaco profondo", "2E2A52"),
    ("ombra", "indaco", "433F73"),
    ("ombra", "blu viola", "5C5A94"),
    ("ombra", "lavanda", "7D7DB5"),
    ("ombra", "lavanda chiara", "A7A9D4"),
    # Middle of the Twilight: vegetation, earth, stone.
    ("crepuscolo", "oliva scuro", "3E4424"),
    ("crepuscolo", "oliva", "5E6B2E"),
    ("crepuscolo", "foglia", "7E8C3A"),
    ("crepuscolo", "muschio chiaro", "A4AC5A"),
    ("crepuscolo", "terra scura", "5A3F2B"),
    ("crepuscolo", "terra", "806042"),
    ("crepuscolo", "pietra calda", "9A8C7A"),
    ("crepuscolo", "pietra chiara", "C4B8A2"),
    # Toward the Night: frost and cold stone.
    ("notte", "ardesia", "3B4163"),
    ("notte", "brina scura", "6E7896"),
    ("notte", "pietra fredda", "8F97B0"),
    ("notte", "brina", "C8D3E6"),
    # Toward the Day: bleached and baked.
    ("giorno", "ocra bruciata", "9E6A2C"),
    ("giorno", "ocra", "C9953F"),
    ("giorno", "sabbia chiara", "E3CFA0"),
    ("giorno", "osso sbiancato", "F4EEDC"),
    # Accent: the only light of the Night.
    ("accento", "lanterna", "FFC46B"),
]

OUT = Path(__file__).resolve().parent.parent / "assets" / "palette"


def rgb(hex_code):
    return tuple(int(hex_code[i : i + 2], 16) for i in (0, 2, 4))


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    lines = ["GIMP Palette", "Name: The Last Caravan v1", "Columns: 8", "#"]
    for group, name, code in PALETTE:
        r, g, b = rgb(code)
        lines.append(f"{r:3d} {g:3d} {b:3d}\t{group} - {name}")
    (OUT / "palette_v1.gpl").write_text("\n".join(lines) + "\n")

    strip = Image.new("RGB", (len(PALETTE), 1))
    for i, (_, _, code) in enumerate(PALETTE):
        strip.putpixel((i, 0), rgb(code))
    strip.save(OUT / "palette_v1.png")

    cell, label = 64, 30
    groups = []
    for group, _, _ in PALETTE:
        if group not in groups:
            groups.append(group)
    width = 8 * cell + 110
    height = len(groups) * (cell + label)
    preview = Image.new("RGB", (width, height), (24, 22, 30))
    draw = ImageDraw.Draw(preview)
    for row, group in enumerate(groups):
        y = row * (cell + label)
        draw.text((6, y + cell // 2 - 6), group, fill=(235, 228, 214))
        entries = [e for e in PALETTE if e[0] == group]
        for col, (_, name, code) in enumerate(entries):
            x = 110 + col * cell
            draw.rectangle([x + 2, y + 2, x + cell - 3, y + cell - 3], fill=rgb(code))
            draw.text((x + 4, y + cell + 2), "#" + code, fill=(235, 228, 214))
            draw.text((x + 4, y + cell + 14), name[:10], fill=(170, 165, 160))
    preview.save(OUT / "palette_v1_preview.png")
    print(f"{len(PALETTE)} colors written to {OUT}")


if __name__ == "__main__":
    main()
