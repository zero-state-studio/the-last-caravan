class_name CombatHit
extends RefCounted
## A hit from Ottavia to a creature (33).

enum Kind { STRIKE, HOOK_PULL, HOOK_PUSH }

var kind: Kind = Kind.STRIKE
var damage: float = 0.0
## Horizontal direction from Ottavia toward the target.
var direction: Vector3 = Vector3.FORWARD
var knockback: float = 0.0
## Counter-hit on an open creature.
var critical: bool = false
var source: Node3D
