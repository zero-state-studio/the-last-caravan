class_name SummitArena
extends BossArena
## The top of the third cart (room 7): a round turning top, 16 m across,
## with four levers on the fixed rim, each turning it a quarter. The rooted
## boss turns with it and then back toward the sun, opening its flank. In
## phase 2 two Voltafaccia come up from the rim, once. If Ottavia falls,
## the fight starts over (105). Won, it waits for the boss to roll away.

signal won_fight

const VOLTAFACCIA_SCENE: PackedScene = preload("res://scenes/creatures/voltafaccia.tscn")

var platform: TurningPlatform
var levers: Array[TurnLever] = []
var reinforcements: Array[CombatEnemy] = []


## Built in code: set everything before the fight (instead of node paths).
func setup(fight_room: Room, fight_boss: BossEnemy, top: TurningPlatform, rim_levers: Array[TurnLever]) -> void:
	room = fight_room
	boss = fight_boss
	platform = top
	levers = rim_levers
	boss.defeated.connect(_on_boss_defeated)
	(boss as RootedFoglione).rolled_away.connect(func() -> void: won_fight.emit())
	_connect_manager.call_deferred()


func _ready() -> void:
	# The nodes come from setup(); BossArena would read node paths here.
	pass


func _process(_delta: float) -> void:
	var rooted: RootedFoglione = boss as RootedFoglione
	if rooted == null or won:
		return
	if rooted.take_pending_call() == &"voltafaccia":
		_call_voltafaccia()


## Two Voltafaccia climb over the rim, on the side away from Ottavia.
func _call_voltafaccia() -> void:
	var ottavia: OttaviaProto = player()
	var away: Vector3 = Vector3.BACK
	if ottavia != null:
		away = -OttaviaCombat._flat_direction(ottavia.global_position - platform.global_position)
	for side: float in [-0.5, 0.5]:
		var beast: CombatEnemy = VOLTAFACCIA_SCENE.instantiate() as CombatEnemy
		beast.position = platform.global_position + away.rotated(Vector3.UP, side) * 6.5 + Vector3.UP * 0.5
		get_parent().add_child(beast)
		reinforcements.append(beast)


func _reset_arena() -> void:
	platform.set_quarter(0)
	for beast: CombatEnemy in reinforcements:
		if is_instance_valid(beast):
			beast.queue_free()
	reinforcements.clear()


func _on_won() -> void:
	for beast: CombatEnemy in reinforcements:
		if is_instance_valid(beast) and beast.is_alive():
			beast.queue_free()
