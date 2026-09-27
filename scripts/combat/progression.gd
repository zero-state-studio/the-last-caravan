class_name Progression
extends RefCounted
## Reverse progression (34), a PROPOSAL of phase 3 step 6 waiting for the
## author's approval: chapter after chapter Ottavia loses breath, speed and
## combo length, but learns techniques and every strike grows stronger.
## One loss and one technique per chapter, shown on the end-of-chapter
## screen. All values here, to be tuned by playing.

const FIRST_CHAPTER: int = 1
const LAST_CHAPTER: int = 10
## Strike power gained each chapter (share of the chapter 1 damage).
const POWER_PER_CHAPTER: float = 0.15

## Index 0 is chapter 1. "stamina" and "speed" are shares of the chapter 1
## value; "lose" and "learn" are translation keys (StringName, empty: none).
const CHAPTERS: Array[Dictionary] = [
	{"stamina": 1.00, "speed": 1.00, "combo": 3, "lose": &"", "learn": &""},
	{"stamina": 0.94, "speed": 1.00, "combo": 3, "lose": &"PROG_LOSE_STAMINA", "learn": &"return_strike"},
	{"stamina": 0.94, "speed": 0.96, "combo": 3, "lose": &"PROG_LOSE_SPEED", "learn": &"keen_eye"},
	{"stamina": 0.94, "speed": 0.96, "combo": 2, "lose": &"PROG_LOSE_COMBO", "learn": &"heavy_finisher"},
	{"stamina": 0.88, "speed": 0.96, "combo": 2, "lose": &"PROG_LOSE_STAMINA", "learn": &"sure_step"},
	{"stamina": 0.88, "speed": 0.92, "combo": 2, "lose": &"PROG_LOSE_SPEED", "learn": &"dazzling_lantern"},
	{"stamina": 0.82, "speed": 0.92, "combo": 2, "lose": &"PROG_LOSE_STAMINA", "learn": &"deep_counter"},
	{"stamina": 0.82, "speed": 0.92, "combo": 1, "lose": &"PROG_LOSE_COMBO", "learn": &"long_hook"},
	{"stamina": 0.76, "speed": 0.92, "combo": 1, "lose": &"PROG_LOSE_STAMINA", "learn": &"veteran_breath"},
	{"stamina": 0.76, "speed": 0.88, "combo": 1, "lose": &"PROG_LOSE_SPEED", "learn": &""},
]

## What the techniques change (read by OttaviaCombat).
const KEEN_EYE_WINDOW: float = 0.05
const HEAVY_FINISHER_STAGGER: float = 0.8
const SURE_STEP_INVULNERABLE: float = 0.2
const DAZZLE_RADIUS: float = 3.0
const DAZZLE_STAGGER: float = 1.2
const DAZZLE_COOLDOWN: float = 8.0
const DEEP_COUNTER_MULTIPLIER: float = 2.5
const LONG_HOOK_EXTRA_REACH: float = 1.0
const VETERAN_BREATH_DELAY: float = 0.3
const RETURN_STRIKE_SECONDS: float = 1.2


static func clamp_chapter(chapter: int) -> int:
	return clampi(chapter, FIRST_CHAPTER, LAST_CHAPTER)


static func entry(chapter: int) -> Dictionary:
	return CHAPTERS[clamp_chapter(chapter) - 1]


static func power(chapter: int) -> float:
	return 1.0 + POWER_PER_CHAPTER * (clamp_chapter(chapter) - 1)


## True when Ottavia has learned `technique` by `chapter`.
static func knows(chapter: int, technique: StringName) -> bool:
	for index: int in clamp_chapter(chapter):
		if CHAPTERS[index]["learn"] == technique:
			return true
	return false


## The two lines of the end-of-chapter screen for arriving at `chapter`:
## [loss text, learned text], already translated.
static func chapter_lines(chapter: int) -> PackedStringArray:
	var now: Dictionary = entry(chapter)
	var before: Dictionary = entry(chapter - 1)
	var lose: String = ""
	match now["lose"]:
		&"PROG_LOSE_STAMINA":
			lose = TranslationServer.translate(&"PROG_LOSE_STAMINA").format({"from": roundi(100.0 * float(before["stamina"])), "to": roundi(100.0 * float(now["stamina"]))})
		&"PROG_LOSE_SPEED":
			lose = TranslationServer.translate(&"PROG_LOSE_SPEED").format({"from": roundi(100.0 * float(before["speed"])), "to": roundi(100.0 * float(now["speed"]))})
		&"PROG_LOSE_COMBO":
			lose = TranslationServer.translate(&"PROG_LOSE_COMBO").format({"from": int(before["combo"]), "to": int(now["combo"])})
	var learn: String = ""
	if now["learn"] != &"":
		learn = TranslationServer.translate(StringName("PROG_LEARN_" + String(now["learn"]).to_upper()))
	return PackedStringArray([lose, learn])
