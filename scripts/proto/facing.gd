class_name Facing
extends RefCounted
## Chooses the sprite view for a movement direction.
## Phase 1 prototype (19, 49): the test sheet has only the four cardinal views,
## so diagonals fall back to the nearest cardinal one.

enum Cardinal { SOUTH, EAST, NORTH, WEST }


## Returns the cardinal view for a screen-space input vector
## (x: right positive, y: down positive, as returned by Input.get_vector).
## On an exact diagonal the current view is kept when it matches one of the
## two components, so the sprite does not flicker; otherwise east/west wins.
static func nearest_cardinal(direction: Vector2, current: Cardinal) -> Cardinal:
	if direction.is_zero_approx():
		return current
	var horizontal: Cardinal = Cardinal.EAST if direction.x > 0.0 else Cardinal.WEST
	var vertical: Cardinal = Cardinal.SOUTH if direction.y > 0.0 else Cardinal.NORTH
	var ax: float = absf(direction.x)
	var ay: float = absf(direction.y)
	if is_equal_approx(ax, ay):
		if current == horizontal or current == vertical:
			return current
		return horizontal
	return horizontal if ax > ay else vertical
