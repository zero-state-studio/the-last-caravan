class_name GameOptions
extends RefCounted
## Player options (96): screen shake, flashes, aim assist, text size. Saved in
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
## Size of dialogues, subtitles and hints (96, 125).
## 28, 37 and 47 px with the pixel font: 3, 4 and 5 of its pixels per row.
const TEXT_SCALES: Array[float] = [1.0, 4.0 / 3.0, 5.0 / 3.0]
static var text_scale: float = 1.0
## True once read from disk: later scenes keep what is in memory (tests and
## dev arguments may have changed it on purpose).
static var loaded: bool = false


static func load_options() -> void:
	if loaded:
		apply()
		return
	loaded = true
	var config: ConfigFile = ConfigFile.new()
	if config.load(PATH) == OK:
		shake_strength = float(config.get_value(SECTION, "shake_strength", 1.0))
		flash_strength = float(config.get_value(SECTION, "flash_strength", 1.0))
		aim_assist = bool(config.get_value(SECTION, "aim_assist", true))
		difficulty = clampi(int(config.get_value(SECTION, "difficulty", 1)), 0, 2)
		text_scale = clampf(float(config.get_value(SECTION, "text_scale", 1.0)), TEXT_SCALES[0], TEXT_SCALES[-1])
	apply()


static func save_options() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.set_value(SECTION, "shake_strength", shake_strength)
	config.set_value(SECTION, "flash_strength", flash_strength)
	config.set_value(SECTION, "aim_assist", aim_assist)
	config.set_value(SECTION, "difficulty", difficulty)
	config.set_value(SECTION, "text_scale", text_scale)
	config.save(PATH)
	apply()


static func apply() -> void:
	HitFeedback.shake_scale = shake_strength
	HitFeedback.flash_scale = flash_strength
