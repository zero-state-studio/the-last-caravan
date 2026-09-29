class_name TuningPanel
extends CanvasLayer
## F1 panel of the visual prototype: sliders bound to ProtoSettings.
## Every visible text is a translation key (see localization/translations.csv).

signal settings_changed
signal save_requested
signal combat_save_requested
signal creatures_save_requested
signal chapter_save_requested
signal end_chapter_requested
## Systems yard of phase 4b step 1: start a Truce, go to the yard.
signal truce_requested
signal yard_requested

const SLIDERS: Array[Dictionary] = [
	{"key": "DEV_CAMERA_PITCH", "property": "camera_pitch", "min": 30.0, "max": 70.0, "step": 0.5},
	{"key": "DEV_CAMERA_DISTANCE", "property": "camera_distance", "min": 4.0, "max": 40.0, "step": 0.5},
	{"key": "DEV_CAMERA_FOV", "property": "camera_fov", "min": 10.0, "max": 75.0, "step": 0.5},
	{"key": "DEV_DOF_NEAR", "property": "dof_near_offset", "min": 0.0, "max": 20.0, "step": 0.5},
	{"key": "DEV_DOF_FAR", "property": "dof_far_offset", "min": 0.0, "max": 40.0, "step": 0.5},
	{"key": "DEV_DOF_AMOUNT", "property": "dof_amount", "min": 0.0, "max": 0.5, "step": 0.01},
	{"key": "DEV_SPRITE_PIXEL_SIZE", "property": "sprite_pixel_size", "min": 0.02, "max": 0.06, "step": 0.0001},
	{"key": "DEV_WORLD_TEXELS", "property": "world_texels_per_meter", "min": 12.0, "max": 48.0, "step": 1.0},
	{"key": "DEV_SUN_ELEVATION", "property": "sun_elevation", "min": 2.0, "max": 60.0, "step": 0.5},
	{"key": "DEV_SUN_AZIMUTH", "property": "sun_azimuth", "min": 0.0, "max": 360.0, "step": 1.0},
	{"key": "DEV_SUN_ENERGY", "property": "sun_energy", "min": 0.0, "max": 5.0, "step": 0.05},
	{"key": "DEV_FOG_DENSITY", "property": "fog_density", "min": 0.0, "max": 0.05, "step": 0.001},
	{"key": "DEV_PALETTE_STRENGTH", "property": "palette_strength", "min": 0.0, "max": 2.0, "step": 0.05},
	{"key": "DEV_ZONE_NIGHT_PROXIMITY", "property": "zone_night_proximity", "min": -1.0, "max": 1.0, "step": 0.05},
	{"key": "DEV_CHAPTER", "property": "chapter", "min": 1.0, "max": 10.0, "step": 1.0},
]
const TOGGLES: Array[Dictionary] = [
	{"key": "DEV_CAMERA_ORTHOGRAPHIC", "property": "camera_orthographic"},
	{"key": "DEV_SPRITE_BILLBOARD_FIXED_Y", "property": "sprite_billboard_fixed_y"},
	{"key": "DEV_SPRITE_UPRIGHT_DEPTH", "property": "sprite_upright_depth"},
	{"key": "DEV_SPRITE_SHADED", "property": "sprite_shaded"},
	{"key": "DEV_SHOW_COMBAT_HUD", "property": "show_combat_hud"},
	{"key": "DEV_TOSCA_PRESENT", "property": "tosca_present"},
]
## Combat values (33), bound to CombatTuning; found by playing in phase 3.
const COMBAT_SLIDERS: Array[Dictionary] = [
	{"key": "DEV_C_MAX_HEALTH", "property": "max_health", "min": 20.0, "max": 300.0, "step": 5.0},
	{"key": "DEV_C_MOVE_SPEED", "property": "move_speed", "min": 1.0, "max": 6.0, "step": 0.1},
	{"key": "DEV_C_MAX_STAMINA", "property": "max_stamina", "min": 20.0, "max": 200.0, "step": 5.0},
	{"key": "DEV_C_STAMINA_REGEN_PER_SECOND", "property": "stamina_regen_per_second", "min": 5.0, "max": 120.0, "step": 1.0},
	{"key": "DEV_C_WALKING_REGEN_MULTIPLIER", "property": "walking_regen_multiplier", "min": 0.0, "max": 1.0, "step": 0.05},
	{"key": "DEV_C_STAMINA_REGEN_DELAY", "property": "stamina_regen_delay", "min": 0.0, "max": 2.0, "step": 0.05},
	{"key": "DEV_C_BREATHLESS_SECONDS", "property": "breathless_seconds", "min": 0.2, "max": 3.0, "step": 0.05},
	{"key": "DEV_C_BREATHLESS_DAMAGE_MULTIPLIER", "property": "breathless_damage_multiplier", "min": 1.0, "max": 3.0, "step": 0.05},
	{"key": "DEV_C_BREATHLESS_SPEED_MULTIPLIER", "property": "breathless_speed_multiplier", "min": 0.0, "max": 1.0, "step": 0.05},
	{"key": "DEV_C_STRIKE_DAMAGE", "property": "strike_damage", "min": 1.0, "max": 50.0, "step": 1.0},
	{"key": "DEV_C_STRIKE_STAMINA_COST", "property": "strike_stamina_cost", "min": 0.0, "max": 40.0, "step": 1.0},
	{"key": "DEV_C_STRIKE_STARTUP", "property": "strike_startup", "min": 0.0, "max": 0.6, "step": 0.01},
	{"key": "DEV_C_STRIKE_ACTIVE", "property": "strike_active", "min": 0.02, "max": 0.3, "step": 0.01},
	{"key": "DEV_C_STRIKE_RECOVERY", "property": "strike_recovery", "min": 0.0, "max": 1.0, "step": 0.01},
	{"key": "DEV_C_STRIKE_REACH", "property": "strike_reach", "min": 1.0, "max": 4.0, "step": 0.05},
	{"key": "DEV_C_STRIKE_ARC_DEGREES", "property": "strike_arc_degrees", "min": 30.0, "max": 200.0, "step": 5.0},
	{"key": "DEV_C_COMBO_LENGTH", "property": "combo_length", "min": 1.0, "max": 5.0, "step": 1.0},
	{"key": "DEV_C_COMBO_FINISHER_MULTIPLIER", "property": "combo_finisher_multiplier", "min": 1.0, "max": 3.0, "step": 0.05},
	{"key": "DEV_C_STRIKE_KNOCKBACK", "property": "strike_knockback", "min": 0.0, "max": 2.0, "step": 0.05},
	{"key": "DEV_C_STRIKE_LUNGE", "property": "strike_lunge", "min": 0.0, "max": 1.0, "step": 0.05},
	{"key": "DEV_C_COUNTER_MULTIPLIER", "property": "counter_multiplier", "min": 1.0, "max": 4.0, "step": 0.05},
	{"key": "DEV_C_HOOK_STAMINA_COST", "property": "hook_stamina_cost", "min": 0.0, "max": 40.0, "step": 1.0},
	{"key": "DEV_C_HOOK_STARTUP", "property": "hook_startup", "min": 0.0, "max": 0.6, "step": 0.01},
	{"key": "DEV_C_HOOK_ACTIVE", "property": "hook_active", "min": 0.02, "max": 0.3, "step": 0.01},
	{"key": "DEV_C_HOOK_RECOVERY", "property": "hook_recovery", "min": 0.0, "max": 1.0, "step": 0.01},
	{"key": "DEV_C_HOOK_REACH", "property": "hook_reach", "min": 1.0, "max": 5.0, "step": 0.05},
	{"key": "DEV_C_HOOK_ARC_DEGREES", "property": "hook_arc_degrees", "min": 10.0, "max": 120.0, "step": 5.0},
	{"key": "DEV_C_HOOK_HOLD_SECONDS", "property": "hook_hold_seconds", "min": 0.1, "max": 1.0, "step": 0.05},
	{"key": "DEV_C_HOOK_PULL_DISTANCE", "property": "hook_pull_distance", "min": 0.5, "max": 3.0, "step": 0.05},
	{"key": "DEV_C_HOOK_PUSH_DISTANCE", "property": "hook_push_distance", "min": 0.5, "max": 6.0, "step": 0.1},
	{"key": "DEV_C_HOOK_DAMAGE", "property": "hook_damage", "min": 0.0, "max": 20.0, "step": 1.0},
	{"key": "DEV_C_PARRY_PRESS_COST", "property": "parry_press_cost", "min": 0.0, "max": 40.0, "step": 1.0},
	{"key": "DEV_C_BLOCK_HIT_COST", "property": "block_hit_cost", "min": 0.0, "max": 60.0, "step": 1.0},
	{"key": "DEV_C_DEFLECT_WINDOW", "property": "deflect_window", "min": 0.02, "max": 0.6, "step": 0.01},
	{"key": "DEV_C_PARRY_SPEED_MULTIPLIER", "property": "parry_speed_multiplier", "min": 0.0, "max": 1.0, "step": 0.05},
	{"key": "DEV_C_DEFLECT_STAGGER_SECONDS", "property": "deflect_stagger_seconds", "min": 0.2, "max": 3.0, "step": 0.05},
	{"key": "DEV_C_JUMP_STAMINA_COST", "property": "jump_stamina_cost", "min": 0.0, "max": 60.0, "step": 1.0},
	{"key": "DEV_C_JUMP_HEIGHT", "property": "jump_height", "min": 0.2, "max": 2.0, "step": 0.05},
	{"key": "DEV_C_JUMP_INVULNERABLE_SECONDS", "property": "jump_invulnerable_seconds", "min": 0.0, "max": 0.5, "step": 0.01},
	{"key": "DEV_C_RUN_SPEED_MULTIPLIER", "property": "run_speed_multiplier", "min": 1.0, "max": 3.0, "step": 0.05},
	{"key": "DEV_C_RUN_STAMINA_PER_SECOND", "property": "run_stamina_per_second", "min": 0.0, "max": 60.0, "step": 1.0},
	{"key": "DEV_C_HITSTUN_SECONDS", "property": "hitstun_seconds", "min": 0.0, "max": 1.0, "step": 0.01},
	{"key": "DEV_C_HIT_KNOCKBACK", "property": "hit_knockback", "min": 0.0, "max": 2.0, "step": 0.05},
	{"key": "DEV_C_LANTERN_HOLD_SECONDS", "property": "lantern_hold_seconds", "min": 0.1, "max": 1.0, "step": 0.05},
	{"key": "DEV_C_LANTERN_RAISED_RANGE_MULTIPLIER", "property": "lantern_raised_range_multiplier", "min": 1.0, "max": 3.0, "step": 0.05},
	{"key": "DEV_C_WARM_STONE_HEAL", "property": "warm_stone_heal", "min": 5.0, "max": 100.0, "step": 1.0},
	{"key": "DEV_C_WARM_STONE_SECONDS", "property": "warm_stone_seconds", "min": 0.2, "max": 3.0, "step": 0.05},
	{"key": "DEV_C_WARM_STONE_MAX", "property": "warm_stone_max", "min": 1.0, "max": 6.0, "step": 1.0},
	{"key": "DEV_C_WARM_STONE_SPEED_MULTIPLIER", "property": "warm_stone_speed_multiplier", "min": 0.0, "max": 1.0, "step": 0.05},
	{"key": "DEV_C_HITSTOP_SECONDS", "property": "hitstop_seconds", "min": 0.0, "max": 0.3, "step": 0.01},
	{"key": "DEV_C_HITSTOP_CRITICAL_SECONDS", "property": "hitstop_critical_seconds", "min": 0.0, "max": 0.4, "step": 0.01},
	{"key": "DEV_C_SHAKE_METERS", "property": "shake_meters", "min": 0.0, "max": 0.4, "step": 0.01},
	{"key": "DEV_C_SHAKE_CRITICAL_METERS", "property": "shake_critical_meters", "min": 0.0, "max": 0.5, "step": 0.01},
	{"key": "DEV_C_AIM_CONE_DEGREES", "property": "aim_cone_degrees", "min": 0.0, "max": 180.0, "step": 5.0},
	{"key": "DEV_C_AIM_CONE_EASY_DEGREES", "property": "aim_cone_easy_degrees", "min": 0.0, "max": 180.0, "step": 5.0},
	{"key": "DEV_C_INPUT_BUFFER_SECONDS", "property": "input_buffer_seconds", "min": 0.0, "max": 0.4, "step": 0.01},
	{"key": "DEV_C_DUMMY_ATTACK_INTERVAL", "property": "dummy_attack_interval", "min": 0.3, "max": 6.0, "step": 0.05},
	{"key": "DEV_C_DUMMY_WINDUP", "property": "dummy_windup", "min": 0.1, "max": 2.0, "step": 0.05},
	{"key": "DEV_C_DUMMY_ACTIVE", "property": "dummy_active", "min": 0.02, "max": 0.5, "step": 0.01},
	{"key": "DEV_C_DUMMY_EXPOSED", "property": "dummy_exposed", "min": 0.0, "max": 2.0, "step": 0.05},
	{"key": "DEV_C_DUMMY_DAMAGE", "property": "dummy_damage", "min": 0.0, "max": 50.0, "step": 1.0},
	{"key": "DEV_C_DUMMY_REACH", "property": "dummy_reach", "min": 1.0, "max": 4.0, "step": 0.05},
	{"key": "DEV_C_ENEA_SPEED", "property": "enea_speed", "min": 1.0, "max": 6.0, "step": 0.1},
	{"key": "DEV_C_ENEA_FOLLOW_DISTANCE", "property": "enea_follow_distance", "min": 0.5, "max": 5.0, "step": 0.1},
	{"key": "DEV_C_ENEA_KEEP_BACK", "property": "enea_keep_back", "min": 0.0, "max": 8.0, "step": 0.1},
	{"key": "DEV_C_ENEA_LEARN_COUNT", "property": "enea_learn_count", "min": 1.0, "max": 10.0, "step": 1.0},
	{"key": "DEV_C_ENEA_DOWN_SECONDS", "property": "enea_down_seconds", "min": 0.2, "max": 5.0, "step": 0.1},
	{"key": "DEV_C_ENEA_PARRY_CHANCE", "property": "enea_parry_chance", "min": 0.0, "max": 1.0, "step": 0.05},
	{"key": "DEV_C_ENEA_ATTACK_DAMAGE", "property": "enea_attack_damage", "min": 0.0, "max": 30.0, "step": 1.0},
	{"key": "DEV_C_ENEA_ATTACK_INTERVAL", "property": "enea_attack_interval", "min": 0.2, "max": 4.0, "step": 0.05},
	{"key": "DEV_C_TOSCA_COOLDOWN", "property": "tosca_cooldown", "min": 1.0, "max": 40.0, "step": 0.5},
	{"key": "DEV_C_TOSCA_RANGE", "property": "tosca_range", "min": 2.0, "max": 15.0, "step": 0.5},
	{"key": "DEV_C_TOSCA_PULL_DISTANCE", "property": "tosca_pull_distance", "min": 0.5, "max": 4.0, "step": 0.1},
	{"key": "DEV_C_TOSCA_DAMAGE", "property": "tosca_damage", "min": 0.0, "max": 40.0, "step": 1.0},
	{"key": "DEV_C_TOSCA_HEAVY_STAGGER", "property": "tosca_heavy_stagger", "min": 0.0, "max": 4.0, "step": 0.1},
]
## Chapter values (Truce, turning terraces), bound to ChapterTuning.
const CHAPTER_SLIDERS: Array[Dictionary] = [
	{"key": "DEV_H_TRUCE_SECONDS", "property": "truce_seconds", "min": 30.0, "max": 900.0, "step": 10.0},
	{"key": "DEV_H_TRUCE_WARNING_SECONDS", "property": "truce_warning_seconds", "min": 5.0, "max": 180.0, "step": 5.0},
	{"key": "DEV_H_TRUCE_WARM_STONES", "property": "truce_warm_stones", "min": 0.0, "max": 6.0, "step": 1.0},
	{"key": "DEV_H_PLATFORM_TURN_SECONDS", "property": "platform_turn_seconds", "min": 0.3, "max": 4.0, "step": 0.05},
]
## Creature values (36), bound to CreatureTuning.
const CREATURE_SLIDERS: Array[Dictionary] = [
	{"key": "DEV_K_LEASH_DISTANCE", "property": "leash_distance", "min": 4.0, "max": 30.0, "step": 0.5},
	{"key": "DEV_K_VOLTAFACCIA_HITS", "property": "voltafaccia_hits", "min": 0.5, "max": 20.0, "step": 0.5},
	{"key": "DEV_K_VOLTAFACCIA_SPEED", "property": "voltafaccia_speed", "min": 0.5, "max": 6.0, "step": 0.1},
	{"key": "DEV_K_VOLTAFACCIA_AGGRO", "property": "voltafaccia_aggro", "min": 2.0, "max": 15.0, "step": 0.5},
	{"key": "DEV_K_VOLTAFACCIA_ATTACK_RANGE", "property": "voltafaccia_attack_range", "min": 0.5, "max": 3.0, "step": 0.05},
	{"key": "DEV_K_VOLTAFACCIA_WINDUP", "property": "voltafaccia_windup", "min": 0.1, "max": 1.5, "step": 0.05},
	{"key": "DEV_K_VOLTAFACCIA_EXPOSED", "property": "voltafaccia_exposed", "min": 0.0, "max": 2.0, "step": 0.05},
	{"key": "DEV_K_VOLTAFACCIA_COOLDOWN", "property": "voltafaccia_cooldown", "min": 0.0, "max": 4.0, "step": 0.05},
	{"key": "DEV_K_VOLTAFACCIA_DAMAGE", "property": "voltafaccia_damage", "min": 0.0, "max": 40.0, "step": 1.0},
	{"key": "DEV_K_VOLTAFACCIA_LUNGE", "property": "voltafaccia_lunge", "min": 0.0, "max": 2.0, "step": 0.05},
	{"key": "DEV_K_VOLTAFACCIA_SHADE_MULTIPLIER", "property": "voltafaccia_shade_multiplier", "min": 1.0, "max": 4.0, "step": 0.05},
	{"key": "DEV_K_VOLTAFACCIA_SHADE_DEGREES", "property": "voltafaccia_shade_degrees", "min": 15.0, "max": 90.0, "step": 1.0},
	{"key": "DEV_K_RASPAGELO_HITS", "property": "raspagelo_hits", "min": 0.5, "max": 20.0, "step": 0.5},
	{"key": "DEV_K_RASPAGELO_BURROW_SPEED", "property": "raspagelo_burrow_speed", "min": 0.5, "max": 8.0, "step": 0.1},
	{"key": "DEV_K_RASPAGELO_AGGRO", "property": "raspagelo_aggro", "min": 2.0, "max": 15.0, "step": 0.5},
	{"key": "DEV_K_RASPAGELO_TELEGRAPH", "property": "raspagelo_telegraph", "min": 0.1, "max": 2.0, "step": 0.05},
	{"key": "DEV_K_RASPAGELO_DAMAGE", "property": "raspagelo_damage", "min": 0.0, "max": 40.0, "step": 1.0},
	{"key": "DEV_K_RASPAGELO_BURST_RADIUS", "property": "raspagelo_burst_radius", "min": 0.3, "max": 3.0, "step": 0.05},
	{"key": "DEV_K_RASPAGELO_EXPOSED", "property": "raspagelo_exposed", "min": 0.0, "max": 2.0, "step": 0.05},
	{"key": "DEV_K_RASPAGELO_SURFACED", "property": "raspagelo_surfaced", "min": 0.0, "max": 3.0, "step": 0.05},
	{"key": "DEV_K_RASPAGELO_UNDERGROUND_MIN", "property": "raspagelo_underground_min", "min": 0.0, "max": 4.0, "step": 0.05},
	{"key": "DEV_K_RASPAGELO_ARMOR_MULTIPLIER", "property": "raspagelo_armor_multiplier", "min": 0.0, "max": 1.0, "step": 0.05},
	{"key": "DEV_K_DAY_BEAST_FLANK_SECONDS", "property": "day_beast_flank_seconds", "min": 0.2, "max": 6.0, "step": 0.1},
	{"key": "DEV_K_RASPAGELO_HOOKED_STUN", "property": "raspagelo_hooked_stun", "min": 0.0, "max": 4.0, "step": 0.1},
	{"key": "DEV_K_COCCIO_HITS", "property": "coccio_hits", "min": 0.5, "max": 20.0, "step": 0.5},
	{"key": "DEV_K_COCCIO_SPEED", "property": "coccio_speed", "min": 0.1, "max": 4.0, "step": 0.1},
	{"key": "DEV_K_COCCIO_AGGRO", "property": "coccio_aggro", "min": 1.0, "max": 15.0, "step": 0.5},
	{"key": "DEV_K_COCCIO_ATTACK_RANGE", "property": "coccio_attack_range", "min": 0.3, "max": 3.0, "step": 0.05},
	{"key": "DEV_K_COCCIO_WINDUP", "property": "coccio_windup", "min": 0.1, "max": 2.0, "step": 0.05},
	{"key": "DEV_K_COCCIO_DAMAGE", "property": "coccio_damage", "min": 0.0, "max": 40.0, "step": 1.0},
	{"key": "DEV_K_COCCIO_COOLDOWN", "property": "coccio_cooldown", "min": 0.0, "max": 5.0, "step": 0.05},
	{"key": "DEV_K_FRINITORE_HITS", "property": "frinitore_hits", "min": 0.5, "max": 20.0, "step": 0.5},
	{"key": "DEV_K_FRINITORE_DIAMETER", "property": "frinitore_diameter", "min": 0.5, "max": 4.0, "step": 0.05},
	{"key": "DEV_K_FRINITORE_DAMAGE_PER_SECOND", "property": "frinitore_damage_per_second", "min": 0.0, "max": 20.0, "step": 0.5},
	{"key": "DEV_K_FRINITORE_SPEED", "property": "frinitore_speed", "min": 0.0, "max": 4.0, "step": 0.1},
	{"key": "DEV_K_FRINITORE_AGGRO", "property": "frinitore_aggro", "min": 1.0, "max": 15.0, "step": 0.5},
	{"key": "DEV_K_SPECCHIETTO_HITS", "property": "specchietto_hits", "min": 0.5, "max": 10.0, "step": 0.5},
	{"key": "DEV_K_SPECCHIETTO_RANGE", "property": "specchietto_range", "min": 1.0, "max": 20.0, "step": 0.5},
	{"key": "DEV_K_SPECCHIETTO_WINDUP", "property": "specchietto_windup", "min": 0.1, "max": 2.0, "step": 0.05},
	{"key": "DEV_K_SPECCHIETTO_DAZZLE_SECONDS", "property": "specchietto_dazzle_seconds", "min": 0.1, "max": 4.0, "step": 0.05},
	{"key": "DEV_K_SPECCHIETTO_DAZZLE_SPEED", "property": "specchietto_dazzle_speed", "min": 0.1, "max": 1.0, "step": 0.05},
	{"key": "DEV_K_SPECCHIETTO_COOLDOWN", "property": "specchietto_cooldown", "min": 0.0, "max": 8.0, "step": 0.1},
	{"key": "DEV_K_FOGLIONE_HITS", "property": "foglione_hits", "min": 0.5, "max": 30.0, "step": 0.5},
	{"key": "DEV_K_FOGLIONE_WINDUP", "property": "foglione_windup", "min": 0.1, "max": 2.0, "step": 0.05},
	{"key": "DEV_K_FOGLIONE_DAMAGE", "property": "foglione_damage", "min": 0.0, "max": 40.0, "step": 1.0},
	{"key": "DEV_K_FOGLIONE_RANGE", "property": "foglione_range", "min": 0.5, "max": 5.0, "step": 0.05},
	{"key": "DEV_K_FOGLIONE_FRONT_DEGREES", "property": "foglione_front_degrees", "min": 10.0, "max": 120.0, "step": 1.0},
	{"key": "DEV_K_FOGLIONE_FLANK_MULTIPLIER", "property": "foglione_flank_multiplier", "min": 1.0, "max": 4.0, "step": 0.05},
	{"key": "DEV_K_FOGLIONE_COOLDOWN", "property": "foglione_cooldown", "min": 0.0, "max": 5.0, "step": 0.05},
	{"key": "DEV_K_FOGLIONE_DISTURB_DISTANCE", "property": "foglione_disturb_distance", "min": 0.3, "max": 5.0, "step": 0.1},
	{"key": "DEV_K_FOGLIONE_CALM_SECONDS", "property": "foglione_calm_seconds", "min": 1.0, "max": 30.0, "step": 0.5},
	{"key": "DEV_K_PELLEGRINO_FELT_HITS", "property": "pellegrino_felt_hits", "min": 0.5, "max": 20.0, "step": 0.5},
	{"key": "DEV_K_PELLEGRINO_BODY_HITS", "property": "pellegrino_body_hits", "min": 0.5, "max": 20.0, "step": 0.5},
	{"key": "DEV_K_PELLEGRINO_WINDUP", "property": "pellegrino_windup", "min": 0.1, "max": 2.0, "step": 0.05},
	{"key": "DEV_K_PELLEGRINO_DAMAGE", "property": "pellegrino_damage", "min": 0.0, "max": 60.0, "step": 1.0},
	{"key": "DEV_K_PELLEGRINO_RANGE", "property": "pellegrino_range", "min": 0.5, "max": 5.0, "step": 0.05},
	{"key": "DEV_K_PELLEGRINO_SPEED", "property": "pellegrino_speed", "min": 0.1, "max": 4.0, "step": 0.1},
	{"key": "DEV_K_PELLEGRINO_COOLDOWN", "property": "pellegrino_cooldown", "min": 0.0, "max": 6.0, "step": 0.1},
	{"key": "DEV_K_BRINACCHIO_HEALTH", "property": "brinacchio_health", "min": 1.0, "max": 60.0, "step": 1.0},
	{"key": "DEV_K_BRINACCHIO_SPEED", "property": "brinacchio_speed", "min": 0.5, "max": 8.0, "step": 0.1},
	{"key": "DEV_K_BRINACCHIO_AGGRO", "property": "brinacchio_aggro", "min": 1.0, "max": 15.0, "step": 0.5},
	{"key": "DEV_K_BRINACCHIO_LANTERN_AGGRO", "property": "brinacchio_lantern_aggro", "min": 1.0, "max": 25.0, "step": 0.5},
	{"key": "DEV_K_BRINACCHIO_LOSE_TRACK", "property": "brinacchio_lose_track", "min": 0.5, "max": 10.0, "step": 0.1},
	{"key": "DEV_K_BRINACCHIO_LATCH_DAMAGE_PER_SECOND", "property": "brinacchio_latch_damage_per_second", "min": 0.0, "max": 20.0, "step": 0.5},
	{"key": "DEV_K_BRINACCHIO_SLOW", "property": "brinacchio_slow", "min": 0.0, "max": 0.5, "step": 0.01},
	{"key": "DEV_K_BRINACCHIO_MAX_SLOW", "property": "brinacchio_max_slow", "min": 0.0, "max": 1.0, "step": 0.05},
	{"key": "DEV_K_BRINACCHIO_CRUST_SECONDS", "property": "brinacchio_crust_seconds", "min": 0.0, "max": 10.0, "step": 0.25},
	{"key": "DEV_K_GRAPPOLO_MEMBERS", "property": "grappolo_members", "min": 1.0, "max": 12.0, "step": 1.0},
	{"key": "DEV_K_GRAPPOLO_MEMBER_HEALTH", "property": "grappolo_member_health", "min": 1.0, "max": 40.0, "step": 1.0},
	{"key": "DEV_K_GRAPPOLO_AGGRO", "property": "grappolo_aggro", "min": 2.0, "max": 15.0, "step": 0.5},
	{"key": "DEV_K_GRAPPOLO_ROLL_WINDUP", "property": "grappolo_roll_windup", "min": 0.1, "max": 2.0, "step": 0.05},
	{"key": "DEV_K_GRAPPOLO_ROLL_SPEED", "property": "grappolo_roll_speed", "min": 1.0, "max": 15.0, "step": 0.5},
	{"key": "DEV_K_GRAPPOLO_ROLL_SECONDS", "property": "grappolo_roll_seconds", "min": 0.2, "max": 3.0, "step": 0.05},
	{"key": "DEV_K_GRAPPOLO_ROLL_COOLDOWN", "property": "grappolo_roll_cooldown", "min": 0.0, "max": 5.0, "step": 0.05},
	{"key": "DEV_K_GRAPPOLO_DAMAGE", "property": "grappolo_damage", "min": 0.0, "max": 40.0, "step": 1.0},
	{"key": "DEV_K_GRAPPOLO_SHELL_MULTIPLIER", "property": "grappolo_shell_multiplier", "min": 0.0, "max": 1.0, "step": 0.05},
	{"key": "DEV_K_GRAPPOLO_REFORM_SECONDS", "property": "grappolo_reform_seconds", "min": 0.5, "max": 10.0, "step": 0.25},
	{"key": "DEV_K_GRAPPOLO_BIT_SPEED", "property": "grappolo_bit_speed", "min": 0.2, "max": 5.0, "step": 0.1},
	{"key": "DEV_K_FOGLIONE_HEALTH", "property": "foglione_health", "min": 50.0, "max": 800.0, "step": 10.0},
	{"key": "DEV_K_FOGLIONE_TURN_DEGREES_PER_SECOND", "property": "foglione_turn_degrees_per_second", "min": 5.0, "max": 180.0, "step": 1.0},
	{"key": "DEV_K_FOGLIONE_LEAF_MULTIPLIER", "property": "foglione_leaf_multiplier", "min": 0.0, "max": 1.0, "step": 0.05},
	{"key": "DEV_K_FOGLIONE_LEAF_DEGREES", "property": "foglione_leaf_degrees", "min": 30.0, "max": 170.0, "step": 1.0},
	{"key": "DEV_K_FOGLIONE_ROOT_INTERVAL", "property": "foglione_root_interval", "min": 0.5, "max": 8.0, "step": 0.1},
	{"key": "DEV_K_FOGLIONE_ROOT_TELEGRAPH", "property": "foglione_root_telegraph", "min": 0.2, "max": 2.0, "step": 0.05},
	{"key": "DEV_K_FOGLIONE_ROOT_DAMAGE", "property": "foglione_root_damage", "min": 0.0, "max": 40.0, "step": 1.0},
	{"key": "DEV_K_FOGLIONE_ROOT_RADIUS", "property": "foglione_root_radius", "min": 0.5, "max": 3.0, "step": 0.05},
	{"key": "DEV_K_FOGLIONE_SWEEP_RANGE", "property": "foglione_sweep_range", "min": 1.0, "max": 6.0, "step": 0.1},
	{"key": "DEV_K_FOGLIONE_SWEEP_WINDUP", "property": "foglione_sweep_windup", "min": 0.2, "max": 2.0, "step": 0.05},
	{"key": "DEV_K_FOGLIONE_SWEEP_DAMAGE", "property": "foglione_sweep_damage", "min": 0.0, "max": 40.0, "step": 1.0},
	{"key": "DEV_K_FOGLIONE_CLOSE_AFTER_DAMAGE", "property": "foglione_close_after_damage", "min": 10.0, "max": 200.0, "step": 5.0},
	{"key": "DEV_K_FOGLIONE_CLOSE_SECONDS", "property": "foglione_close_seconds", "min": 0.0, "max": 6.0, "step": 0.1},
	{"key": "DEV_K_FIELD_TILT_SECONDS", "property": "field_tilt_seconds", "min": 2.0, "max": 20.0, "step": 0.5},
	{"key": "DEV_K_FIELD_LEVER_COOLDOWN", "property": "field_lever_cooldown", "min": 2.0, "max": 30.0, "step": 0.5},
	{"key": "DEV_K_SPARTI_HEALTH", "property": "sparti_health", "min": 50.0, "max": 900.0, "step": 10.0},
	{"key": "DEV_K_SPARTI_AIM_SECONDS", "property": "sparti_aim_seconds", "min": 0.3, "max": 3.0, "step": 0.05},
	{"key": "DEV_K_SPARTI_CHARGE_SPEED", "property": "sparti_charge_speed", "min": 2.0, "max": 20.0, "step": 0.5},
	{"key": "DEV_K_SPARTI_CHARGE_DAMAGE", "property": "sparti_charge_damage", "min": 0.0, "max": 60.0, "step": 1.0},
	{"key": "DEV_K_SPARTI_RECOVER_SECONDS", "property": "sparti_recover_seconds", "min": 0.0, "max": 5.0, "step": 0.05},
	{"key": "DEV_K_SPARTI_STUCK_SECONDS", "property": "sparti_stuck_seconds", "min": 0.0, "max": 8.0, "step": 0.1},
	{"key": "DEV_K_SPARTI_SHIELD_MULTIPLIER", "property": "sparti_shield_multiplier", "min": 0.0, "max": 1.0, "step": 0.05},
	{"key": "DEV_K_SPARTI_SHIELD_DEGREES", "property": "sparti_shield_degrees", "min": 20.0, "max": 120.0, "step": 1.0},
	{"key": "DEV_K_SPARTI_STOMP_RANGE", "property": "sparti_stomp_range", "min": 0.5, "max": 5.0, "step": 0.1},
	{"key": "DEV_K_SPARTI_STOMP_DAMAGE", "property": "sparti_stomp_damage", "min": 0.0, "max": 40.0, "step": 1.0},
	{"key": "DEV_K_ICE_FALL_DAMAGE", "property": "ice_fall_damage", "min": 0.0, "max": 50.0, "step": 1.0},
]
const PANEL_WIDTH: float = 380.0

