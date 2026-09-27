class_name Difficulty
extends RefCounted
## Difficulty levels (40): easy, medium, hard change the strength of the
## creatures and the times (telegraphs, deflect window, aim cone). Medium is
## the tuned game; the others scale it. Chosen in the options (GameOptions).

enum Level { EASY, MEDIUM, HARD }

const ENEMY_DAMAGE: Array[float] = [0.7, 1.0, 1.3]
const ENEMY_HEALTH: Array[float] = [0.8, 1.0, 1.25]
## Wind-ups and warnings of the creatures: longer is easier.
const TELEGRAPH: Array[float] = [1.3, 1.0, 0.85]
const DEFLECT_WINDOW: Array[float] = [1.3, 1.0, 0.8]


static func level() -> Level:
	return GameOptions.difficulty as Level


static func enemy_damage() -> float:
	return ENEMY_DAMAGE[level()]


static func enemy_health() -> float:
	return ENEMY_HEALTH[level()]


static func telegraph() -> float:
	return TELEGRAPH[level()]


static func deflect_window() -> float:
	return DEFLECT_WINDOW[level()]


static func is_easy() -> bool:
	return level() == Level.EASY
