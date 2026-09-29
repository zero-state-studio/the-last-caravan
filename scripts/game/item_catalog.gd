class_name ItemCatalog
extends Resource
## Every item of the game, in assets/items/item_catalog.tres: add one there,
## with its translation keys, and it can be placed in the world with a
## WorldPickup.

const PATH: String = "res://assets/items/item_catalog.tres"

@export var items: Array[ItemDefinition] = []

static var _main: ItemCatalog


static func main() -> ItemCatalog:
	if _main == null:
		_main = load(PATH) as ItemCatalog
	return _main


func find(item_id: StringName) -> ItemDefinition:
	for item: ItemDefinition in items:
		if item.id == item_id:
			return item
	return null


func of_kind(kind: ItemDefinition.Kind) -> Array[ItemDefinition]:
	var result: Array[ItemDefinition] = []
	for item: ItemDefinition in items:
		if item.kind == kind:
			result.append(item)
	return result
