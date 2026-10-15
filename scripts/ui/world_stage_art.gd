extends RefCounted
## Small atlas landmarks drawn at native UI resolution, with no baked-in text.
const GOLD := Color("#dfca8c")
const GREEN := Color("#88bd98")

static func paint(canvas: Control, number: int, region: StringName, done: bool, available: bool, active: bool, highlighted: bool, pulse: float) -> void:
	var unit := minf(canvas.size.x / 72.0, (canvas.size.y - 18.0) / 72.0)
	var center := Vector2(canvas.size.x * 0.5, (canvas.size.y - 18.0) * 0.54)
	canvas.draw_set_transform(center, 0, Vector2.ONE * unit)
	var accent := GOLD if active and available else (GREEN if done else (GOLD if available else Color("#68736d")))
	if number in [5, 10] and available and not done: accent = Color("#f3a46c")
	if active or highlighted:
		for radius in range(36, 29, -1):
			canvas.draw_circle(Vector2.ZERO, radius, Color(accent, (0.025 + pulse * 0.01)), true, -1, true)
		canvas.draw_arc(Vector2.ZERO, 30, -PI * 0.5, TAU - PI * 0.5, 64, accent, 2.3, true)
		canvas.draw_arc(Vector2.ZERO, 33, -0.55, 0.55, 20, Color(accent, 0.8), 1, true)
		canvas.draw_arc(Vector2.ZERO, 33, PI - 0.55, PI + 0.55, 20, Color(accent, 0.8), 1, true)
	elif done:
		canvas.draw_arc(Vector2.ZERO, 29, 0, TAU, 56, Color(accent, 0.8), 2, true)
	canvas.draw_circle(Vector2(0, 6), 24, Color("#07120f", 0.8), true, -1, true)
	var stone := Color("#969681") if available else Color("#3e4944")
	var light := Color("#c5bd98") if available else Color("#59635b")
	var roof := Color("#626b4d") if available else Color("#303c38")
	if region == &"graveyard": roof = Color("#717280") if available else Color("#343a41")
	elif region == &"volcanic": roof = Color("#925b46") if available else Color("#493831")
	elif region == &"frost": roof = Color("#adc8c9") if available else Color("#45585a")
	elif region == &"swamp": roof = Color("#547f6b") if available else Color("#31493e")
	var base := PackedVector2Array([Vector2(-26, 9), Vector2(-13, 3), Vector2(14, 2), Vector2(27, 10), Vector2(20, 18), Vector2(-15, 20), Vector2(-27, 14)])
	canvas.draw_colored_polygon(base, stone.darkened(0.56))
	canvas.draw_polyline(base, Color(light, 0.55), 1, true)
	canvas.draw_line(Vector2(-22, 13), Vector2(17, 17), Color(light, 0.3), 1, true)
	canvas.draw_line(Vector2(-12, 8), Vector2(19, 11), Color(light, 0.3), 1, true)
	if number in [5, 10]:
		_gate(canvas, number == 10, stone, light, roof, available)
	else:
		match (number - 1) % 4:
			0:
				_house(canvas, Vector2(-9, 6), 0.78, stone, light, roof)
				_house(canvas, Vector2(10, 10), 0.57, stone, light, roof)
				_pine(canvas, Vector2(17, -2), 0.65, roof)
				_pine(canvas, Vector2(-21, 4), 0.7, roof)
			1:
				_tower(canvas, Vector2(0, 10), 1.0, stone, light, roof)
				_pine(canvas, Vector2(-19, 8), 0.65, roof)
				_pine(canvas, Vector2(19, 12), 0.6, roof)
			2:
				_house(canvas, Vector2(-10, 10), 0.72, stone, light, roof)
				_tower(canvas, Vector2(11, 5), 0.78, stone, light, roof)
				canvas.draw_rect(Rect2(-17, -6, 31, 16), stone.darkened(0.27))
				for x in [-13, -3, 7]: canvas.draw_rect(Rect2(x, -12, 6, 9), light.darkened(0.24))
				canvas.draw_rect(Rect2(-5, 0, 7, 10), Color("#182420"))
			3:
				_altar(canvas, stone, light, available)
	if not available:
		canvas.draw_circle(Vector2(0, 9), 10, Color("#0b1512", 0.94), true, -1, true)
		canvas.draw_arc(Vector2(0, 5), 4, PI, TAU, 16, Color("#a0a99c"), 2, true)
		canvas.draw_style_box(_lock_box(), Rect2(-6, 5, 12, 10))
		canvas.draw_circle(Vector2(0, 9), 1.3, Color("#16211b"), true, -1, true)
	elif done:
		canvas.draw_circle(Vector2(0, -27), 6, Color("#1c3929"), true, -1, true)
		canvas.draw_polyline(PackedVector2Array([Vector2(-4, -27), Vector2(-1, -24), Vector2(5, -31)]), GREEN, 1.8, true)
	elif active:
		canvas.draw_colored_polygon(PackedVector2Array([Vector2(-4, -34), Vector2(0, -41), Vector2(4, -34), Vector2(0, -30)]), GOLD)
	canvas.draw_set_transform(Vector2.ZERO)
	var font: Font = ThemeDB.fallback_font
	var points := 10 if canvas.size.y < 80 else 11
	var label := "%02d" % number
	canvas.draw_string(font, Vector2(0, canvas.size.y - 3), label, HORIZONTAL_ALIGNMENT_CENTER, canvas.size.x, points, accent)

