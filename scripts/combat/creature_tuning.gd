class_name CreatureTuning
extends Resource
## Values of the creatures (36): those of phase 3 (89, 92) and those of
## chapter 1 (docs/livelli/capitolo-01.md, section 6), to be tuned by
## playing. Saved in assets/combat/creature_tuning.tres and editable in the
## F1 panel. Times in seconds, distances in meters. Chapter 1 gives the
## resistance in base strikes ("hits"): how many plain strikes of Ottavia,
## without criticals, bring the creature down (see health_for_hits).

const COMBAT_TUNING_PATH: String = "res://assets/combat/combat_tuning.tres"

@export_group("Common")
## Creatures notice Ottavia within this distance (their own values can differ).
@export var leash_distance: float = 14.0

## Day beasts carried by a turning terrace turn back toward the sun over
## this time, showing their shaded flank (chapter 1, section 4).
@export var day_beast_flank_seconds: float = 2.0

@export_group("Voltafaccia (B31)")
## Chapter 1: 3 base strikes, headbutt with 0.5 s of warning for 8, the
## herd alarmed within 5 m, attacking one at a time.
@export var voltafaccia_hits: float = 3.0
@export var voltafaccia_speed: float = 2.2
@export var voltafaccia_aggro: float = 5.0
@export var voltafaccia_attack_range: float = 1.5
@export var voltafaccia_windup: float = 0.5
@export var voltafaccia_active: float = 0.12
@export var voltafaccia_exposed: float = 0.8
@export var voltafaccia_cooldown: float = 1.8
@export var voltafaccia_damage: float = 8.0
@export var voltafaccia_lunge: float = 0.7
## Damage multiplier when hit on the shaded side (its right, 36).
@export var voltafaccia_shade_multiplier: float = 2.0
## Half-angle of the shaded side, around the creature's right.
@export var voltafaccia_shade_degrees: float = 60.0

@export_group("Raspagelo (B5)")
## Chapter 1: 2 base strikes; within 2 m the ground swells (0.6 s), it
## bursts out and bites for 10, dives back after 2 s; hooked while the
## ground swells, it is pulled out stunned.
@export var raspagelo_hits: float = 2.0
@export var raspagelo_burrow_speed: float = 3.5
@export var raspagelo_aggro: float = 2.0
## Ground shaking before it bursts out: the time to step aside.
@export var raspagelo_telegraph: float = 0.6
@export var raspagelo_damage: float = 10.0
@export var raspagelo_burst_radius: float = 1.1
## Open right after bursting out (counter-hit window); with `surfaced`
## the 2 s it stays out.
@export var raspagelo_exposed: float = 1.0
@export var raspagelo_surfaced: float = 1.0
@export var raspagelo_hooked_stun: float = 1.5
@export var raspagelo_underground_min: float = 1.2
## Frontal strikes on the head plate while not open.
@export var raspagelo_armor_multiplier: float = 0.5

@export_group("Coccio (B39)")
## Slow; one more crack in the shell at every strike, broken at the third.
@export var coccio_hits: float = 3.0
@export var coccio_speed: float = 0.7
@export var coccio_aggro: float = 5.0
@export var coccio_attack_range: float = 0.9
@export var coccio_windup: float = 0.5
@export var coccio_damage: float = 5.0
@export var coccio_cooldown: float = 1.6

@export_group("Frinitore (B38)")
## A floating cloud 1.5 m across; 3 damage a second to whoever is inside;
## thinner at every strike. Its song grows toward the warm side (west).
@export var frinitore_hits: float = 4.0
@export var frinitore_diameter: float = 1.5
@export var frinitore_damage_per_second: float = 3.0
## Not in the document: it drifts slowly toward Ottavia within this range,
## otherwise hovers around its place (TODO-DESIGN #107, to confirm).
@export var frinitore_speed: float = 0.8
@export var frinitore_aggro: float = 6.0

@export_group("Specchietto (B32)")
## Basks in the sun; lit and within 8 m it flashes (0.5 s of warning):
## Ottavia is dazzled for 1.2 s, slower and without aim assist. In the
## shade it hides. One strike.
@export var specchietto_hits: float = 1.0
@export var specchietto_range: float = 8.0
@export var specchietto_windup: float = 0.5
@export var specchietto_dazzle_seconds: float = 1.2
@export var specchietto_dazzle_speed: float = 0.6
@export var specchietto_cooldown: float = 2.5

@export_group("Foglione (B33)")
## Calm until disturbed; the closed leaves cover its front, the flank takes
## double damage; leaf blow in front with 0.8 s of warning for 12.
@export var foglione_hits: float = 6.0
@export var foglione_windup: float = 0.8
@export var foglione_damage: float = 12.0
@export var foglione_range: float = 2.2
@export var foglione_front_degrees: float = 60.0
@export var foglione_flank_multiplier: float = 2.0
@export var foglione_cooldown: float = 1.6
## Disturbed: when hit, or when Ottavia comes this close in front.
@export var foglione_disturb_distance: float = 1.2
@export var foglione_calm_seconds: float = 8.0

@export_group("Pellegrino di feltro (B2)")
## Only in the Truce; does not attack unless provoked. First the felt (3
## base strikes), then the body (4); a push for 15 with 0.8 s of warning.
@export var pellegrino_felt_hits: float = 3.0
@export var pellegrino_body_hits: float = 4.0
@export var pellegrino_windup: float = 0.8
@export var pellegrino_damage: float = 15.0
@export var pellegrino_range: float = 2.2
@export var pellegrino_speed: float = 1.3
@export var pellegrino_cooldown: float = 2.0

