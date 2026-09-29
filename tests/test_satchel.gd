extends SceneTree
## The bisaccia (128-131): items into GameState, patches sewn and unpicked
## only at the caravan, warm stones squeezed for health (129), pickups that
## stay taken, the found line, and the state kept as plain data (95).
## Usage: godot --headless --path . --script res://tests/test_satchel.gd

var _checks: int = 0
var _failures: int = 0
var _ottavia: OttaviaProto
var _combat: OttaviaCombat


func _initialize() -> void:
	change_scene_to_file("res://scenes/proto/diorama.tscn")
	await _wait(0.3)
	current_scene.get_node("Creatures").free()
	_ottavia = current_scene.get_node("Ottavia")
	_combat = _ottavia.combat
	GameState.reset()

	_test_catalog()
	_test_items_and_sewing()
	await _test_warm_stone()
	await _test_pickup()
	_test_data()

	GameState.reset()
	current_scene.queue_free()
	await _wait(0.4)
	print("TESTS: satchel %d checks, %d failures" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)


func _test_catalog() -> void:
	var catalog: ItemCatalog = ItemCatalog.main()
	_check(catalog.of_kind(ItemDefinition.Kind.PATCH).size() == 3, "catalog: the three patches of chapter 1")
	_check(catalog.of_kind(ItemDefinition.Kind.MEMORY).size() == 2, "catalog: the two memories of chapter 1")
	var keys_ok: bool = true
	for item: ItemDefinition in catalog.items:
		for key: StringName in [item.name_key, item.text_key]:
			if TranslationServer.translate(key) == String(key):
				keys_ok = false
				print("missing translation ", key)
	_check(keys_ok, "catalog: every name and text is translated")
	_check(is_equal_approx(_ottavia.max_health, 100.0), "Ottavia has 100 health (chapter 1, section 1)")


func _test_items_and_sewing() -> void:
	_check(GameState.receive(&"patch_felt", 3) and &"patch_felt" in GameState.found_patches, "a found patch goes into the bisaccia")
	_check(GameState.receive(&"memory_black_seed", 3) and &"memory_black_seed" in GameState.memories, "a memory goes into the bisaccia")
	GameState.at_caravan = false
	_check(not GameState.sew(0, &"patch_felt"), "away from the caravan patches cannot be sewn (128)")
	GameState.at_caravan = true
	_check(not GameState.sew(0, &"patch_oiled_leather"), "a patch not found cannot be sewn")
	_check(GameState.sew(0, &"patch_felt") and _combat.patches == [&"patch_felt"], "at the caravan a patch is sewn and Ottavia wears it")
	GameState.sew(2, &"patch_felt")
	_check(GameState.sewn_patches == [GameState.EMPTY_SLOT, GameState.EMPTY_SLOT, &"patch_felt"], "sewing a patch in another slot moves it")
	GameState.sew(2, GameState.EMPTY_SLOT)
	_check(_combat.patches.is_empty(), "an unpicked patch is not worn any more")
	GameState.at_caravan = false


func _test_warm_stone() -> void:
	_ottavia.set_physics_process(false)
	var tuning: CombatTuning = _combat.tuning
	GameState.warm_stones = 0
	_ottavia.health = 40.0
	_combat.reset()
	_combat.press(&"warm_stone")
	_step(0.05)
	_check(_combat.state == OttaviaCombat.State.FREE, "no stone: nothing to squeeze")
	_combat.release(&"warm_stone")
	GameState.warm_stones = 2
	_combat.press(&"warm_stone")
	_step(0.05)
	_check(_combat.is_squeezing_stone(), "with a stone Ottavia starts squeezing it")
	_step(tuning.warm_stone_seconds * 0.5)
	_combat.release(&"warm_stone")
	_step(0.05)
	_check(GameState.warm_stones == 2 and is_equal_approx(_ottavia.health, 40.0), "let go too early: the stone is kept")
	_combat.press(&"warm_stone")
	for index: int in int(tuning.warm_stone_seconds / 0.05) + 3:
		_step(0.05)
	_combat.release(&"warm_stone")
	_check(GameState.warm_stones == 1 and is_equal_approx(_ottavia.health, 40.0 + tuning.warm_stone_heal), "held to the end: one stone gives back 35 health")
	_combat.press(&"parry")
	_step(0.05)
	_combat.press(&"warm_stone")
	_step(0.1)
	_check(not _combat.is_squeezing_stone(), "not while parrying")
	_combat.release(&"parry")
	_combat.release(&"warm_stone")
	_step(0.05)
	_combat.press(&"warm_stone")
	_step(0.1)
	var attack: CombatAttack = CombatAttack.new()
	attack.damage = 5.0
	_combat.receive_attack(attack)
	_check(_combat.state == OttaviaCombat.State.HITSTUN and GameState.warm_stones == 1, "a hit breaks the squeeze and the stone is kept")
	_combat.release(&"warm_stone")
	_ottavia.health = _ottavia.max_health
	_combat.reset()
	_combat.press(&"warm_stone")
	_step(0.05)
	_check(not _combat.is_squeezing_stone(), "full health: the stone is not wasted")
	_combat.release(&"warm_stone")
	_ottavia.set_physics_process(true)
	await _wait(0.05)


func _test_pickup() -> void:
	GameState.warm_stones = _combat.tuning.warm_stone_max
	var stone: WorldPickup = WorldPickup.new()
	stone.item_id = &"warm_stone"
	stone.pickup_id = &"test_stone"
	current_scene.add_child(stone)
	stone.global_position = _ottavia.global_position + Vector3(0.3, 0.0, 0.0)
	await _wait(0.3)
	_check(is_instance_valid(stone) and not GameState.is_taken(&"test_stone"), "a warm stone stays where it is when three are carried")
	stone.global_position = Vector3(40.0, 0.0, 40.0)
	GameState.warm_stones = 1
	await _wait(0.1)
	stone.global_position = _ottavia.global_position
	await _wait(0.3)
	_check(not is_instance_valid(stone) and GameState.warm_stones == 2 and GameState.is_taken(&"test_stone"), "walking onto a stone takes it")
	var toast: ItemToast = ItemToast.new()
	current_scene.add_child(toast)
	toast.show_item(&"patch_felt")
	_check(toast.current_text().contains(TranslationServer.translate(&"ITEM_PATCH_FELT")), "the found line names the item")
	var again: WorldPickup = WorldPickup.new()
	again.item_id = &"warm_stone"
	again.pickup_id = &"test_stone"
	current_scene.add_child(again)
	await _wait(0.1)
	_check(not is_instance_valid(again), "a pickup already taken is not there any more")


func _test_data() -> void:
	GameState.knots = 2
	GameState.set_flag(&"shortcut_test")
	var data: Dictionary = JSON.parse_string(JSON.stringify(GameState.to_data()))
	GameState.reset()
	_check(GameState.knots == 0 and GameState.found_patches.is_empty(), "reset empties the state")
	GameState.from_data(data)
	_check(GameState.knots == 2 and &"patch_felt" in GameState.found_patches and &"memory_black_seed" in GameState.memories, "the state comes back from plain data")
	_check(GameState.has_flag(&"shortcut_test") and GameState.is_taken(&"test_stone") and GameState.sewn_patches.size() == GameState.COAT_SLOTS, "flags, taken pickups and slots come back")


func _step(delta: float) -> void:
	_combat.physics_update(delta, Vector2.ZERO, true)


func _check(condition: bool, label: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		print("FAIL: ", label)


func _wait(seconds: float) -> void:
	await create_timer(seconds, true, true).timeout
