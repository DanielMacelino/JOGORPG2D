extends RefCounted
## Shared native emblems for tree selectors and graph nodes.
static func draw(canvas: CanvasItem, category: String, p: Vector2, r: float, color: Color, width: float = 1.5) -> void:
	match category:
		"fury":
			var points := PackedVector2Array([p + Vector2(0, -r), p + Vector2(r * 0.3, -r * 0.1), p + Vector2(r * 0.6, -r * 0.5), p + Vector2(r * 0.8, r * 0.4), p + Vector2(0, r), p + Vector2(-r * 0.7, r * 0.4), p + Vector2(-r * 0.5, -r * 0.3), p + Vector2(-r * 0.2, r * 0.1)])
			points.append(points[0])
			canvas.draw_polyline(points, color, width, true)
		"vigor":
			var points := PackedVector2Array()
			for i in 25:
				var t := float(i) * TAU / 24
				points.append(p + Vector2(16 * pow(sin(t), 3), -(13 * cos(t) - 5 * cos(2*t) - 2 * cos(3*t) - cos(4*t))) * r / 17)
			canvas.draw_polyline(points, color, width, true)
		"cunning":
			canvas.draw_polyline(PackedVector2Array([p + Vector2(-r, 0), p + Vector2(0, -r * 0.6), p + Vector2(r, 0), p + Vector2(0, r * 0.6), p + Vector2(-r, 0)]), color, width, true)
			canvas.draw_circle(p, r * 0.22, color)
		"survival":
			canvas.draw_polyline(PackedVector2Array([p + Vector2(0, -r), p + Vector2(r * 0.7, 0), p + Vector2(0, r), p + Vector2(-r * 0.7, 0), p + Vector2(0, -r)]), color, width, true)
			canvas.draw_line(p + Vector2(0, -r * 0.75), p + Vector2(0, r * 0.8), color, width, true)
			for side in [-1, 1]: canvas.draw_line(p + Vector2(side * r * 0.5, 0), p + Vector2(0, r * 0.35), color, width, true)
		"technique":
			var points := PackedVector2Array()
			for i in 7: points.append(p + Vector2.from_angle(i * TAU / 6 - PI / 2) * r)
			canvas.draw_polyline(points, color, width, true)
			canvas.draw_line(p - Vector2(r * 0.45, 0), p + Vector2(r * 0.45, 0), color, width, true)
			canvas.draw_line(p - Vector2(0, r * 0.45), p + Vector2(0, r * 0.45), color, width, true)
		_:
			for i in 4:
				var axis := Vector2.from_angle(i * PI / 2) * r
				canvas.draw_line(p - axis, p + axis, color, width, true)
			canvas.draw_arc(p, r * 0.65, 0, TAU, 24, color, width, true)
