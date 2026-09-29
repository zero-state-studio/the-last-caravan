class_name PrologueState
extends RefCounted
## What the prologue (106) carries from one space to the next.

const FLOOR_SCENE: String = "res://scenes/prologo/piano_tessibuio.tscn"
const CAMP_SCENE: String = "res://scenes/prologo/accampamento.tscn"
const COLUMN_SCENE: String = "res://scenes/prologo/colonna.tscn"

## Ottavia came out of the back door: the camp opens with the glare, the
## wide shot of the caravan and the narration.
static var entered_from_door: bool = false
## The lantern shutter as she left the floor.
static var lantern_open: bool = false


static func reset() -> void:
	entered_from_door = false
	lantern_open = false
	# A new game: the rope, the bisaccia and the world start empty.
	GameState.reset()
