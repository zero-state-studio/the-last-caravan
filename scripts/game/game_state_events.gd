class_name GameStateEvents
extends RefCounted
## Signals of GameState, which is all static: the interface listens here.

signal changed
signal item_received(item_id: StringName)
signal knot_added(count: int)
signal patches_changed
