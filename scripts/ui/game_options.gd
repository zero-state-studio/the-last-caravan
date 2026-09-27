class_name GameOptions
extends RefCounted
## Player options (96): screen shake, flashes, aim assist. Saved in
## user://options.cfg and applied at start.

const PATH: String = "user://options.cfg"
const SECTION: String = "options"

## 0-1: how much the camera shakes on hits.
static var shake_strength: float = 1.0
## 0-1: how strong hit flashes and telegraph glows are.
static var flash_strength: float = 1.0
## Turns strikes and the hook toward the creature in front (33).
static var aim_assist: bool = true
## Difficulty level (40): 0 easy, 1 medium, 2 hard.
static var difficulty: int = 1


static func load_options() -> void:
	var config: ConfigFile = ConfigFile.new()
	if config.load(PATH) == OK:
		shake_strength = float(config.get_value(SECTION, "shake_strength", 1.0))
		flash_strength = float(config.get_value(SECTION, "flash_strength", 1.0))
		aim_assist = bool(config.get_value(SECTION, "aim_assist", true))
		difficulty = clampi(int(config.get_value(SECTION, "difficulty", 1)), 0, 2)
	apply()


static func save_options() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.set_value(SECTION, "shake_strength", shake_strength)
	config.set_value(SECTION, "flash_strength", flash_strength)
	config.set_value(SECTION, "aim_assist", aim_assist)
	config.set_value(SECTION, "difficulty", difficulty)
	config.save(PATH)
	apply()


static func apply() -> void:
	HitFeedback.shake_scale = shake_strength
	HitFeedback.flash_scale = flash_strength