static func _house(c: Control, at: Vector2, unit: float, stone: Color, light: Color, roof: Color) -> void:
	var wall := PackedVector2Array([at + Vector2(-11, -11) * unit, at + Vector2(2, -15) * unit, at + Vector2(13, -7) * unit, at + Vector2(13, 4) * unit, at + Vector2(0, 9) * unit, at + Vector2(-11, 2) * unit])
	c.draw_colored_polygon(wall, stone)
	c.draw_colored_polygon(PackedVector2Array([at + Vector2(0, -10) * unit, at + Vector2(13, -7) * unit, at + Vector2(13, 4) * unit, at + Vector2(0, 9) * unit]), stone.darkened(0.35))
	c.draw_colored_polygon(PackedVector2Array([at + Vector2(-15, -10) * unit, at + Vector2(-3, -28) * unit, at + Vector2(17, -8) * unit, at + Vector2(0, -5) * unit]), roof)
	c.draw_polyline(PackedVector2Array([at + Vector2(-15, -10) * unit, at + Vector2(-3, -28) * unit, at + Vector2(17, -8) * unit]), light, 1, true)
	c.draw_rect(Rect2(at + Vector2(-6, -3) * unit, Vector2(4, 8) * unit), Color("#25312b"))
	c.draw_rect(Rect2(at + Vector2(6, -3) * unit, Vector2(3, 4) * unit), Color("#c3b27d"))

static func _tower(c: Control, at: Vector2, unit: float, stone: Color, light: Color, roof: Color) -> void:
	c.draw_rect(Rect2(at + Vector2(-8, -24) * unit, Vector2(16, 28) * unit), stone)
	c.draw_rect(Rect2(at + Vector2(2, -24) * unit, Vector2(6, 28) * unit), stone.darkened(0.37))
	c.draw_colored_polygon(PackedVector2Array([at + Vector2(-12, -23) * unit, at + Vector2(0, -40) * unit, at + Vector2(12, -23) * unit]), roof)
	c.draw_polyline(PackedVector2Array([at + Vector2(-12, -23) * unit, at + Vector2(0, -40) * unit, at + Vector2(12, -23) * unit]), light, 1, true)
	for y in [-18, -8]: c.draw_rect(Rect2(at + Vector2(-3, y) * unit, Vector2(4, 6) * unit), Color("#23312a"))
	c.draw_line(at + Vector2(-8, -3) * unit, at + Vector2(8, -3) * unit, light.darkened(0.2), 1, true)

