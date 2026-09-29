"""Turn a textured Meshy GLB into a pixel-art-ready model (bible element 54).

- Downsamples the base color texture to a small square (box filter), then
  reduces it to a limited palette without dithering (or, with --palette, maps it
  onto that palette in OKLab, see tools/palette_remap.py). With --texels-per-meter
  the size is computed from surface area / UV area, so the model gets the
  same pixel density as the rest of the world.
- Embeds the result as PNG with a nearest-neighbour sampler (no mipmaps).
- Scales the root node to a target height in meters and puts the base at y=0.

Usage (Pillow via uv):
  uv run --with pillow python3 tools/meshy_pixelize.py IN.glb OUT.glb \
      (--texture-size 128 | --texels-per-meter 30) --colors 24 --height 1.0 \
      [--preview OUT_texture.png]
"""

import argparse
import io
import json
import math
import struct
import sys
from pathlib import Path

from PIL import Image

GLB_MAGIC = 0x46546C67
CHUNK_JSON = 0x4E4F534A
CHUNK_BIN = 0x004E4942
GL_NEAREST = 9728


def read_glb(path):
    data = open(path, "rb").read()
    magic, _version, _length = struct.unpack_from("<III", data, 0)
    if magic != GLB_MAGIC:
        raise ValueError(f"{path} is not a GLB file")
    offset = 12
    gltf, binary = None, b""
    while offset < len(data):
        chunk_length, chunk_type = struct.unpack_from("<II", data, offset)
        chunk = data[offset + 8 : offset + 8 + chunk_length]
        if chunk_type == CHUNK_JSON:
            gltf = json.loads(chunk)
        elif chunk_type == CHUNK_BIN:
            binary = chunk
        offset += 8 + chunk_length
    return gltf, binary


def pad4(blob, fill):
    return blob + fill * ((4 - len(blob) % 4) % 4)


def write_glb(path, gltf, binary):
    json_chunk = pad4(json.dumps(gltf, separators=(",", ":")).encode(), b" ")
    bin_chunk = pad4(binary, b"\0")
    total = 12 + 8 + len(json_chunk) + 8 + len(bin_chunk)
    with open(path, "wb") as out:
        out.write(struct.pack("<III", GLB_MAGIC, 2, total))
        out.write(struct.pack("<II", len(json_chunk), CHUNK_JSON) + json_chunk)
        out.write(struct.pack("<II", len(bin_chunk), CHUNK_BIN) + bin_chunk)


def read_accessor(gltf, binary, index):
    """Returns the accessor as a list of float/int tuples (tightly packed data only)."""
    accessor = gltf["accessors"][index]
    view = gltf["bufferViews"][accessor["bufferView"]]
    components = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4}[accessor["type"]]
    fmt = {5126: "f", 5125: "I", 5123: "H", 5121: "B"}[accessor["componentType"]]
    size = struct.calcsize(fmt) * components
    stride = view.get("byteStride", size)
    start = view.get("byteOffset", 0) + accessor.get("byteOffset", 0)
    return [struct.unpack_from("<" + fmt * components, binary, start + i * stride) for i in range(accessor["count"])]


def surface_and_uv_area(gltf, binary):
    surface, uv_area = 0.0, 0.0
    for mesh in gltf["meshes"]:
        for primitive in mesh["primitives"]:
            positions = read_accessor(gltf, binary, primitive["attributes"]["POSITION"])
            uvs = read_accessor(gltf, binary, primitive["attributes"]["TEXCOORD_0"])
            indices = [i[0] for i in read_accessor(gltf, binary, primitive["indices"])]
            for t in range(0, len(indices), 3):
                a, b, c = (positions[i] for i in indices[t : t + 3])
                ab = [b[k] - a[k] for k in range(3)]
                ac = [c[k] - a[k] for k in range(3)]
                cross = (ab[1] * ac[2] - ab[2] * ac[1], ab[2] * ac[0] - ab[0] * ac[2], ab[0] * ac[1] - ab[1] * ac[0])
                surface += 0.5 * math.sqrt(sum(v * v for v in cross))
                ua, ub, uc = (uvs[i] for i in indices[t : t + 3])
                uv_area += 0.5 * abs((ub[0] - ua[0]) * (uc[1] - ua[1]) - (uc[0] - ua[0]) * (ub[1] - ua[1]))
    return surface, uv_area


def pixelize(image, size, colors, palette_path=None, brightness=1.0, clean=0):
    small = image.convert("RGB").resize((size, size), Image.BOX)
    if brightness != 1.0:
        small = small.point(lambda value: min(255, int(value * brightness)))
    if palette_path:
        sys.path.insert(0, str(Path(__file__).resolve().parent))
        from palette_remap import load_palette, remap

        result = remap(small, load_palette(palette_path)).convert("RGB")
    else:
        result = small.quantize(colors=colors, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE).convert("RGB")
    for _ in range(clean):
        result = clean_isolated(result)
    return result


