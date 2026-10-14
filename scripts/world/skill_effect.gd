extends Node2D
## Cosmetic only: geometry never deals damage or changes an ability's range.
var kind := "arcane"
var radius := 110.0
var color := Color("#abebff")
var direction := Vector2.RIGHT
var elapsed := 0.0
var lifetime := 0.65

func _ready() -> void:
	z_index = 6
	add_to_group("skill_effect")

func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()
	if elapsed >= lifetime:
		queue_free()

func _draw() -> void:
	var progress := clampf(elapsed / maxf(0.001, lifetime), 0.0, 1.0)
	var alpha := sin(progress * PI) * 0.85
	var reach := radius * (0.20 + progress * 0.80)
	var ink := Color(color, alpha)
	var bright := Color(color.lightened(0.55), alpha)
	match kind:
		"frost":
			draw_arc(Vector2.ZERO, reach, 0, TAU, 48, ink, 2.0, true)
			for index in 10:
				var center := Vector2.from_angle(index * TAU / 10.0) * reach
				var scale_amount := 5.0 + sin(progress * PI) * 10.0
				var points := PackedVector2Array([center + Vector2(0, -scale_amount), center + Vector2(scale_amount * 0.4, 0), center + Vector2(0, scale_amount * 0.5), center + Vector2(-scale_amount * 0.4, 0)])
				draw_colored_polygon(points, Color(color, alpha * 0.50))
				draw_polyline(points + PackedVector2Array([points[0]]), bright, 1.1, true)
		"fire", "holy":
			draw_circle(Vector2.ZERO, reach, Color(color, alpha * 0.055))
			for index in 12:
				var angle := index * TAU / 12.0 + progress * 0.18
				var center := Vector2.from_angle(angle) * reach
				var flame := PackedVector2Array([center + Vector2(-5, 3), center + Vector2(-3, -6), center + Vector2(sin(index + progress * 12) * 5, -18 * (1.0 - progress) - 6), center + Vector2(6, 1)])
				draw_colored_polygon(flame, ink)
				draw_line(Vector2.from_angle(angle) * reach * 0.65, center, bright, 1.2, true)
			if kind == "holy":
				draw_line(Vector2(0, -reach * 0.65), Vector2(0, reach * 0.65), bright, 2.0, true)
				draw_line(Vector2(-reach * 0.4, 0), Vector2(reach * 0.4, 0), bright, 2.0, true)
		"roots", "summon":
			for index in 9:
				var angle := index * TAU / 9.0
				var root := PackedVector2Array([Vector2.from_angle(angle) * reach * 0.35, Vector2.from_angle(angle + 0.10) * reach * 0.7, Vector2.from_angle(angle - 0.04) * reach])
				draw_polyline(root, ink, 2.5, true)
				var leaf := root[2]
				draw_colored_polygon(PackedVector2Array([leaf, leaf + Vector2(7, -9), leaf + Vector2(9, -2)]), bright)
			if kind == "summon":
				draw_arc(Vector2.ZERO, reach * 0.8, elapsed, elapsed + TAU, 48, ink, 2.0, true)
		"blades", "shadow":
			for index in 4:
				var angle := index * PI / 2.0 + progress * TAU
				draw_arc(Vector2.ZERO, reach * (0.6 + index * 0.1), angle, angle + 1.0, 18, ink, 2.0 + (1.0 - progress) * 3.0, true)
		"arrows":
			draw_set_transform(Vector2.ZERO, direction.angle(), Vector2.ONE)
			for index in 5:
				var heading := Vector2.from_angle((index - 2) * 0.15)
				var tip := heading * reach
				draw_line(heading * reach * 0.55, tip, bright, 1.5, true)
				draw_line(tip, tip - heading.rotated(0.5) * 8.0, ink, 1.5, true)
				draw_line(tip, tip - heading.rotated(-0.5) * 8.0, ink, 1.5, true)
		"void", "time":
			for ring in 3:
				var phase := progress * TAU * (-1 if ring % 2 else 1)
				draw_arc(Vector2.ZERO, reach * (0.4 + ring * 0.27), phase, phase + PI * 1.5, 40, ink, 2, true)
			for index in 8:
				var point := Vector2.from_angle(index * TAU / 8.0 + progress * PI) * reach
				draw_circle(point, 2.0, bright)
		"taunt":
			for index in 3:
				var weight := fmod(progress + index / 3.0, 1.0)
				draw_arc(Vector2.ZERO, radius * weight, 0, TAU, 48, Color(color, (1.0 - weight) * alpha), 2, true)
		"starfall":
			var tip := Vector2(0, -radius * (1.0 - progress))
			draw_line(tip + Vector2(30, -65), tip, Color(color, alpha * 0.25), 9, true)
			draw_line(tip + Vector2(25, -60), tip, bright, 2.5, true)
			draw_circle(tip, 6.0, ink)
		_:
			draw_arc(Vector2.ZERO, reach, elapsed, elapsed + TAU, 48, ink, 1.7, true)
			for index in 6:
				var angle := index * TAU / 6.0 + progress * 1.2
				var center := Vector2.from_angle(angle) * reach
				draw_line(center - Vector2(3, 0), center + Vector2(3, 0), bright, 1.5, true)
				draw_line(center - Vector2(0, 3), center + Vector2(0, 3), bright, 1.5, true)
