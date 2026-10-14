extends Node2D

const AREA := Rect2(-1220, -860, 2440, 1720)

var time := 0.0
var rng := RandomNumberGenerator.new()
var fireflies: Array[Dictionary] = []
var leaves: Array[Dictionary] = []
var grass: Array[Dictionary] = []
var theme: StringName = &"forest"
var mote_color := Color("#edbf66")
var mist_color := Color("#bec2a0")
var drift_color := Color("#718252")

func configure(map_theme: StringName) -> void:
	theme = map_theme
	match theme:
		&"graveyard":
			mote_color = Color("#a5c9c9")
			mist_color = Color("#b5c7c9")
			drift_color = Color("#8e9e9d")
		&"volcanic":
			mote_color = Color("#e4a46e")
			mist_color = Color("#b6a19b")
			drift_color = Color("#c49a76")
		&"castle":
			mote_color = Color("#c19aa7")
			mist_color = Color("#bbb7c6")
			drift_color = Color("#9991a2")
		&"frost":
			mote_color = Color("#e0eadf")
			mist_color = Color("#d3e4df")
			drift_color = Color("#e1e8da")
		&"swamp":
			mote_color = Color("#d6d78c")
			mist_color = Color("#b5c28b")
			drift_color = Color("#a1ad74")
		_:
			mote_color = Color("#edbf66")
			mist_color = Color("#bec2a0")
			drift_color = Color("#718252")

func _ready() -> void:
	rng.seed = 70194
	for index in 30:
		fireflies.append({
			"position": Vector2(rng.randf_range(AREA.position.x, AREA.end.x), rng.randf_range(AREA.position.y, AREA.end.y)),
			"phase": rng.randf_range(0.0, TAU),
			"speed": rng.randf_range(4.0, 12.0),
			"size": rng.randf_range(1.0, 2.2)
		})
	for index in 12:
		leaves.append({
			"x": rng.randf_range(AREA.position.x, AREA.end.x),
			"y": rng.randf_range(AREA.position.y, AREA.end.y),
			"phase": rng.randf_range(0.0, TAU),
			"speed": rng.randf_range(13.0, 27.0),
			"size": rng.randf_range(3.0, 5.5),
			"color": drift_color.lightened(0.1) if index % 3 == 0 else drift_color
		})
	for index in 16:
		grass.append({"position": Vector2(rng.randf_range(-1180, 1180), rng.randf_range(-820, 820)), "phase": rng.randf_range(0.0, TAU), "height": rng.randf_range(9.0, 18.0)})

func _process(delta: float) -> void:
	time += delta
	queue_redraw()

func _draw() -> void:
	for index in 5:
		var x := -930.0 + float(index) * 465.0 + sin(time * 0.12 + index) * 38.0
		var y := 230.0 + sin(time * 0.18 + index * 2.0) * 22.0
		draw_set_transform(Vector2(x, y), 0.0, Vector2(1.0, 0.28))
		draw_circle(Vector2.ZERO, 260.0, Color(mist_color, 0.018 if theme == &"forest" else 0.03))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for tuft in grass:
		if theme != &"forest" and theme != &"swamp":
			continue
		var point: Vector2 = tuft.position
		var phase: float = tuft.phase
		var height: float = tuft.height
		for blade in 3:
			var side := float(blade - 1)
			var sway := sin(time * 1.45 + phase + side * 0.7) * 4.5
			var tip := point + Vector2(side * 5.0 + sway, -height * (1.0 - absf(side) * 0.12))
			draw_line(point, tip, Color(drift_color, 0.62 - absf(side) * 0.1), 1.8, true)
	for mote in fireflies:
		var origin: Vector2 = mote.position
		var phase: float = mote.phase
		var drift := Vector2(sin(time * 0.45 + phase) * 13.0, cos(time * 0.32 + phase) * 9.0)
		var point := origin + drift
		var glow := 0.25 + 0.55 * (0.5 + 0.5 * sin(time * 1.65 + phase))
		var radius: float = mote.size
		draw_circle(point, radius * 4.0, Color(mote_color, glow * 0.12))
		draw_circle(point, radius, Color(mote_color.lightened(0.08), glow * 0.78))
	for leaf in leaves:
		var phase: float = leaf.phase
		var travel := fposmod(time * float(leaf.speed) + phase * 53.0, AREA.size.y)
		var point := Vector2(float(leaf.x) + sin(time * 0.55 + phase) * 24.0, AREA.end.y - travel if theme == &"volcanic" else AREA.position.y + travel)
		var angle := sin(time * 1.8 + phase) * 1.1
		var size: float = leaf.size
		var axis := Vector2(cos(angle), sin(angle)) * size
		if theme == &"frost":
			draw_circle(point, size * 0.42, Color(drift_color, 0.65))
		elif theme == &"graveyard" or theme == &"castle":
			draw_line(point - axis * 0.4, point + axis * 0.4, Color(drift_color, 0.3), 1.0, true)
		elif theme == &"volcanic":
			draw_circle(point, size * 0.35, Color(drift_color, 0.58))
		else:
			draw_line(point - axis, point + axis, Color(leaf.color, 0.7), 2.0, true)
