"""Re-skin the texture atlas of a pixelized GLB with tileable material textures (54, 101).

Run it after tools/meshy_pixelize.py (the atlas is then at 30 px/m, so tiling a
material 1:1 in atlas pixels keeps the project density). Each atlas pixel is
classified by hue and replaced by the matching material pixel, keeping a little of
the original light/dark variation; the result can be mapped onto the base palette.

Classes (by HSV hue of the original pixel):
  leaf:  greens and yellow-greens (hue 55-170 degrees)
  bark:  browns, reds and dark warm colors (everything else that is not grey)
  other: greys (low saturation), left untouched

Usage: uv run --with pillow python3 tools/reskin_atlas.py IN.glb OUT.glb \
           --leaf foliage.png [--bark bark.png] [--palette assets/palette/palette_v1.png] [--preview atlas.png]
"""

import argparse
import colorsys
import io
import sys
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
from meshy_pixelize import read_glb, rebuild_binary, write_glb  # noqa: E402
from palette_remap import load_palette, remap  # noqa: E402


def classify(rgb):
    h, s, v = colorsys.rgb_to_hsv(*(c / 255.0 for c in rgb))
    if s < 0.18:
        return "other"
    if 55 <= h * 360 <= 170:
        return "leaf"
    return "bark"


def luminance(rgb):
    return 0.299 * rgb[0] + 0.587 * rgb[1] + 0.114 * rgb[2]


def reskin(atlas, materials, shading):
    atlas = atlas.convert("RGB")
    w, h = atlas.size
    classes = {}
    for y in range(h):
        for x in range(w):
            classes[(x, y)] = classify(atlas.getpixel((x, y)))
    means = {}
    for name in materials:
        values = [luminance(atlas.getpixel(p)) for p, c in classes.items() if c == name]
        means[name] = sum(values) / len(values) if values else 1.0
    out = atlas.copy()
    for (x, y), name in classes.items():
        material = materials.get(name)
        if material is None:
            continue
        mw, mh = material.size
        base = material.getpixel((x % mw, y % mh))
        # Keep part of the original shading (darker folds stay darker).
        factor = 1.0 + shading * (luminance(atlas.getpixel((x, y))) / max(means[name], 1.0) - 1.0)
        factor = max(0.7, min(1.3, factor))
        out.putpixel((x, y), tuple(max(0, min(255, round(c * factor))) for c in base))
    return out


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("input")
    parser.add_argument("output")
    parser.add_argument("--leaf", required=True, help="tileable foliage texture")
    parser.add_argument("--bark", help="tileable bark texture")
    parser.add_argument("--shading", type=float, default=0.5, help="how much original shading to keep (0-1)")
    parser.add_argument("--palette", help="map the result onto this palette strip")
    parser.add_argument("--preview", help="also save the new atlas here")
    args = parser.parse_args()

    materials = {"leaf": Image.open(args.leaf).convert("RGB")}
    if args.bark:
        materials["bark"] = Image.open(args.bark).convert("RGB")
    gltf, binary = read_glb(args.input)
    replaced = {}
    for image_info in gltf.get("images", []):
        view_index = image_info["bufferView"]
        view = gltf["bufferViews"][view_index]
        start = view.get("byteOffset", 0)
        atlas = Image.open(io.BytesIO(binary[start : start + view["byteLength"]]))
        result = reskin(atlas, materials, args.shading)
        if args.palette:
            result = remap(result, load_palette(args.palette)).convert("RGB")
        if args.preview:
            result.save(args.preview)
        buffer = io.BytesIO()
        result.save(buffer, format="PNG")
        replaced[view_index] = buffer.getvalue()
        image_info["mimeType"] = "image/png"
    binary = rebuild_binary(gltf, binary, replaced)
    write_glb(args.output, gltf, binary)
    print(f"{args.output}: atlas re-skinned with {', '.join(materials)}")


if __name__ == "__main__":
    main()
