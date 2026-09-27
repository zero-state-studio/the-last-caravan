class_name VegetationEntry
extends Resource
## One element of the 3D vegetation kit (101): a simplified model (54) or a
## crossed-plane card for grass and small plants. Kit elements are saved as
## .tres files in assets/vegetation_kit/ and spread by VegetationScatter.

## Imported model (GLB scene). Its first mesh is used, with the transform the
## model has inside the scene (size in meters, base at y = 0).
@export var model: PackedScene
## Card texture, used when there is no model; drawn at the world density (49).
@export var card_texture: Texture2D
## Relative chance of being picked when a scatter holds several entries.
@export var weight: float = 1.0
## Radius in meters kept free around each instance: no other instance is
## placed closer than the sum of the two radii.
@export var footprint_radius: float = 0.15
## Random uniform scale range.
@export var scale_range: Vector2 = Vector2(0.9, 1.1)
@export var cast_shadow: bool = true
