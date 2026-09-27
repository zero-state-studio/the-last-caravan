"""Turn a textured Meshy GLB into a pixel-art-ready model (bible element 54).

- Downsamples the base color texture to a small square (box filter), then
  reduces it to a limited palette without dithering.
- Embeds the result as PNG with a nearest-neighbour sampler (no mipmaps).
- Scales the root node to a target height in meters and puts the base at y=0.

Usage (Pillow via uv):
  uv run --with pillow python3 tools/meshy_pixelize.py IN.glb OUT.glb \
      --texture-size 128 --colors 24 --height 1.0 [--preview OUT_texture.png]
"""

import argparse
import io
import json
import struct

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


def pixelize(image, size, colors):
    small = image.convert("RGB").resize((size, size), Image.BOX)
    return small.quantize(colors=colors, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE).convert("RGB")


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
    parser.add_argument("--texture-size", type=int, default=128)
    parser.add_argument("--colors", type=int, default=24)
    parser.add_argument("--height", type=float, required=True, help="target height in meters")
    parser.add_argument("--preview", help="also save the reduced texture here")
    args = parser.parse_args()

    gltf, binary = read_glb(args.input)
    replaced = {}
    for image_info in gltf.get("images", []):
        view_index = image_info["bufferView"]
        view = gltf["bufferViews"][view_index]
        start = view.get("byteOffset", 0)
        source = Image.open(io.BytesIO(binary[start : start + view["byteLength"]]))
        reduced = pixelize(source, args.texture_size, args.colors)
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
    for material in gltf.get("materials", []):
        pbr = material.setdefault("pbrMetallicRoughness", {})
        pbr["metallicFactor"] = 0.0
        pbr["roughnessFactor"] = 1.0

    min_y, max_y = float("inf"), float("-inf")
    for mesh in gltf["meshes"]:
        for primitive in mesh["primitives"]:
            accessor = gltf["accessors"][primitive["attributes"]["POSITION"]]
            min_y = min(min_y, accessor["min"][1])
            max_y = max(max_y, accessor["max"][1])
    # Mesh bounds assume the original root transforms are identity-scaled,
    # which holds for Meshy exports; the new parent node does the resizing.
    scale = args.height / (max_y - min_y)
    scene = gltf["scenes"][gltf.get("scene", 0)]
    gltf["nodes"].append({
        "name": "pixelized_root",
        "children": scene["nodes"],
        "scale": [scale, scale, scale],
        "translation": [0.0, -min_y * scale, 0.0],
    })
    scene["nodes"] = [len(gltf["nodes"]) - 1]

    write_glb(args.output, gltf, binary)
    triangles = sum(
        gltf["accessors"][p["indices"]]["count"] // 3 for m in gltf["meshes"] for p in m["primitives"] if "indices" in p
    )
    print(f"{args.output}: {triangles} triangles, texture {args.texture_size}px/{args.colors} colors, scale {scale:.3f}")


if __name__ == "__main__":
    main()
