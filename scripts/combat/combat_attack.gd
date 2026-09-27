class_name CombatAttack
extends RefCounted
## An attack from a creature to Ottavia (33).

enum Result { HIT, BLOCKED, DEFLECTED, EVADED }

var damage: float = 0.0
## The attacker: staggered when the attack is deflected.
var source: CombatEnemy
var deflectable: bool = true
