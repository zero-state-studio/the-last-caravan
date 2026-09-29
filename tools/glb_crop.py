"""Keep only the faces of a textured GLB lying wholly inside a box, with their UVs
and texture: a way to take single pieces (a wheel, a lever with its gears) out of a
Meshy model made of many small parts. Coordinates are those of the input file.
Run tools/meshy_pixelize.py afterwards for the size and the pixel-art texture.

Usage: uv run --with trimesh --with pillow --with networkx --with scipy python3 tools/glb_crop.py \\
           IN.glb OUT.glb --box XMIN XMAX YMIN YMAX ZMIN ZMAX
"""

import argparse

import numpy as np
import trimesh


def crop_texture(mesh, margin=4):
    """Cut the base colour texture down to the UV box of `mesh` and remap its UVs."""
    visual = mesh.visual
    image = getattr(visual.material, "baseColorTexture", None)
    if image is None or visual.uv is None or len(visual.uv) == 0:
        return
    width, height = image.size
    uv = np.array(visual.uv, dtype=float)
    # UV v runs upward, image rows downward.
    left = max(0, int(np.floor(uv[:, 0].min() * width)) - margin)
    right = min(width, int(np.ceil(uv[:, 0].max() * width)) + margin)
    top = max(0, int(np.floor((1.0 - uv[:, 1].max()) * height)) - margin)
    bottom = min(height, int(np.ceil((1.0 - uv[:, 1].min()) * height)) + margin)
    cropped = image.crop((left, top, right, bottom))
    new_uv = np.empty_like(uv)
    new_uv[:, 0] = (uv[:, 0] * width - left) / (right - left)
    new_uv[:, 1] = 1.0 - ((1.0 - uv[:, 1]) * height - top) / (bottom - top)
    visual.material.baseColorTexture = cropped
    visual.uv = new_uv


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("input")
    parser.add_argument("output")
    parser.add_argument("--box", type=float, nargs=6, required=True, metavar=("XMIN", "XMAX", "YMIN", "YMAX", "ZMIN", "ZMAX"))
    parser.add_argument("--crop-texture", action="store_true", help="keep only the part of the texture the piece uses")
    args = parser.parse_args()
    x0, x1, y0, y1, z0, z1 = args.box
    scene = trimesh.load(args.input, force="scene")
    kept = trimesh.Scene()
    total = 0
    for name, geometry in scene.geometry.items():
        # Every corner inside: long faces of the rest of the model stay out.
        corners = geometry.triangles
        inside = np.all(
            (corners[:, :, 0] >= x0) & (corners[:, :, 0] <= x1)
            & (corners[:, :, 1] >= y0) & (corners[:, :, 1] <= y1)
            & (corners[:, :, 2] >= z0) & (corners[:, :, 2] <= z1),
            axis=1,
        )
        if not inside.any():
            continue
        piece = geometry.submesh([np.nonzero(inside)[0]], append=True)
        piece.remove_unreferenced_vertices()
        if args.crop_texture:
            crop_texture(piece)
        kept.add_geometry(piece, geom_name=name)
        total += int(inside.sum())
    kept.export(args.output)
    bounds = kept.bounds
    print(f"{args.output}: {total} faces, size {bounds[1] - bounds[0]}")


if __name__ == "__main__":
    main()