static func _pine(c: Control, at: Vector2, unit: float, color: Color) -> void:
	c.draw_line(at, at + Vector2(0, -26) * unit, color.darkened(0.45), 2, true)
	for index in 3:
		var tip := at + Vector2(0, -30 + index * 7) * unit
		c.draw_colored_polygon(PackedVector2Array([tip, tip + Vector2(8 + index, 14) * unit, tip + Vector2(-8 - index, 14) * unit]), color.darkened(index * 0.10))

static func _altar(c: Control, stone: Color, light: Color, available: bool) -> void:
	for index in 3:
		c.draw_colored_polygon(PackedVector2Array([Vector2(-19 + index * 4, 9 - index * 4), Vector2(0, 2 - index * 4), Vector2(19 - index * 4, 9 - index * 4), Vector2(0, 16 - index * 4)]), stone.lightened(index * 0.1))
	var magic := Color("#72d5c5") if available else Color("#425d57")
	c.draw_colored_polygon(PackedVector2Array([Vector2(-8, -7), Vector2(0, -18), Vector2(9, -7), Vector2(0, 3)]), magic)
	c.draw_line(Vector2(0, -18), Vector2(0, 3), light, 1, true)
	for x in [-19, 19]:
		c.draw_rect(Rect2(x - 2, -10, 4, 19), stone.darkened(0.2))
		c.draw_line(Vector2(x - 4, -10), Vector2(x + 4, -10), light, 2, true)

static func _gate(c: Control, sovereign: bool, stone: Color, light: Color, roof: Color, available: bool) -> void:
	var fire := Color("#eb9b54") if available else Color("#495650")
	for x in [-18, 18]:
		c.draw_rect(Rect2(x - 5, -28, 10, 43), stone.darkened(0.15))
		c.draw_rect(Rect2(x + 1, -28, 4, 43), stone.darkened(0.45))
		c.draw_colored_polygon(PackedVector2Array([Vector2(x - 8, -28), Vector2(x, -44 if sovereign else -37), Vector2(x + 8, -28)]), roof)
		c.draw_polyline(PackedVector2Array([Vector2(x - 8, -28), Vector2(x, -44 if sovereign else -37), Vector2(x + 8, -28)]), light, 1, true)
		for y in [-20, -7, 6]: c.draw_line(Vector2(x - 5, y), Vector2(x + 5, y), light.darkened(0.2), 1, true)
	c.draw_rect(Rect2(-13, -20, 26, 35), stone.darkened(0.35))
	c.draw_arc(Vector2(0, -13), 12, PI, TAU, 24, light, 4, true)
	c.draw_rect(Rect2(-9, -13, 18, 28), Color("#101c17"))
	c.draw_arc(Vector2(0, -12), 8, PI, TAU, 24, fire, 2, true)
	for x in [-9, 9]: c.draw_line(Vector2(x, -12), Vector2(x, 15), fire, 2, true)
	if sovereign:
		c.draw_colored_polygon(PackedVector2Array([Vector2(-12, -23), Vector2(0, -44), Vector2(12, -23)]), roof)
		c.draw_colored_polygon(PackedVector2Array([Vector2(-4, -25), Vector2(0, -33), Vector2(4, -25), Vector2(0, -20)]), light)
		c.draw_line(Vector2(0, -14), Vector2(0, 15), light.darkened(0.1), 1, true)
	else:
		for x in [-25, 25]:
			c.draw_rect(Rect2(x - 1, -22, 2, 18), light.darkened(0.1))
			c.draw_colored_polygon(PackedVector2Array([Vector2(x - 4, -22), Vector2(x - 1, -31), Vector2(x + 1, -34), Vector2(x + 4, -25), Vector2(x + 2, -20)]), fire)
	for index in 3: c.draw_rect(Rect2(-10 - index * 3, 13 + index * 3, 20 + index * 6, 3), stone.lightened(index * 0.06))

static func _lock_box() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#899286")
	style.set_corner_radius_all(1)
	return style
