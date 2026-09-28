class_name LanternProgress
extends RefCounted
## Where the farewell lantern stands (88): shown in the pause menu once the
## verdict has revealed it, with one piece per dungeon done.
## Kept in memory only, until there is a save system.

static var revealed: bool = false
static var pieces: int = 0
