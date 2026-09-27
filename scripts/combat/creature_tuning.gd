class_name CreatureTuning
extends Resource
## Values of the Margin creatures of phase 3 (36, 89, 92), to be found by
## playing. Saved in assets/combat/creature_tuning.tres and editable in the
## F1 panel. Times in seconds, distances in meters.

@export_group("Common")
## Creatures notice Ottavia within this distance (their own values can differ).
@export var leash_distance: float = 14.0

@export_group("Voltafaccia (B31)")
@export var voltafaccia_health: float = 30.0
@export var voltafaccia_speed: float = 2.2
@export var voltafaccia_aggro: float = 7.0
@export var voltafaccia_attack_range: float = 1.5
@export var voltafaccia_windup: float = 0.5
@export var voltafaccia_active: float = 0.12
@export var voltafaccia_exposed: float = 0.8
@export var voltafaccia_cooldown: float = 1.4
@export var voltafaccia_damage: float = 10.0
@export var voltafaccia_lunge: float = 0.7
## Damage multiplier when hit on the shaded side (its right, 36).
@export var voltafaccia_shade_multiplier: float = 2.0
## Half-angle of the shaded side, around the creature's right.
@export var voltafaccia_shade_degrees: float = 60.0

@export_group("Raspagelo (B5)")
@export var raspagelo_health: float = 25.0
@export var raspagelo_burrow_speed: float = 3.5
@export var raspagelo_aggro: float = 8.0
## Ground shaking before it bursts out: the time to step aside.
@export var raspagelo_telegraph: float = 0.7
@export var raspagelo_damage: float = 12.0
@export var raspagelo_burst_radius: float = 1.1
## Open right after bursting out (counter-hit window).
@export var raspagelo_exposed: float = 0.8
@export var raspagelo_surfaced: float = 0.8
@export var raspagelo_underground_min: float = 1.2
## Frontal strikes on the head plate while not open.
@export var raspagelo_armor_multiplier: float = 0.5

@export_group("Brinacchio (B1)")
@export var brinacchio_health: float = 8.0
@export var brinacchio_speed: float = 3.0
@export var brinacchio_aggro: float = 4.0
## With the lantern open they sense Ottavia from farther away (36).
@export var brinacchio_lantern_aggro: float = 11.0
## Shutter closed and farther than this: they lose her track.
@export var brinacchio_lose_track: float = 3.0
@export var brinacchio_latch_range: float = 0.6
@export var brinacchio_latch_damage_per_second: float = 2.0
## Speed lost per parasite attached (sum capped by brinacchio_max_slow).
@export var brinacchio_slow: float = 0.15
@export var brinacchio_max_slow: float = 0.6
## Frost crust after coming off: blocks strikes until torn by the hook.
@export var brinacchio_crust_seconds: float = 4.0

@export_group("Grappolo (B7)")
@export var grappolo_members: int = 6
@export var grappolo_member_health: float = 8.0
@export var grappolo_aggro: float = 9.0
@export var grappolo_roll_windup: float = 0.7
@export var grappolo_roll_speed: float = 7.0
@export var grappolo_roll_seconds: float = 1.0
@export var grappolo_roll_cooldown: float = 1.8
@export var grappolo_damage: float = 14.0
## Outer shells: share of a strike that reaches the huddled ball.
@export var grappolo_shell_multiplier: float = 0.5
@export var grappolo_reform_seconds: float = 3.0
@export var grappolo_bit_speed: float = 1.5
