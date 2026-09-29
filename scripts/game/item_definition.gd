class_name ItemDefinition
extends Resource
## One item of the game (128): few, each with a meaning in the world.
## Names and texts are translation keys. Patches (104) carry an effect and
## its amount, a starting value to tune by playing.

enum Kind { PATCH, WARM_STONE, TOOL, MEMORY }

@export var id: StringName
@export var kind: Kind = Kind.PATCH
@export var name_key: StringName
## Patches: what the effect does, in words. Memories: their two lines (130).
@export var text_key: StringName
## Patches only: which effect (see CoatPatches) and how strong.
@export var effect: StringName
@export var amount: float = 1.0