def clean_isolated(image):
    """Replace every texel that matches none of its four neighbours with the most
    common neighbour colour: no lone specks, so the texture reads in clusters of
    2-6 pixels like the sprites (docs/stile.md), at the same density."""
    width, height = image.size
    source = image.load()
    result = image.copy()
    target = result.load()
    for y in range(height):
        for x in range(width):
            here = source[x, y]
            around = [source[(x + dx) % width, (y + dy) % height] for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))]
            if here in around:
                continue
            counts = {}
            for colour in around:
                counts[colour] = counts.get(colour, 0) + 1
            target[x, y] = max(counts, key=counts.get)
    return result


def rebuild_binary(gltf, binary, replaced):
    """Repack buffer views, swapping the ones listed in `replaced` (index -> bytes)."""
    new_binary = b""
    for index, view in enumerate(gltf["bufferViews"]):
        start = view.get("byteOffset", 0)
        blob = replaced.get(index, binary[start : start + view["byteLength"]])
        new_binary = pad4(new_binary, b"\0")
        view["byteOffset"] = len(new_binary)
        view["byteLength"] = len(blob)
        new_binary += blob
    gltf["buffers"] = [{"byteLength": len(new_binary)}]
    return new_binary


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("input")
    parser.add_argument("output")
    size_group = parser.add_mutually_exclusive_group(required=True)
    size_group.add_argument("--texture-size", type=int)
    size_group.add_argument("--texels-per-meter", type=float, help="world pixel density (px per m)")
    parser.add_argument("--colors", type=int, default=24)
    parser.add_argument("--height", type=float, required=True, help="target height in meters")
    parser.add_argument("--preview", help="also save the reduced texture here")
    parser.add_argument("--turn-180", action="store_true", help="turn the model half around the vertical axis")
    parser.add_argument("--brightness", type=float, default=1.0, help="scale the texture brightness before the palette (e.g. 0.7 for pale stone)")
    parser.add_argument("--palette", help="map colors onto this palette strip (e.g. assets/palette/palette_v1.png)")
    parser.add_argument("--clean", type=int, default=0, help="passes that remove lone texels (clusters like the sprites)")
    args = parser.parse_args()

    gltf, binary = read_glb(args.input)
    min_y, max_y = float("inf"), float("-inf")
    for mesh in gltf["meshes"]:
        for primitive in mesh["primitives"]:
            accessor = gltf["accessors"][primitive["attributes"]["POSITION"]]
            min_y = min(min_y, accessor["min"][1])
            max_y = max(max_y, accessor["max"][1])
    scale = args.height / (max_y - min_y)
    texture_size = args.texture_size
    if args.texels_per_meter:
        surface, uv_area = surface_and_uv_area(gltf, binary)
        # texels along one side = density * sqrt(scaled surface / uv area)
        texture_size = max(16, 4 * round(args.texels_per_meter * scale * math.sqrt(surface / uv_area) / 4))
        print(f"surface {surface * scale * scale:.2f} m2, uv area {uv_area:.3f} -> texture {texture_size}px")
    replaced = {}
    for image_info in gltf.get("images", []):
        view_index = image_info["bufferView"]
        view = gltf["bufferViews"][view_index]
        start = view.get("byteOffset", 0)
        source = Image.open(io.BytesIO(binary[start : start + view["byteLength"]]))
        reduced = pixelize(source, texture_size, args.colors, args.palette, args.brightness, args.clean)
        if args.preview:
            reduced.save(args.preview)
        buffer = io.BytesIO()
        reduced.save(buffer, format="PNG")
        replaced[view_index] = buffer.getvalue()
        image_info["mimeType"] = "image/png"
    binary = rebuild_binary(gltf, binary, replaced)
    for sampler in gltf.get("samplers", []):
        sampler["magFilter"] = GL_NEAREST
        sampler["minFilter"] = GL_NEAREST
    if gltf.get("textures") and not gltf.get("samplers"):
        gltf["samplers"] = [{"magFilter": GL_NEAREST, "minFilter": GL_NEAREST}]
        for texture in gltf["textures"]:
            texture["sampler"] = 0
    for material in gltf.get("materials", []):
        pbr = material.setdefault("pbrMetallicRoughness", {})
        pbr["metallicFactor"] = 0.0
        pbr["roughnessFactor"] = 1.0

    # Mesh bounds assume the original root transforms are identity-scaled,
    # which holds for Meshy exports; the new parent node does the resizing.
    scene = gltf["scenes"][gltf.get("scene", 0)]
    root = {
        "name": "pixelized_root",
        "children": scene["nodes"],
        "scale": [scale, scale, scale],
        "translation": [0.0, -min_y * scale, 0.0],
    }
    if args.turn_180:
        # Half turn around the vertical axis, e.g. to put a vehicle's front west.
        root["rotation"] = [0.0, 1.0, 0.0, 0.0]
    gltf["nodes"].append(root)
    scene["nodes"] = [len(gltf["nodes"]) - 1]

    write_glb(args.output, gltf, binary)
    triangles = sum(
        gltf["accessors"][p["indices"]]["count"] // 3 for m in gltf["meshes"] for p in m["primitives"] if "indices" in p
    )
    print(f"{args.output}: {triangles} triangles, texture {texture_size}px/{args.colors} colors, scale {scale:.3f}")


if __name__ == "__main__":
    main()
