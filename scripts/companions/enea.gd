class_name Enea
extends CharacterBody3D
## Enea, the apprentice (81). He always walks with Ottavia. In a fight he is
## never an escort mission: he cannot die, and when hit he falls and gets up.
## At first he stays back; each move the player does well (parry, counter,
## combo, step, hook) is counted, and after `enea_learn_count` a signal says
## "Enea learned ..." and from then on he uses it. In a lesson (82) the
## player guides him directly.

signal learned(technique: StringName)
signal deflected
signal hit_taken

enum State { FOLLOW, DOWN, CONTROLLED }

const LIT_SHADER: Shader = preload("res://scenes/proto/materials/sprite_billboard_lit.gdshader")
const TECHNIQUES: Array[StringName] = [&"parry", &"counter", &"combo", &"step", &"hook"]
const GRAVITY: float = 20.0

@export var tuning: CombatTuning

var state: State = State.FOLLOW
var known: Dictionary = {}
var counts: Dictionary = {}
## Seconds since the parry was pressed while the player guides him; -1: not held.
var parry_time: float = -1.0
var _down_left: float = 0.0
var _attack_left: float = 0.0
var _flash: float = 0.0
var _flash_color: Color = Color.WHITE
var _material: ShaderMaterial = ShaderMaterial.new()
var _connected: bool = false

@onready var sprite: Sprite3D = $Sprite3D


func _ready() -> void:
	add_to_group(&"fighters")
	_material.shader = LIT_SHADER
	_material.set_shader_parameter(&"sprite_texture", sprite.texture)
	sprite.material_override = _material
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func knows(technique: StringName) -> bool:
	return known.get(technique, false)


func can_be_attacked() -> bool:
	return state != State.DOWN


func learn(technique: StringName) -> void:
	if knows(technique):
		return
	known[technique] = true
	SoundBank.play_sound(get_tree(), &"segnale_enea", 0.0)
	var hud: CombatHud = get_tree().get_first_node_in_group(&"combat_hud") as CombatHud
	if hud != null:
		hud.show_message(StringName("ENEA_LEARNED_" + String(technique).to_upper()))
	learned.emit(technique)


func count_technique(technique: StringName) -> void:
	if knows(technique) or not technique in TECHNIQUES:
		return
	counts[technique] = int(counts.get(technique, 0)) + 1
	if int(counts[technique]) >= tuning.enea_learn_count:
		learn(technique)


## An attack aimed at Enea: deflected if he parries in time (guided, or by
## himself once learned), otherwise he falls and gets up.
func receive_attack(attack: CombatAttack) -> int:
	if state == State.DOWN:
		return CombatAttack.Result.EVADED
	var parried: bool = false
	if state == State.CONTROLLED:
		parried = parry_time >= 0.0 and parry_time <= tuning.deflect_window
	elif knows(&"parry"):
		parried = randf() < tuning.enea_parry_chance
	if parried and attack.deflectable:
		if attack.source != null:
			attack.source.stagger(tuning.deflect_stagger_seconds)
		SoundBank.play_sound(get_tree(), &"deviazione")
		_flash = 0.8
		_flash_color = Color(0.85, 0.9, 1.0)
		deflected.emit()
		return CombatAttack.Result.DEFLECTED
	if state == State.FOLLOW and knows(&"step") and randf() < 0.5:
		return CombatAttack.Result.EVADED
	state = State.DOWN if state == State.FOLLOW else state
	_down_left = tuning.enea_down_seconds
	_flash = 1.0
	_flash_color = Color(1.0, 0.45, 0.4)
	SoundBank.play_sound(get_tree(), &"colpo_subito")
	hit_taken.emit()
	return CombatAttack.Result.HIT