var settings: ProtoSettings

var _root: PanelContainer
var combat_tuning: CombatTuning
var creature_tuning: CreatureTuning
var chapter_tuning: ChapterTuning
var _fps_label: Label
var _status_label: Label


func _init(target_settings: ProtoSettings, target_combat: CombatTuning = null, target_creatures: CreatureTuning = null, target_chapter: ChapterTuning = null) -> void:
	settings = target_settings
	combat_tuning = target_combat
	creature_tuning = target_creatures
	chapter_tuning = target_chapter
	layer = 10


func _ready() -> void:
	_build()
	_root.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"toggle_tuning_panel"):
		_root.visible = not _root.visible
		get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	if _root.visible:
		_fps_label.text = tr(&"DEV_FPS").format({"fps": Engine.get_frames_per_second()})


func set_panel_visible(value: bool) -> void:
	_root.visible = value


func is_panel_visible() -> bool:
	return _root.visible


func show_saved(file_name: String) -> void:
	_status_label.text = tr(&"DEV_SAVED").format({"file": file_name})


func _build() -> void:
	_root = PanelContainer.new()
	_root.anchor_bottom = 1.0
	_root.custom_minimum_size = Vector2(PANEL_WIDTH, 0.0)
	add_child(_root)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_root.add_child(scroll)
	var box: VBoxContainer = VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(box)

	var title: Label = Label.new()
	title.text = "DEV_PANEL_TITLE"
	box.add_child(title)
	_fps_label = Label.new()
	_fps_label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	box.add_child(_fps_label)

	for definition: Dictionary in SLIDERS:
		_add_slider(box, definition, settings)
	for definition: Dictionary in TOGGLES:
		_add_toggle(box, definition)
	_add_color(box, "DEV_SUN_COLOR", "sun_color")

	var save_button: Button = Button.new()
	save_button.text = "DEV_SAVE"
	save_button.pressed.connect(func() -> void: save_requested.emit())
	box.add_child(save_button)
	_status_label = Label.new()
	_status_label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_status_label)

	var end_chapter: Button = Button.new()
	end_chapter.text = "DEV_END_CHAPTER"
	end_chapter.pressed.connect(func() -> void: end_chapter_requested.emit())
	box.add_child(end_chapter)
	var truce: Button = Button.new()
	truce.text = "DEV_START_TRUCE"
	truce.pressed.connect(func() -> void: truce_requested.emit())
	box.add_child(truce)
	var yard: Button = Button.new()
	yard.text = "DEV_GO_TO_YARD"
	yard.pressed.connect(func() -> void: yard_requested.emit())
	box.add_child(yard)
	var coat: Label = Label.new()
	coat.text = "DEV_SECTION_COAT"
	box.add_child(coat)
	for slot: int in CoatPatches.SLOTS:
		_add_patch_slot(box, "patch_slot_%d" % (slot + 1))

	if combat_tuning != null:
		var section: Label = Label.new()
		section.text = "DEV_SECTION_COMBAT"
		box.add_child(HSeparator.new())
		box.add_child(section)
		for definition: Dictionary in COMBAT_SLIDERS:
			_add_slider(box, definition, combat_tuning)
		var combat_save: Button = Button.new()
		combat_save.text = "DEV_SAVE_COMBAT"
		combat_save.pressed.connect(func() -> void: combat_save_requested.emit())
		box.add_child(combat_save)
	if creature_tuning != null:
		var creatures: Label = Label.new()
		creatures.text = "DEV_SECTION_CREATURES"
		box.add_child(HSeparator.new())
		box.add_child(creatures)
		for definition: Dictionary in CREATURE_SLIDERS:
			_add_slider(box, definition, creature_tuning)
		var creatures_save: Button = Button.new()
		creatures_save.text = "DEV_SAVE_CREATURES"
		creatures_save.pressed.connect(func() -> void: creatures_save_requested.emit())
		box.add_child(creatures_save)
	if chapter_tuning != null:
		var chapter_label: Label = Label.new()
		chapter_label.text = "DEV_SECTION_CHAPTER"
		box.add_child(HSeparator.new())
		box.add_child(chapter_label)
		for definition: Dictionary in CHAPTER_SLIDERS:
			_add_slider(box, definition, chapter_tuning)
		var chapter_save: Button = Button.new()
		chapter_save.text = "DEV_SAVE_CHAPTER"
		chapter_save.pressed.connect(func() -> void: chapter_save_requested.emit())
		box.add_child(chapter_save)


