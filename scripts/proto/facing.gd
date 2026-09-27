class_name Facing
extends RefCounted
## Chooses the sprite view for a movement direction (19, 49).
## Views follow the row order of the Ottavia v1 sheet:
## south, south-east, east, north-east, north, north-west, west, south-west.

enum Direction { SOUTH, SOUTH_EAST, EAST, NORTH_EAST, NORTH, NORTH_WEST, WEST, SOUTH_WEST }

const DIRECTION_COUNT: int = 8


## Returns the nearest of the eight views for a screen-space input vector
## (x: right positive, y: down positive, as returned by Input.get_vector).
## No input keeps the current view.
static func nearest_direction(input: Vector2, current: Direction) -> Direction:
	if input.is_zero_approx():
		return current
	# atan2(x, y) is 0 for south and grows clockwise on screen: east is +90 degrees.
	var octant: int = roundi(atan2(input.x, input.y) / (TAU / DIRECTION_COUNT))
	return posmod(octant, DIRECTION_COUNT) as Direction
