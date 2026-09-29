class_name CoatPatches
extends RefCounted
## Coat patches (104): found in the world, sewn into three slots at the
## caravan (128), each a small effect. The patches and their amounts are in
## the item catalog (assets/items/item_catalog.tres); this file lists what
## each effect does. The full list of patches is still to be defined
## (TODO-DESIGN #104).

const SLOTS: int = GameState.COAT_SLOTS

## Cold: damage from creatures of the Night side and the slowing of clinging
## frost are multiplied by the amount (felt patch: 0.75, a quarter less).
const EFFECT_COLD: StringName = &"cold"
## Heat: damage from beasts of the Day side, multiplied by the amount.
const EFFECT_HEAT: StringName = &"heat"
## Breath regained faster: regeneration multiplied by the amount.
const EFFECT_BREATH_REGEN: StringName = &"breath_regen"
## Out of breath for less time: multiplied by the amount.
const EFFECT_BREATHLESS: StringName = &"breathless"
## The raised lantern (chapter 3) lasts longer (131): not used yet.
const EFFECT_LANTERN_RAISED: StringName = &"lantern_raised"


## Product of the amounts of `effect` among the `patches` worn (1: none).
static func multiplier(patches: Array[StringName], effect: StringName) -> float:
	var result: float = 1.0
	var catalog: ItemCatalog = ItemCatalog.main()
	for patch: StringName in patches:
		var item: ItemDefinition = catalog.find(patch)
		if item != null and item.effect == effect:
			result *= item.amount
	return result


static func all_patches() -> Array[ItemDefinition]:
	return ItemCatalog.main().of_kind(ItemDefinition.Kind.PATCH)