func _add_slider(box: VBoxContainer, definition: Dictionary, target: Object) -> void:
	var property: String = definition["property"]
	var header: HBoxContainer = HBoxContainer.new()
	var label: Label = Label.new()
	label.text = definition["key"]
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(label)
	var value_label: Label = Label.new()
	value_label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	header.add_child(value_label)
	box.add_child(header)
	var slider: HSlider = HSlider.new()
	slider.min_value = definition["min"]
	slider.max_value = definition["max"]
	slider.step = definition["step"]
	slider.value = float(target.get(property))
	value_label.text = _format_value(slider.value, slider.step)
	slider.value_changed.connect(func(value: float) -> void:
		if target.get(property) is int:
			target.set(property, roundi(value))
		else:
			target.set(property, value)
		value_label.text = _format_value(value, slider.step)
		settings_changed.emit())
	box.add_child(slider)


## One coat slot (104): empty or one of the patches of the item catalog.
## Picking one here also counts it as found.
func _add_patch_slot(box: VBoxContainer, property: String) -> void:
	var picker: OptionButton = OptionButton.new()
	var options: Array[StringName] = [GameState.EMPTY_SLOT]
	picker.add_item("PATCH_NONE")
	for item: ItemDefinition in CoatPatches.all_patches():
		options.append(item.id)
		picker.add_item(item.name_key)
	picker.selected = maxi(0, options.find(StringName(settings.get(property))))
	picker.item_selected.connect(func(index: int) -> void:
		settings.set(property, String(options[index]))
		settings_changed.emit())
	box.add_child(picker)


func _add_toggle(box: VBoxContainer, definition: Dictionary) -> void:
	var property: String = definition["property"]
	var check: CheckBox = CheckBox.new()
	check.text = definition["key"]
	check.button_pressed = bool(settings.get(property))
	check.toggled.connect(func(pressed: bool) -> void:
		settings.set(property, pressed)
		settings_changed.emit())
	box.add_child(check)


func _add_color(box: VBoxContainer, key: String, property: String) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	var label: Label = Label.new()
	label.text = key
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	var picker: ColorPickerButton = ColorPickerButton.new()
	picker.custom_minimum_size = Vector2(64.0, 0.0)
	picker.edit_alpha = false
	picker.color = settings.get(property)
	picker.color_changed.connect(func(color: Color) -> void:
		settings.set(property, color)
		settings_changed.emit())
	row.add_child(picker)
	box.add_child(row)


func _format_value(value: float, step: float) -> String:
	if step >= 1.0:
		return "%d" % roundi(value)
	if step >= 0.1:
		return "%.1f" % value
	if step >= 0.01:
		return "%.2f" % value
	if step >= 0.001:
		return "%.3f" % value
	return "%.4f" % value