func _physics_process(delta: float) -> void:
	var player: OttaviaProto = get_tree().get_first_node_in_group(&"player") as OttaviaProto
	if player == null:
		return
	if not _connected:
		_connected = true
		player.combat.technique_done.connect(count_technique)
	_flash = maxf(0.0, _flash - 6.0 * delta)
	var move: Vector3 = Vector3.ZERO
	match state:
		State.FOLLOW:
			move = _follow_move(player)
			_fight(delta)
		State.DOWN:
			_down_left -= delta
			_flash = maxf(_flash, 0.35)
			_flash_color = Color(0.55, 0.55, 0.65)
			if _down_left <= 0.0:
				state = State.FOLLOW
		State.CONTROLLED:
			var input: Vector2 = Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
			move = Vector3(input.x, 0.0, input.y) * tuning.enea_speed * (0.4 if parry_time >= 0.0 else 1.0)
			if Input.is_action_just_pressed(&"parry"):
				press_parry()
			elif Input.is_action_just_released(&"parry"):
				release_parry()
			if parry_time >= 0.0:
				parry_time += delta
				_flash = maxf(_flash, 0.15)
				_flash_color = Color(0.85, 0.92, 1.0)
	velocity.x = move.x
	velocity.z = move.z
	velocity.y = 0.0 if is_on_floor() else velocity.y - GRAVITY * delta
	move_and_slide()
	if absf(move.x) > 0.1:
		sprite.flip_h = move.x > 0.0
	_material.set_shader_parameter(&"flash", _flash * HitFeedback.flash_scale)
	_material.set_shader_parameter(&"flash_color", _flash_color)


func press_parry() -> void:
	parry_time = 0.0


func release_parry() -> void:
	parry_time = -1.0


## Behind Ottavia; while he knows no attack he keeps away from creatures.
func _follow_move(player: OttaviaProto) -> Vector3:
	var goal: Vector3 = player.global_position - player.facing_vector() * tuning.enea_follow_distance
	var creature: CombatEnemy = _nearest_creature(tuning.enea_keep_back)
	if creature != null and not (knows(&"counter") or knows(&"combo")):
		goal = global_position + OttaviaCombat._flat_direction(global_position - creature.global_position) * 2.0
	var offset: Vector3 = goal - global_position
	offset.y = 0.0
	if offset.length() < 0.3:
		return Vector3.ZERO
	var speed: float = tuning.enea_speed * (1.5 if offset.length() > 5.0 else 1.0)
	return offset.normalized() * minf(speed, offset.length() * 4.0)


## Once he has learned the counter or the combo, he strikes nearby creatures:
## the counter only when they are open.
func _fight(delta: float) -> void:
	_attack_left -= delta
	if _attack_left > 0.0 or not (knows(&"counter") or knows(&"combo")):
		return
	var creature: CombatEnemy = _nearest_creature(tuning.enea_attack_reach)
	if creature == null or (not knows(&"combo") and not creature.is_exposed()):
		return
	_attack_left = tuning.enea_attack_interval
	var hit: CombatHit = CombatHit.new()
	hit.source = self
	hit.direction = OttaviaCombat._flat_direction(creature.global_position - global_position)
	hit.critical = creature.is_exposed() and knows(&"counter")
	hit.damage = tuning.enea_attack_damage * (tuning.counter_multiplier if hit.critical else 1.0)
	CombatEffects.swing(get_tree().current_scene, global_position + Vector3.UP * 0.7, hit.direction, tuning.enea_attack_reach, 100.0, Color(1.0, 0.95, 0.8, 0.8))
	creature.receive_hit(hit)


func _nearest_creature(within: float) -> CombatEnemy:
	var best: CombatEnemy = null
	var best_distance: float = within
	for node: Node in get_tree().get_nodes_in_group(&"combat_targets"):
		var creature: CombatEnemy = node as CombatEnemy
		if creature == null or not creature.can_be_targeted() or creature is TrainingDummy:
			continue
		var distance: float = Vector2(creature.global_position.x - global_position.x, creature.global_position.z - global_position.z).length()
		if distance < best_distance:
			best = creature
			best_distance = distance
	return best
