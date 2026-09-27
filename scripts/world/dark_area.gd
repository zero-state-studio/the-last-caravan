class_name DarkArea
extends Area3D
## A place where the lantern is the main light (45, 43): while Ottavia is
## inside, the lantern light casts shadows and, if the area is deep shadow,
## sun, sky light and fog fade down so the lantern is the only light left.
## Outside, in daylight, the lantern shadows stay off to keep the frame cheap
## on Steam Deck (7).

## Fade the scene light down while Ottavia is inside (deep shadow).
@export var deep_shadow: bool = false
## Paths, not typed node exports: hand-written paths in a .tscn do not
## resolve into typed node exports (see docs/tecnica.md).
@export var world_environment_path: NodePath
@export var sun_path: NodePath
## Share of the normal light kept inside, for sun, ambient light and fog.
@export_range(0.0, 1.0, 0.01) var light_kept: float = 0.04
@export var transition_seconds: float = 0.8

var world_environment: WorldEnvironment
var sun: DirectionalLight3D
var _tween: Tween
var _dark: bool = false
var _saved_sun_energy: float = 1.0
var _saved_ambient_energy: float = 1.0
var _saved_fog_density: float = 0.0
var _saved_volumetric_density: float = 0.0


func _ready() -> void:
	if not world_environment_path.is_empty():
		world_environment = get_node(world_environment_path) as WorldEnvironment
	if not sun_path.is_empty():
		sun = get_node(sun_path) as DirectionalLight3D
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node3D) -> void:
	if not body is OttaviaProto:
		return
	(body as OttaviaProto).enter_dark_area()
	if deep_shadow and sun != null and world_environment != null and not _dark:
		_dark = true
		var environment: Environment = world_environment.environment
		_saved_sun_energy = sun.light_energy
		_saved_ambient_energy = environment.ambient_light_energy
		_saved_fog_density = environment.fog_density
		_saved_volumetric_density = environment.volumetric_fog_density
		_fade_to(light_kept)


func _on_body_exited(body: Node3D) -> void:
	if not body is OttaviaProto:
		return
	(body as OttaviaProto).exit_dark_area()
	if _dark:
		_dark = false
		_fade_to(1.0)


func _fade_to(share: float) -> void:
	if _tween != null:
		_tween.kill()
	var environment: Environment = world_environment.environment
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(sun, "light_energy", _saved_sun_energy * share, transition_seconds)
	_tween.tween_property(environment, "ambient_light_energy", _saved_ambient_energy * share, transition_seconds)
	_tween.tween_property(environment, "fog_density", _saved_fog_density * share, transition_seconds)
	_tween.tween_property(environment, "volumetric_fog_density", _saved_volumetric_density * share, transition_seconds)
