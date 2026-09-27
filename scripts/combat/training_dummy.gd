class_name TrainingDummy
extends CombatEnemy
## Straw training dummy of the Voltacampi (phase 3): it never moves and
## swings its stick at a steady, tunable rhythm, to practise the parry, the
## deflection and the counter-hit (33). Telegraph: it leans back and glows
## warm before the swing. After the swing it stays open for a moment.

enum Phase { WAIT, WINDUP, ACTIVE, EXPOSED, DOWN }

const TELEGRAPH_COLOR: Color = Color(1.0, 0.6, 0.3)
const LEAN_PIXELS: float = 3.0

@export var tuning: CombatTuning

var phase: Phase = Phase.WAIT
## Held still (a lesson explains before it swings).
var paused: bool = false
var _phase_time: float = 0.0
var _sprite_rest: Vector3


func _ready() -> void:
	max_health = tuning.dummy_health
	heavy = true
	super._ready()
	_sprite_rest = sprite.position


## It gets up again after dummy_respawn_seconds.
func acts_when_defeated() -> bool:
	return true


func is_exposed() -> bool:
	return phase == Phase.EXPOSED or super.is_exposed()


func _behave(delta: float) -> void:
	if paused:
		sprite.position = _sprite_rest
		return
	_phase_time += delta
	var player: Node3D = find_target()
	var toward: Vector3 = Vector3.BACK
	if player != null:
		toward = OttaviaCombat._flat_direction(player.global_position - global_position)
	sprite.position = _sprite_rest
	match phase:
		Phase.WAIT:
			if is_staggered():
				_phase_time = 0.0
			elif _phase_time >= tuning.dummy_attack_interval:
				_set_phase(Phase.WINDUP)
		Phase.WINDUP:
			var t: float = _phase_time / maxf(tuning.dummy_windup, 0.01)
			sprite.position = _sprite_rest - toward * LEAN_PIXELS * WorldScale.METERS_PER_PIXEL * t
			flash(0.35 + 0.35 * t, TELEGRAPH_COLOR)
			if _phase_time >= tuning.dummy_windup:
				_set_phase(Phase.ACTIVE)
				_swing(player, toward)
		Phase.ACTIVE:
			sprite.position = _sprite_rest + toward * LEAN_PIXELS * 2.0 * WorldScale.METERS_PER_PIXEL
			if _phase_time >= tuning.dummy_active:
				_set_phase(Phase.EXPOSED)
		Phase.EXPOSED:
			if _phase_time >= tuning.dummy_exposed and not is_staggered():
				_set_phase(Phase.WAIT)
		Phase.DOWN:
			if _phase_time >= tuning.dummy_respawn_seconds:
				health = max_health
				sprite.visible = true
				_set_phase(Phase.WAIT)


func _swing(_target: Node3D, toward: Vector3) -> void:
	CombatEffects.swing(get_tree().current_scene, global_position + Vector3.UP * 0.9, toward, tuning.dummy_reach, 90.0, Color(1.0, 0.7, 0.45, 0.9))
	SoundBank.play_sound(get_tree(), &"colpo_bastone", 0.15)
	attack_player(tuning.dummy_damage, tuning.dummy_reach)


func _on_staggered() -> void:
	# A deflected swing leaves the dummy open for the stagger time.
	if phase == Phase.ACTIVE or phase == Phase.WINDUP:
		_set_phase(Phase.EXPOSED)


func _on_defeated() -> void:
	sprite.visible = false
	_set_phase(Phase.DOWN)


func _on_reset() -> void:
	_set_phase(Phase.WAIT)


func _set_phase(new_phase: Phase) -> void:
	phase = new_phase
	_phase_time = 0.0
