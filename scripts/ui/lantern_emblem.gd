class_name LanternEmblem
extends Control
## The farewell lantern (88), drawn in ten pieces, one for each dungeon
## (the ten of 06-dungeon): ring, cap, two cage sides, four glass panes,
## base and wick. The outline is always there; the pieces Anselmo has
## already made are filled in. It is the progress bar of the game (125).

const PIECES: int = 10
const LINE: Color = Color(0.93, 0.8, 0.52)
const FILL: Color = Color(0.86, 0.6, 0.3)
const GLASS: Color = Color(1.0, 0.86, 0.55)
const SIZE: Vector2 = Vector2(120.0, 200.0)
const WIDTH: float = 4.0

## How many pieces are made (0 = the empty silhouette).
var pieces: int = 0:
	set(value):
		pieces = clampi(value, 0, PIECES)
		queue_redraw()


func _init() -> void:
	custom_minimum_size = SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var shapes: Array[PackedVector2Array] = piece_shapes()
	for index: int in shapes.size():
		if index < pieces:
			draw_colored_polygon(shapes[index], GLASS if index >= 4 and index < 8 else FILL)
	for shape: PackedVector2Array in shapes:
		var closed: PackedVector2Array = shape.duplicate()
		closed.append(shape[0])
		draw_polyline(closed, LINE, WIDTH, false)


## The ten pieces as polygons, in the order they are made.
static func piece_shapes() -> Array[PackedVector2Array]:
	var shapes: Array[PackedVector2Array] = []
	# 1 ring, 2 cap.
	var ring: PackedVector2Array = []
	for index: int in 9:
		var angle: float = PI + PI * index / 8.0
		ring.append(Vector2(60.0, 22.0) + Vector2(cos(angle), sin(angle)) * 12.0)
	ring.append(Vector2(66.0, 22.0))
	ring.append(Vector2(54.0, 22.0))
	shapes.append(ring)
	shapes.append(PackedVector2Array([Vector2(36.0, 52.0), Vector2(48.0, 30.0), Vector2(72.0, 30.0), Vector2(84.0, 52.0)]))
	# 3, 4: the cage sides.
	shapes.append(PackedVector2Array([Vector2(30.0, 52.0), Vector2(36.0, 52.0), Vector2(36.0, 152.0), Vector2(30.0, 152.0)]))
	shapes.append(PackedVector2Array([Vector2(84.0, 52.0), Vector2(90.0, 52.0), Vector2(90.0, 152.0), Vector2(84.0, 152.0)]))
	# 5-8: four glass panes, two by two.
	for row: int in 2:
		for column: int in 2:
			var x: float = 38.0 + column * 23.0
			var y: float = 56.0 + row * 48.0
			shapes.append(PackedVector2Array([Vector2(x, y), Vector2(x + 21.0, y), Vector2(x + 21.0, y + 44.0), Vector2(x, y + 44.0)]))
	# 9 base, 10 the wick and flame holder in the middle.
	shapes.append(PackedVector2Array([Vector2(28.0, 154.0), Vector2(92.0, 154.0), Vector2(84.0, 172.0), Vector2(36.0, 172.0)]))
	shapes.append(PackedVector2Array([Vector2(56.0, 124.0), Vector2(64.0, 124.0), Vector2(66.0, 150.0), Vector2(54.0, 150.0)]))
	return shapes
