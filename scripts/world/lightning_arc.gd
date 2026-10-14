extends Node2D

var start_position := Vector2.ZERO
var end_position := Vector2.ZERO
var lifetime := 0.24
var elapsed := 0.0
var color := Color("#9ce3ff")
var rng := RandomNumberGenerator.new()
var shape_points: PackedVector2Array = []

func setup(from: Vector2, to: Vector2, arc_color: Color = Color("#9ce3ff")) -> void:
	start_position = from
	end_position = to
	global_position = from
	color = arc_color
	rng.randomize()
	_build_shape()

func _ready() -> void:
	if shape_points.is_empty():
		_build_shape()

func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()
	if elapsed >= lifetime:
		queue_free()

func _build_shape() -> void:
	shape_points.clear()
	var local_end := end_position - start_position
	var axis := local_end.normalized()
	var perpendicular := Vector2(-axis.y, axis.x)
	var segment_count := 7
	shape_points.append(Vector2.ZERO)
	for index in range(1, segment_count):
		var progress := float(index) / float(segment_count)
		var offset := rng.randf_range(-15.0, 15.0) * (1.0 - absf(0.5 - progress) * 0.7)
		shape_points.append(local_end * progress + perpendicular * offset)
	shape_points.append(local_end)

func _draw() -> void:
	if shape_points.size() < 2:
		return
	var fade := 1.0 - elapsed / lifetime
	var flicker := 0.78 + 0.22 * sin(elapsed * 93.0)
	for index in range(shape_points.size() - 1):
		var from := shape_points[index]
		var to := shape_points[index + 1]
		draw_line(from, to, Color(color, fade * flicker * 0.24), 9.0 * fade + 1.0, true)
		draw_line(from, to, Color("#effcff", fade * flicker), 2.6 * fade + 0.5, true)
	draw_circle(shape_points[-1], 5.5 * fade, Color(color, fade * 0.42))
