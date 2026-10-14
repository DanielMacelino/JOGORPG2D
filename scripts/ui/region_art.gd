extends Control
## Small field illustrations used by the expedition atlas.
var region_theme: StringName = &"forest"
var accent := Color("#91ad8a")

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE

func _draw() -> void:
	var unit := minf(size.x / 120.0, size.y / 100.0)
	draw_set_transform((size - Vector2(120, 100) * unit) * 0.5, 0, Vector2.ONE * unit)
	draw_circle(Vector2(61, 49), 44, accent.darkened(0.77))
	draw_arc(Vector2(61, 49), 44, 0, TAU, 56, Color(accent, 0.35), 1, true)
	draw_line(Vector2(22, 80), Vector2(100, 80), accent.darkened(0.32), 1, true)
	match region_theme:
		&"graveyard":
			for i in 3:
				var p := Vector2(35 + i * 24, 75 - i % 2 * 5)
				draw_style_box(_stone(), Rect2(p + Vector2(-8, -29), Vector2(16, 30)))
				draw_line(p + Vector2(0, -23), p + Vector2(0, -8), accent, 1.5)
				draw_line(p + Vector2(-4, -18), p + Vector2(4, -18), accent, 1.5)
		&"volcanic":
			draw_colored_polygon(PackedVector2Array([Vector2(21, 78), Vector2(49, 31), Vector2(72, 31), Vector2(102, 78)]), accent.darkened(0.43))
			draw_polyline(PackedVector2Array([Vector2(48, 31), Vector2(60, 41), Vector2(73, 31)]), Color("#e0b482"), 3, true)
			draw_polyline(PackedVector2Array([Vector2(61, 43), Vector2(55, 56), Vector2(69, 67), Vector2(67, 78)]), accent, 2.5, true)
		&"castle":
			for x in [33, 74]:
				draw_rect(Rect2(x, 38, 17, 41), accent.darkened(0.32))
				for k in 3:
					draw_rect(Rect2(x + k * 6, 32, 5, 9), accent.darkened(0.32))
				draw_rect(Rect2(x + 6, 48, 5, 10), accent.darkened(0.78))
			draw_rect(Rect2(50, 54, 24, 25), accent.darkened(0.50))
			draw_rect(Rect2(59, 65, 7, 14), accent.darkened(0.78))
		&"frost", &"snow", &"tundra", &"frozen":
			_tree(Vector2(42, 78), 45, accent)
			_tree(Vector2(78, 78), 59, accent.lightened(0.18))
			draw_line(Vector2(25, 80), Vector2(98, 80), accent.lightened(0.4), 3, true)
		&"swamp":
			_draw_pool(Vector2(60, 73), Vector2(37, 8), accent.darkened(0.40))
			for i in 4:
				var p := Vector2(33 + i * 18, 69 + i % 2 * 5)
				draw_line(p, p + Vector2(3, -35), accent, 2, true)
				draw_arc(p + Vector2(3, -35), 9, 0.2, 2.5, 12, accent, 2, true)
		_:
			_tree(Vector2(35, 78), 39, accent.darkened(0.20))
			_tree(Vector2(61, 78), 61, accent)
			_tree(Vector2(87, 78), 43, accent.darkened(0.10))
	draw_set_transform(Vector2.ZERO)

func _tree(base: Vector2, height: float, color: Color) -> void:
	draw_line(base, base - Vector2(0, height - 3), color.darkened(0.15), 3, true)
	for tier in 3:
		var top := base - Vector2(0, height - tier * 13)
		var half := 10.0 + tier * 5
		draw_colored_polygon(PackedVector2Array([top, top + Vector2(half, 25), top + Vector2(-half, 25)]), color.darkened(tier * 0.09))

func _stone() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = accent.darkened(0.40)
	box.corner_radius_top_left = 8
	box.corner_radius_top_right = 8
	return box

func _draw_pool(center: Vector2, extent: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in 32:
		points.append(center + Vector2(cos(TAU * i / 32.0), sin(TAU * i / 32.0)) * extent)
	draw_colored_polygon(points, color)
