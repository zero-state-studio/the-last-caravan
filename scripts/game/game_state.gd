class_name GameState
extends RefCounted
## What Ottavia carries through the whole game, and what the world
## remembers of her: the rope of the saved (125), the bisaccia (128) with
## patches, warm stones (129), tools and memories (130), the items already
## taken, the shortcuts opened and the hints already shown. SaveGame writes
## it to disk (95). Scenes read and change it; `events` tells the interface.

const COAT_SLOTS: int = 3
const EMPTY_SLOT: StringName = &""

## The chapter Ottavia lives in (34): 1 until the end of chapter 1.
static var chapter: int = 1
## Knots on the rope: one per person saved (106, 125).
static var knots: int = 0
## Patches found (104), in the order they were found.
static var found_patches: Array[StringName] = []
## The three coat slots: a patch id, or EMPTY_SLOT.
static var sewn_patches: Array[StringName] = [EMPTY_SLOT, EMPTY_SLOT, EMPTY_SLOT]
static var warm_stones: int = 0
## Items of the trade needed in one chapter (a key, a tool for a puzzle).
static var tools: Array[StringName] = []
static var memories: Array[StringName] = []
## Pickups already taken, by their unique id: they are not there any more.
static var taken: Dictionary = {}
## Named facts of the world: shortcuts opened, hints shown, rooms solved.
static var flags: Dictionary = {}
## True at the caravan (during the Truce): only there patches can be sewn
## and unpicked (37, 128).
static var at_caravan: bool = false
static var events: GameStateEvents = GameStateEvents.new()


static func reset() -> void:
	chapter = 1
	knots = 0
	found_patches = []
	sewn_patches = [EMPTY_SLOT, EMPTY_SLOT, EMPTY_SLOT]
	warm_stones = 0
	tools = []
	memories = []
	taken = {}
	flags = {}
	at_caravan = false
	LanternProgress.revealed = false
	LanternProgress.pieces = 0
	events.changed.emit()


static func add_knot() -> void:
	knots += 1
	events.knot_added.emit(knots)
	events.changed.emit()


## An item found in the world goes into the bisaccia. Returns false when it
## cannot be carried (warm stones already at the maximum).
static func receive(item_id: StringName, max_stones: int) -> bool:
	var item: ItemDefinition = ItemCatalog.main().find(item_id)
	if item == null:
		push_warning("GameState: unknown item %s" % item_id)
		return false
	match item.kind:
		ItemDefinition.Kind.PATCH:
			if not item_id in found_patches:
				found_patches.append(item_id)
		ItemDefinition.Kind.MEMORY:
			if not item_id in memories:
				memories.append(item_id)
		ItemDefinition.Kind.TOOL:
			if not item_id in tools:
				tools.append(item_id)
		ItemDefinition.Kind.WARM_STONE:
			if warm_stones >= max_stones:
				return false
			warm_stones += 1
	events.item_received.emit(item_id)
	events.changed.emit()
	return true


## Sews a found patch into a slot (the patch leaves any other slot), or
## empties the slot with EMPTY_SLOT. Only at the caravan.
static func sew(slot: int, patch_id: StringName) -> bool:
	if not at_caravan or slot < 0 or slot >= COAT_SLOTS:
		return false
	if patch_id != EMPTY_SLOT and not patch_id in found_patches:
		return false
	for index: int in COAT_SLOTS:
		if sewn_patches[index] == patch_id:
			sewn_patches[index] = EMPTY_SLOT
	sewn_patches[slot] = patch_id
	events.patches_changed.emit()
	events.changed.emit()
	return true


static func worn_patches() -> Array[StringName]:
	var worn: Array[StringName] = []
	for patch: StringName in sewn_patches:
		if patch != EMPTY_SLOT:
			worn.append(patch)
	return worn


static func use_warm_stone() -> bool:
	if warm_stones <= 0:
		return false
	warm_stones -= 1
	events.changed.emit()
	return true


## At the caravan, at the start of every Truce (129).
static func refill_warm_stones(count: int) -> void:
	warm_stones = maxi(warm_stones, count)
	events.changed.emit()


static func is_taken(pickup_id: StringName) -> bool:
	return taken.has(String(pickup_id))


static func mark_taken(pickup_id: StringName) -> void:
	taken[String(pickup_id)] = true


static func has_flag(flag: StringName) -> bool:
	return flags.has(String(flag))


static func set_flag(flag: StringName) -> void:
	flags[String(flag)] = true
	events.changed.emit()


## Everything above as plain data, for the save file.
static func to_data() -> Dictionary:
	return {
		"chapter": chapter,
		"knots": knots,
		"found_patches": _strings(found_patches),
		"sewn_patches": _strings(sewn_patches),
		"warm_stones": warm_stones,
		"tools": _strings(tools),
		"memories": _strings(memories),
		"taken": taken.duplicate(),
		"flags": flags.duplicate(),
		"lantern_revealed": LanternProgress.revealed,
		"lantern_pieces": LanternProgress.pieces,
	}


static func from_data(data: Dictionary) -> void:
	chapter = int(data.get("chapter", 1))
	knots = int(data.get("knots", 0))
	found_patches = _names(data.get("found_patches", []))
	sewn_patches = _names(data.get("sewn_patches", []))
	sewn_patches.resize(COAT_SLOTS)
	for index: int in COAT_SLOTS:
		if sewn_patches[index] == null:
			sewn_patches[index] = EMPTY_SLOT
	warm_stones = int(data.get("warm_stones", 0))
	tools = _names(data.get("tools", []))
	memories = _names(data.get("memories", []))
	taken = (data.get("taken", {}) as Dictionary).duplicate()
	flags = (data.get("flags", {}) as Dictionary).duplicate()
	LanternProgress.revealed = bool(data.get("lantern_revealed", false))
	LanternProgress.pieces = int(data.get("lantern_pieces", 0))
	events.changed.emit()


static func _strings(values: Array[StringName]) -> Array[String]:
	var result: Array[String] = []
	for value: StringName in values:
		result.append(String(value))
	return result


static func _names(values: Variant) -> Array[StringName]:
	var result: Array[StringName] = []
	if values is Array:
		for value: Variant in values:
			result.append(StringName(str(value)))
	return result
