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


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("input")
    parser.add_argument("output")
    parser.add_argument("--box", type=float, nargs=6, required=True, metavar=("XMIN", "XMAX", "YMIN", "YMAX", "ZMIN", "ZMAX"))
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
        kept.add_geometry(piece, geom_name=name)
        total += int(inside.sum())
    kept.export(args.output)
    bounds = kept.bounds
    print(f"{args.output}: {total} faces, size {bounds[1] - bounds[0]}")


if __name__ == "__main__":
    main()
