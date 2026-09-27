"""Reduce the triangles of a textured GLB (bible element 54), keeping its UVs and texture.

Uses MeshLab's quadric edge collapse with texture preservation (pymeshlab), then writes
a GLB again with trimesh. Run tools/meshy_pixelize.py afterwards for the pixel-art texture,
the nearest filter and the size in meters.

Usage: uv run --with pymeshlab --with trimesh --with pillow python3 tools/mesh_simplify.py \
           IN.glb OUT.glb --triangles 1000
"""

import argparse
import tempfile
from pathlib import Path

import pymeshlab
import trimesh


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("input")
    parser.add_argument("output")
    parser.add_argument("--triangles", type=int, required=True, help="target triangle count")
    args = parser.parse_args()

    meshes = pymeshlab.MeshSet()
    meshes.load_new_mesh(args.input)
    before = meshes.current_mesh().face_number()
    # Weld vertices duplicated at UV seams and between parts, so the collapse can
    # work across them (UVs stay per face corner) without opening holes.
    meshes.meshing_merge_close_vertices(threshold=pymeshlab.PercentageValue(0.1))
    if before > args.triangles:
        meshes.meshing_decimation_quadric_edge_collapse_with_texture(
            targetfacenum=args.triangles, qualitythr=0.3, preserveboundary=True, boundaryweight=2.0,
            optimalplacement=True, preservenormal=True, planarquadric=True,
        )
    after = meshes.current_mesh().face_number()
    # MeshLab cannot re-save the embedded texture (no file extension), so only the
    # geometry and UVs go through OBJ; the original image is attached again here.
    source = trimesh.load(args.input, force="mesh", process=False)
    image = source.visual.material.baseColorTexture
    with tempfile.TemporaryDirectory() as folder:
        obj_path = Path(folder) / "simplified.obj"
        meshes.save_current_mesh(str(obj_path), save_textures=False, save_wedge_texcoord=True)
        simplified = trimesh.load(str(obj_path), force="mesh", process=False)
        material = trimesh.visual.material.PBRMaterial(baseColorTexture=image, metallicFactor=0.0, roughnessFactor=1.0, doubleSided=True)
        simplified.visual = trimesh.visual.TextureVisuals(uv=simplified.visual.uv, material=material)
        # Faceted low-poly look: one vertex per face corner, so normals are per face.
        simplified.unmerge_vertices()
        simplified.export(args.output, include_normals=True)
    print(f"{args.output}: {before} -> {after} triangles")


if __name__ == "__main__":
    main()
