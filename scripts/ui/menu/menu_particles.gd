extends Control
var elapsed := 0.0
var leaves: Array[Dictionary] = []
func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	var random := RandomNumberGenerator.new()
	random.seed = 18372
	for index in 22:
		leaves.append({"x": random.randf(), "y": random.randf(), "speed": random.randf_range(13, 30), "phase": random.randf() * TAU, "leaf": index % 3 == 0})
func _process(delta: float) -> void:
	if not is_visible_in_tree(): return
	elapsed += delta
	queue_redraw()
func _draw() -> void:
	for mote in leaves:
		var point := Vector2(fposmod(float(mote.x) * size.x + sin(elapsed * 0.4 + float(mote.phase)) * 25, maxf(1, size.x)), fposmod(float(mote.y) * size.y + elapsed * float(mote.speed), maxf(1, size.y)))
		var color := Color("#b5bb7d", 0.38) if mote.leaf else Color("#e5bd72", 0.28 + sin(elapsed + float(mote.phase)) * 0.12)
		if mote.leaf:
			draw_set_transform(point, sin(elapsed + float(mote.phase)) * 0.7)
			draw_colored_polygon(PackedVector2Array([Vector2(-5, 0), Vector2(0, -2), Vector2(6, 0), Vector2(0, 3)]), color)
			draw_line(Vector2(-4, 0), Vector2(5, 0), Color("#d7c392", 0.35), 0.6, true)
			draw_set_transform(Vector2.ZERO)
		else:
			draw_circle(point, 1.2, color)
