class_name CoatPatches
extends RefCounted
## Coat patches (104): found during the Truce, sewn into three slots, each a
## small effect. The four test patches of phase 3; the final list is still
## to be defined (TODO-DESIGN #104), and so are temperatures and lantern
## fuel, so the cold, heat and lantern effects below are provisional.

const SLOTS: int = 3
const NONE: StringName = &""
## Order shown in the panel.
const ALL: Array[StringName] = [&"cold", &"heat", &"breath", &"lantern"]

## Cold: creatures of the Night side and the ice hurt less, clinging frost
## parasites slow less.
const COLD_DAMAGE_TAKEN: float = 0.8
const COLD_SLOW: float = 0.5
## Heat: beasts of the Day side hurt less.
const HEAT_DAMAGE_TAKEN: float = 0.8
## Breath regained faster.
const BREATH_REGEN: float = 1.2
## Lantern light reaches farther (stands for "lasts longer" until the
## lantern has fuel, TODO-DESIGN #104).
const LANTERN_RANGE: float = 1.25


static func label_key(patch: StringName) -> StringName:
	return StringName("PATCH_" + String(patch).to_upper()) if patch != NONE else &"PATCH_NONE"
