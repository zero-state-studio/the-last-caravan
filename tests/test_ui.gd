extends SceneTree
## The play interface (125): sundial, rope, hints with key icons, dialogue
## text size (96), the farewell lantern in the pause menu (88).
## Usage: godot --headless --path . --script res://tests/test_ui.gd

var _checks: int = 0
var _failures: int = 0


func _initialize() -> void:
	await _test_hud()
	await _test_hints()
	await _test_dialogue_size()
	await _test_pause_lantern()
	_test_translation_rows()
	print("TESTS: ui %d checks, %d failures" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)


func _test_hud() -> void:
	var floor: Node3D = (load(PrologueState.FLOOR_SCENE) as PackedScene).instantiate()
	floor.intro_seconds = 0.0
	floor.leave_scene = false
	root.add_child(floor)
	current_scene = floor
	await _frames(2)
	var ottavia: OttaviaProto = floor.ottavia
	var hud: CombatHud = CombatHud.new()
	floor.add_child(hud)
	hud.bind(ottavia)
	await _frames(3)
	ottavia.health = ottavia.max_health * 0.5
	ottavia.combat.stamina = ottavia.combat.max_stamina() * 0.25
	await process_frame
	await process_frame
	_check(absf(hud.gauge.health_ratio - 0.5) < 0.01 and hud.gauge.breath_ratio > 0.2 and hud.gauge.breath_ratio < 0.45, "hud: the sundial shows health on the outer arc and breath on the inner one")
	var view: Vector2 = root.get_visible_rect().size
	var corner: Vector2 = hud.gauge.get_global_rect().position
	_check(corner.x < view.x * 0.2 and corner.y > view.y * 0.6, "hud: the sundial sits at the bottom left")
	var rope: RopeCounter = RopeCounter.new()
	floor.add_child(rope)
	await process_frame
	rope.set_knots(0)
	rope.add_knot()
	_check(rope.knots == 1, "hud: a saved person adds a knot to the rope")
	floor.queue_free()
	await _frames(2)


func _test_hints() -> void:
	var hints: HintBanner = HintBanner.new()
	root.add_child(hints)
	await process_frame
	var jump: PackedStringArray = HintBanner.key_caps(&"jump", InputRemap.Device.KEYBOARD)
	var move: PackedStringArray = HintBanner.key_caps(&"move", InputRemap.Device.KEYBOARD)
	_check(jump.size() == 1 and not jump[0].is_empty() and move.size() == 4, "hints: one key icon for an action, four for moving")
	hints.show_hint(&"PRO_HINT_JUMP", &"jump")
	await process_frame
	_check(hints.current_hint() == &"PRO_HINT_JUMP", "hints: the hint text is shown with its key")
	hints.queue_free()
	await process_frame


func _test_dialogue_size() -> void:
	var box: DialogueBox = DialogueBox.new()
	root.add_child(box)
	await process_frame
	var before: float = GameOptions.text_scale
	GameOptions.text_scale = 1.5
	box.show_line(&"SPEAKER_OTTAVIA", &"PRO_OTTAVIA_01")
	var line: Label = box.find_children("*", "Label", true, false)[1]
	_check(line.get_theme_font_size(&"font_size") == roundi(UiStyle.BODY_SIZE * 1.5), "dialogue: the text size follows the option (96)")
	GameOptions.text_scale = before
	box.queue_free()
	await process_frame


func _test_pause_lantern() -> void:
	_check(LanternEmblem.piece_shapes().size() == LanternEmblem.PIECES and LanternEmblem.PIECES == 10, "lantern: ten pieces, one per dungeon (88)")
	var menu: OptionsMenu = OptionsMenu.new()
	root.add_child(menu)
	await process_frame
	LanternProgress.revealed = false
	menu.open()
	_check(not menu.lantern.get_parent().visible, "pause: before the verdict the lantern is not in the menu")
	menu.close()
	LanternProgress.revealed = true
	LanternProgress.pieces = 3
	menu.open()
	_check(menu.lantern.get_parent().visible and menu.lantern.pieces == 3, "pause: after the verdict the lantern shows, filled piece by piece (88)")
	menu.close()
	LanternProgress.revealed = false
	LanternProgress.pieces = 0
	menu.queue_free()
	await process_frame


## Every row of the translation table has key, English and Italian: a
## comma outside quotes would shift the columns.
func _test_translation_rows() -> void:
	var file: FileAccess = FileAccess.open("res://localization/translations.csv", FileAccess.READ)
	var bad: Array[String] = []
	while not file.eof_reached():
		var row: PackedStringArray = file.get_csv_line()
		if row.size() == 1 and row[0].is_empty():
			continue
		if row.size() != 3:
			bad.append(row[0])
	_check(bad.is_empty(), "translations: every row has three columns (%s)" % ", ".join(bad))


func _frames(count: int) -> void:
	for index: int in count:
		await physics_frame


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		print("FAIL: " + message)
