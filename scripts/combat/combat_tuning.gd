class_name CombatTuning
extends Resource
## Every number of the combat prototype (33), to be found by playing in
## phase 3. Saved in assets/combat/combat_tuning.tres and editable in the F1
## panel. Times are in seconds, distances in meters, breath in points.

@export_group("Ottavia")
@export var max_health: float = 150.0
@export var move_speed: float = 3.0

@export_group("Breath")
@export var max_stamina: float = 100.0
@export var stamina_regen_per_second: float = 55.0
## Time without actions before the breath starts coming back.
@export var stamina_regen_delay: float = 0.6
## Share of the regeneration while walking: stopping is worth it (33).
@export var walking_regen_multiplier: float = 0.5
@export var breathless_seconds: float = 1.0
@export var breathless_damage_multiplier: float = 1.3
@export var breathless_speed_multiplier: float = 0.5

@export_group("Strike")
@export var strike_damage: float = 14.0
@export var strike_stamina_cost: float = 4.0
@export var strike_startup: float = 0.12
@export var strike_active: float = 0.08
@export var strike_recovery: float = 0.22
@export var strike_reach: float = 2.3
@export var strike_arc_degrees: float = 120.0
@export var combo_length: int = 3
@export var combo_finisher_multiplier: float = 1.8
@export var strike_knockback: float = 0.4
@export var strike_lunge: float = 0.35

@export_group("Counter-hit")
@export var counter_multiplier: float = 2.0

@export_group("Hook")
@export var hook_stamina_cost: float = 8.0
@export var hook_startup: float = 0.14
@export var hook_active: float = 0.1
@export var hook_recovery: float = 0.24
@export var hook_reach: float = 3.2
@export var hook_arc_degrees: float = 60.0
## Holding the button this long turns the pull into a push.
@export var hook_hold_seconds: float = 0.35
## Distance from Ottavia where a pulled creature ends.
@export var hook_pull_distance: float = 1.3
@export var hook_push_distance: float = 3.5
@export var hook_damage: float = 4.0

@export_group("Parry")
## Breath spent just by pressing parry; 0: only blocked hits cost breath, and
## a deflection is always free (the reward for timing).
@export var parry_press_cost: float = 0.0
@export var block_hit_cost: float = 15.0
## A hit landing this soon after pressing parry is deflected.
@export var deflect_window: float = 0.25
@export var parry_speed_multiplier: float = 0.4
@export var deflect_stagger_seconds: float = 1.2

@export_group("Step")
@export var step_stamina_cost: float = 20.0
@export var step_distance: float = 1.7
@export var step_seconds: float = 0.16
@export var step_invulnerable_seconds: float = 0.12

@export_group("Hit taken")
@export var hitstun_seconds: float = 0.25
@export var hit_knockback: float = 0.7

@export_group("Lantern")
@export var lantern_hold_seconds: float = 0.3
@export var lantern_raised_range_multiplier: float = 1.8

@export_group("Feel")
@export var hitstop_seconds: float = 0.06
@export var hitstop_critical_seconds: float = 0.12
@export var shake_meters: float = 0.08
@export var shake_critical_meters: float = 0.16
@export var aim_assist_degrees: float = 35.0
## A press this early is kept and used as soon as the action is possible.
@export var input_buffer_seconds: float = 0.2

@export_group("Training dummy")
@export var dummy_attack_interval: float = 2.2
@export var dummy_windup: float = 0.6
@export var dummy_active: float = 0.12
## After its swing the dummy is open: a strike now is a counter-hit.
@export var dummy_exposed: float = 0.7
@export var dummy_damage: float = 8.0
@export var dummy_reach: float = 2.4
@export var dummy_health: float = 150.0
@export var dummy_respawn_seconds: float = 2.5

@export_group("Enea")
@export var enea_speed: float = 3.3
## Distance he keeps behind Ottavia.
@export var enea_follow_distance: float = 1.8
## At first he stays this far from creatures (81).
@export var enea_keep_back: float = 3.0
## Moves done well by the player before Enea learns them.
@export var enea_learn_count: int = 3
@export var enea_down_seconds: float = 1.5
## Chance that Enea deflects a hit once he has learned the parry.
@export var enea_parry_chance: float = 0.8
@export var enea_attack_damage: float = 5.0
@export var enea_attack_interval: float = 1.2
@export var enea_attack_reach: float = 1.5

@export_group("Tosca")
@export var tosca_cooldown: float = 12.0
@export var tosca_range: float = 8.0
## Where the dragged creature ends, in front of Ottavia.
@export var tosca_pull_distance: float = 1.5
@export var tosca_damage: float = 8.0
## Heavy creatures and bosses cannot be dragged: they only stagger.
@export var tosca_heavy_stagger: float = 1.0
