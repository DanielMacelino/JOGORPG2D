extends Node2D

var radius := 70.0
var color := Color("#ffb765")
var lifetime := 0.26
var elapsed := 0.0

func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()
	if elapsed >= lifetime:
		queue_free()

func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE * 0.75)
	var progress := clampf(elapsed / maxf(lifetime, 0.001), 0.0, 1.0)
	draw_circle(Vector2.ZERO, radius * progress, Color(color, (1.0 - progress) * 0.14))
	draw_arc(Vector2.ZERO, radius * progress, 0.0, TAU, 36, Color(color, 1.0 - progress), 3.0 * (1.0 - progress) + 0.5, true)
