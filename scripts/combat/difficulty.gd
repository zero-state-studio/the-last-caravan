class_name Difficulty
extends RefCounted
## Difficulty levels (40): easy, medium, hard change the strength of the
## creatures and the times. Medium is the tuned game; the others scale it,
## as the chapter 1 document says (phase 4b): at easy only the telegraphs
## are 30% longer (and the aim cone widens, 33); at hard the creatures deal
## 30% more damage and have 25% more health. Chosen in the options.

enum Level { EASY, MEDIUM, HARD }

const ENEMY_DAMAGE: Array[float] = [1.0, 1.0, 1.3]
const ENEMY_HEALTH: Array[float] = [1.0, 1.0, 1.25]
## Wind-ups and warnings of the creatures: longer is easier.
const TELEGRAPH: Array[float] = [1.3, 1.0, 1.0]
const DEFLECT_WINDOW: Array[float] = [1.0, 1.0, 1.0]


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