@export_group("Brinacchio (B1)")
@export var brinacchio_health: float = 6.0
@export var brinacchio_speed: float = 3.0
@export var brinacchio_aggro: float = 4.0
## With the lantern open they sense Ottavia from farther away (36).
@export var brinacchio_lantern_aggro: float = 8.0
## Shutter closed and farther than this: they lose her track.
@export var brinacchio_lose_track: float = 3.0
@export var brinacchio_latch_range: float = 0.6
## Besides slowing down whoever they cling to (B1), they drain a little
## health, so a swarm on her back is a real danger (decided 2026-09-28).
@export var brinacchio_latch_damage_per_second: float = 2.0
## Speed lost per parasite attached (sum capped by brinacchio_max_slow).
@export var brinacchio_slow: float = 0.15
@export var brinacchio_max_slow: float = 0.6
## Frost crust after coming off: a strike cracks it, the hook tears it,
## otherwise it melts after this long.
@export var brinacchio_crust_seconds: float = 4.0

@export_group("Grappolo (B7)")
@export var grappolo_members: int = 6
@export var grappolo_member_health: float = 6.0
@export var grappolo_aggro: float = 9.0
@export var grappolo_roll_windup: float = 0.9
@export var grappolo_roll_speed: float = 6.0
@export var grappolo_roll_seconds: float = 1.0
@export var grappolo_roll_cooldown: float = 1.8
@export var grappolo_damage: float = 9.0
## Outer shells: share of a strike that reaches the huddled ball.
@export var grappolo_shell_multiplier: float = 0.7
@export var grappolo_reform_seconds: float = 3.0
@export var grappolo_bit_speed: float = 1.5

@export_group("Foglione Radicato (83)")
@export var foglione_health: float = 200.0
## How fast the rooted beast turns its leaves after the sun (degrees/s).
@export var foglione_turn_degrees_per_second: float = 40.0
## Share of damage that gets through the leaves.
@export var foglione_leaf_multiplier: float = 0.2
## Half-angle of the leaf-covered side, around its facing (toward the sun).
@export var foglione_leaf_degrees: float = 80.0
@export var foglione_root_interval: float = 3.2
@export var foglione_root_telegraph: float = 0.9
@export var foglione_root_damage: float = 10.0
@export var foglione_root_radius: float = 1.3
@export var foglione_sweep_range: float = 3.2
@export var foglione_sweep_windup: float = 0.8
@export var foglione_sweep_damage: float = 11.0
@export var foglione_sweep_exposed: float = 0.7
## Damage taken before it closes its leaves all around.
@export var foglione_close_after_damage: float = 60.0
@export var foglione_close_seconds: float = 2.5
## The field stays tilted (sun on the other side) this long after the lever.
@export var field_tilt_seconds: float = 9.0
@export var field_lever_cooldown: float = 12.0

@export_group("Foglione Radicato, chapter 1 (107)")
## About 30 base strikes, about 15 on the flank (double damage).
@export var rooted_hits: float = 30.0
@export var rooted_flank_multiplier: float = 2.0
## Front covered by the closed leaves: strikes bounce off.
@export var rooted_front_degrees: float = 70.0
## Phases: from full to this share, then to the next.
@export var rooted_phase_2_share: float = 0.66
@export var rooted_phase_3_share: float = 0.33
## Seconds between one attack and the next.
@export var rooted_attack_interval: float = 2.6
## Leaf lash: a 120 degree arc in front.
@export var rooted_lash_windup: float = 0.7
@export var rooted_lash_damage: float = 15.0
@export var rooted_lash_range: float = 4.5
@export var rooted_lash_degrees: float = 120.0
## Seeds: a burst in a straight line toward Ottavia.
@export var rooted_seed_windup: float = 0.6
@export var rooted_seed_damage: float = 10.0
@export var rooted_seed_width: float = 0.9
## Roots (phase 2 on): three lines from the centre to the edge, cracks in
## the planks first.
@export var rooted_root_windup: float = 0.8
@export var rooted_root_damage: float = 20.0
@export var rooted_root_width: float = 1.0
## Window on the flank after each turn of the arena, per phase.
@export var rooted_window_1: float = 3.0
@export var rooted_window_2: float = 2.0
@export var rooted_window_3: float = 1.2
## Phase 3: two turns less than this apart lengthen the window.
@export var rooted_double_turn_seconds: float = 2.0
@export var rooted_double_turn_bonus: float = 1.5
## Phase 3: every so often it opens its leaves to the sun and regains
## resistance (in base strikes), unless a flank strike interrupts it.
@export var rooted_bask_interval: float = 20.0
@export var rooted_bask_seconds: float = 3.0
@export var rooted_bask_regain_hits: float = 5.0

@export_group("Vecchio Spartighiaccio (41)")
@export var sparti_health: float = 240.0
@export var sparti_aim_seconds: float = 1.2
@export var sparti_charge_speed: float = 9.0
@export var sparti_charge_max_distance: float = 16.0
@export var sparti_charge_damage: float = 16.0
@export var sparti_recover_seconds: float = 2.0
## Stopped at the edge of broken ice: open for longer.
@export var sparti_stuck_seconds: float = 3.0
## Share of damage that gets through the front shield.
@export var sparti_shield_multiplier: float = 0.1
@export var sparti_shield_degrees: float = 60.0
@export var sparti_stomp_range: float = 2.2
@export var sparti_stomp_telegraph: float = 0.6
@export var sparti_stomp_damage: float = 10.0
@export var ice_fall_damage: float = 15.0


## Health for a resistance given in base strikes (chapter 1, section 1):
## hits times the damage of a plain strike (CombatTuning.strike_damage).
## Untyped and without a static cache on purpose: either keeps the tuning
## scripts in use at exit.
static func health_for_hits(hits: float) -> float:
	var combat: Resource = load(COMBAT_TUNING_PATH)
	return hits * (float(combat.get(&"strike_damage")) if combat != null else 14.0)
