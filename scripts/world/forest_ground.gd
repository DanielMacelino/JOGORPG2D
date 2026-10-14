extends Node2D
## Static, seeded woodland illustration. Physics footprints are unchanged.
const WORLD_RECT := Rect2(-1280, -910, 2560, 1820)
var rng := RandomNumberGenerator.new()
var stones: Array[Dictionary] = []
var shrubs: Array[Dictionary] = []
var trees: Array[Dictionary] = []
var flecks: Array[Dictionary] = []
var theme: StringName = &"forest"
const PALETTES := {
	"forest": ["#263d2e", "#414a32", "#50643a", "#7c8651", "#657363", "#83907a", "#4b5b4c", "#294632", "#527047", "#47683e", "#584b33"],
	"graveyard": ["#30383b", "#42454a", "#56645c", "#8b9180", "#656f72", "#9ca7a4", "#454e54", "#475455", "#6e7c74", "#596669", "#565352"],
	"volcanic": ["#3a302e", "#514039", "#635449", "#a48459", "#5e5653", "#8f7870", "#3e3639", "#4e3e3b", "#806052", "#65504a", "#53423a"],
	"castle": ["#33363e", "#45434a", "#545954", "#8a8b71", "#666c76", "#9b9ea6", "#474b58", "#48505b", "#737c88", "#626b77", "#504e56"],
	"frost": ["#789095", "#a6b6b3", "#71898b", "#b4c6b8", "#7c949a", "#c6d4cc", "#58717d", "#436774", "#a5c2bc", "#688d93", "#667577"],
	"swamp": ["#293c33", "#495340", "#6a7848", "#a4a974", "#607567", "#8d9a77", "#3e564c", "#3c5741", "#788b55", "#57734b", "#665f41"]
}

func configure(map_theme: StringName) -> void:
	theme = map_theme if PALETTES.has(str(map_theme)) else &"forest"
	queue_redraw()

func _tone(index: int) -> Color:
	return Color(PALETTES[str(theme)][index])

func _ready() -> void:
	rng.seed = 27392
	for index in 48:
		var point := Vector2(rng.randf_range(-1210, 1210), rng.randf_range(-840, 840))
		if point.length() < 150.0:
			point.x += 250.0
		trees.append({"p": point, "r": rng.randf_range(20.0, 33.0), "shade": rng.randf_range(0.75, 1.15), "kind": index % 3})
	for index in 175:
		shrubs.append({"p": Vector2(rng.randf_range(-1250, 1250), rng.randf_range(-880, 880)), "r": rng.randf_range(8.0, 24.0), "h": rng.randf_range(0.0, 1.0)})
	for index in 75:
		stones.append({"p": Vector2(rng.randf_range(-1240, 1240), rng.randf_range(-870, 870)), "r": rng.randf_range(7.0, 16.0)})
	for index in 3200:
		flecks.append({"p": Vector2(rng.randf_range(-1280, 1280), rng.randf_range(-910, 910)), "length": rng.randf_range(1.0, 5.0), "shade": index % 4})
	trees.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.p.y < b.p.y)
	for tree in trees:
		_add_circle_obstacle(tree.p + Vector2(0, 11), 10)
	for stone in stones:
		_add_circle_obstacle(stone.p, float(stone.r) * 0.65)
	queue_redraw()

func _add_circle_obstacle(point: Vector2, radius: float) -> void:
	var body := StaticBody2D.new()
	body.position = point
	body.collision_layer = 4
	body.collision_mask = 0
	var collider := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = radius
	collider.shape = shape
	body.add_child(collider)
	add_child(body)

func _draw() -> void:
	draw_rect(WORLD_RECT, _tone(0))
	_draw_terrain()
	# An old trail gives the arena a readable structure.
	var trail := PackedVector2Array()
	for i in 50:
		var x := -1280.0 + i * 2560.0 / 49.0
		trail.append(Vector2(x, sin(x * 0.0022) * 135.0 - 38.0))
	for i in range(49, -1, -1):
		var x := -1280.0 + i * 2560.0 / 49.0
		trail.append(Vector2(x, sin(x * 0.0022) * 135.0 + 70.0))
	draw_colored_polygon(trail, _tone(1))
	var tones := [Color(_tone(3), 0.14), Color(_tone(0).darkened(0.4), 0.23), Color(_tone(2), 0.26), Color(_tone(8), 0.12)]
	for fleck in flecks:
		var point: Vector2 = fleck.p
		draw_line(point, point + Vector2(float(fleck.length), -0.7), tones[int(fleck.shade)], 1, false)
	_draw_ruins(Vector2(-265, -155))
	for shrub in shrubs:
		if theme == &"volcanic":
			_draw_ash(shrub.p, float(shrub.r))
		elif theme == &"castle":
			draw_line(shrub.p, shrub.p + Vector2(float(shrub.r), -4), Color(_tone(5), 0.12), 1, false)
		elif theme == &"swamp":
			_draw_reeds(shrub.p, float(shrub.r), float(shrub.h))
		else:
			_draw_fern(shrub.p, float(shrub.r), float(shrub.h))
	for stone in stones:
		_draw_stone(stone.p, float(stone.r))
	for tree in trees:
		_draw_tree(tree.p, float(tree.r), float(tree.shade), int(tree.kind))
	draw_rect(WORLD_RECT, _tone(0).darkened(0.45), false, 8)

func _draw_terrain() -> void:
	if theme == &"castle":
		for column in range(-13, 14):
			for row in range(-10, 10):
				var offset := 45.0 if row % 2 == 0 else 0.0
				var tile := Rect2(column * 90.0 + offset, row * 86.0, 85, 81)
				draw_rect(tile, Color(_tone(5), 0.045 if (column + row) % 3 else 0.08))
			draw_line(Vector2(column * 90, -910), Vector2(column * 90, 910), Color("#172029", 0.08), 1)
	elif theme == &"swamp":
		for index in range(0, shrubs.size(), 12):
			var point: Vector2 = shrubs[index].p
			_draw_oval(point, Vector2(95 + index % 60, 36 + index % 15), Color("#1d3430"))
			_draw_oval(point + Vector2(-12, -2), Vector2(77 + index % 30, 23), Color("#344e42"))
			draw_arc(point, 38, 0.15, 2.5, 16, Color("#71896b", 0.28), 1, true)
	elif theme == &"frost":
		for index in range(0, shrubs.size(), 8):
			var point: Vector2 = shrubs[index].p
			_draw_oval(point, Vector2(92 + index % 60, 45), Color("#bfd0c6", 0.34))
			_draw_oval(point + Vector2(18, 0), Vector2(64, 28), Color("#d0dacd", 0.24))
	elif theme == &"volcanic":
		for index in 7:
			var point := Vector2(-1150 + index * 365, -650 + sin(index * 2.8) * 420)
			var seam := PackedVector2Array([point, point + Vector2(40, 24), point + Vector2(60, -17), point + Vector2(99, -5), point + Vector2(145, 32)])
			draw_polyline(seam, Color("#221f20"), 17, true)
			draw_polyline(seam, Color("#935d43"), 5, true)
			draw_polyline(seam, Color("#d09860", 0.65), 1.7, true)
	elif theme == &"graveyard":
		for index in range(0, shrubs.size(), 13):
			var point: Vector2 = shrubs[index].p
			_draw_oval(point, Vector2(44, 16), Color("#1e2b2d", 0.7))
			draw_line(point - Vector2(30, 0), point + Vector2(31, 0), Color("#65736b", 0.2), 2)

func _draw_fern(point: Vector2, radius: float, shade: float) -> void:
	var color := _tone(2).lerp(_tone(3), shade * 0.5)
	for branch in 5:
		var angle := -PI + branch * PI / 4.0
		var tip := point + Vector2(cos(angle) * radius, sin(angle) * radius * 0.7 - 3)
		draw_line(point, tip, color.darkened(0.15), 1, true)
		for leaf in 3:
			var center := point.lerp(tip, 0.35 + leaf * 0.2)
			var axis := (tip - point).normalized()
			var side := axis.orthogonal() * radius * 0.16
			draw_colored_polygon(PackedVector2Array([center - axis * 3, center + side - axis * 4, center + axis * 3, center - side - axis * 4]), color)

func _draw_stone(point: Vector2, radius: float) -> void:
	_draw_oval(point + Vector2(4, 5), Vector2(radius * 1.25, radius * 0.65), Color("#10251b", 0.5))
	var poly := PackedVector2Array([Vector2(-1, -0.2), Vector2(-0.45, -0.85), Vector2(0.38, -0.9), Vector2(0.9, -0.25), Vector2(0.8, 0.55), Vector2(-0.7, 0.6)])
	for i in poly.size():
		poly[i] = point + poly[i] * radius
	draw_colored_polygon(poly, _tone(4))
	draw_colored_polygon(PackedVector2Array([poly[0], poly[1], poly[2], point, poly[5]]), _tone(5))
	draw_colored_polygon(PackedVector2Array([point, poly[2], poly[3], poly[4]]), _tone(6))
	draw_line(poly[0] + Vector2(2, 3), point + Vector2(-2, 4), _tone(3), 2, true)

func _draw_tree(point: Vector2, radius: float, shade: float, kind: int) -> void:
	if theme == &"graveyard":
		_draw_gravestone(point, radius, kind)
		return
	if theme == &"volcanic":
		_draw_outcrop(point, radius)
		return
	if theme == &"castle":
		_draw_pillar(point, radius, kind)
		return
	_draw_oval(point + Vector2(17, 14), Vector2(radius * 1.35, radius * 0.55), Color("#10231b", 0.55))
	draw_colored_polygon(PackedVector2Array([point + Vector2(-6, 13), point + Vector2(-4, -28), point + Vector2(4, -32), point + Vector2(7, 13), point + Vector2(1, 19)]), _tone(10))
	draw_line(point + Vector2(2, -16), point + Vector2(3, 12), Color("#8a754e"), 2, true)
	var dark := _tone(7).lightened((shade - 0.75) * 0.15)
	if theme == &"swamp" and kind != 0:
		for branch in 4:
			var root := point + Vector2(0, -16 - branch * 8)
			var tip := root + Vector2((-1 if branch % 2 else 1) * radius, -radius * 0.7)
			draw_line(root, tip, _tone(10), 4, true)
			draw_line(tip, tip + Vector2(2, 24), Color(_tone(3), 0.4), 2, true)
		return
	if kind == 0 or theme == &"frost":
		for tier in 3:
			var y := -radius * (2.5 - tier * 0.65)
			var span := radius * (0.64 + tier * 0.23)
			var tip := point + Vector2(0, y - radius * 0.9)
			var left := point + Vector2(-span, y + radius * 0.58)
			var right := point + Vector2(span, y + radius * 0.58)
			draw_colored_polygon(PackedVector2Array([tip, right, point + Vector2(0, y + radius * 0.7), left]), dark.lightened(tier * 0.025))
			draw_colored_polygon(PackedVector2Array([tip, point + Vector2(-3, y + radius * 0.5), left]), _tone(8).lightened((shade - 0.75) * 0.1))
			if theme == &"frost":
				draw_line(left + Vector2(1, -1), tip, Color("#d4dfd2"), 3, true)
	else:
		var offsets := PackedVector2Array([Vector2(-1.2, -0.7), Vector2(-0.95, -1.6), Vector2(-0.2, -2.2), Vector2(0.6, -2.04), Vector2(1.12, -1.5), Vector2(1.3, -0.65), Vector2(0.62, -0.25), Vector2(-0.5, -0.23)])
		var crown := PackedVector2Array()
		for offset in offsets:
			crown.append(point + offset * radius)
		draw_colored_polygon(crown, dark)
		draw_colored_polygon(PackedVector2Array([crown[0], crown[1], crown[2], point + Vector2(-0.1, -0.7) * radius]), _tone(8))
		draw_colored_polygon(PackedVector2Array([crown[2], crown[3], crown[4], point + Vector2(0.25, -0.8) * radius, point + Vector2(-0.1, -0.7) * radius]), _tone(9))
		draw_colored_polygon(PackedVector2Array([crown[4], crown[5], crown[6], point + Vector2(0.25, -0.8) * radius]), dark.lightened(0.025))
		for i in 4:
			var leaf := point + Vector2(-0.65 + i * 0.4, -1.2 + sin(i * 1.7) * 0.4) * radius
			draw_line(leaf, leaf + Vector2(6, -2), Color("#84965d", 0.4), 2, true)

func _draw_ruins(center: Vector2) -> void:
	draw_arc(center, 87, 0, TAU, 64, _tone(0).darkened(0.2), 30, true)
	for i in 14:
		var angle := i * TAU / 14
		var axis := Vector2.RIGHT.rotated(angle)
		var tangent := axis.orthogonal()
		var point := center + axis * 80
		var tile := PackedVector2Array([point - axis * 10 - tangent * 13, point + axis * 12 - tangent * 10, point + axis * 11 + tangent * 12, point - axis * 12 + tangent * 13])
		draw_colored_polygon(tile, _tone(4) if i % 3 != 0 else _tone(6))
		draw_line(tile[0], tile[1], _tone(5), 1, true)
	draw_arc(center, 61, 0.2, 4.9, 48, Color(_tone(3), 0.22), 1, true)
	draw_colored_polygon(PackedVector2Array([center + Vector2(-20, 4), center + Vector2(-12, -32), center + Vector2(10, -41), center + Vector2(24, -5), center + Vector2(15, 12)]), _tone(4))
	draw_colored_polygon(PackedVector2Array([center + Vector2(-12, -32), center + Vector2(10, -41), center + Vector2(5, -4), center + Vector2(-20, 4)]), _tone(5))
	draw_line(center + Vector2(-3, -24), center + Vector2(1, -8), _tone(3).lightened(0.25), 2, true)
	_draw_fern(center + Vector2(19, 14), 18, 0.7)

func _draw_gravestone(point: Vector2, radius: float, kind: int) -> void:
	_draw_oval(point + Vector2(6, 10), Vector2(radius, radius * 0.34), Color("#15252a", 0.6))
	var height := radius * (1.5 if kind == 0 else 1.15)
	var slab := PackedVector2Array([point + Vector2(-radius * 0.5, 7), point + Vector2(-radius * 0.45, -height), point + Vector2(-radius * 0.15, -height - 8), point + Vector2(radius * 0.3, -height - 5), point + Vector2(radius * 0.45, 7)])
	draw_colored_polygon(slab, _tone(4))
	draw_line(slab[1], slab[2], _tone(5), 3, true)
	draw_line(point + Vector2(0, -height + 8), point + Vector2(0, -10), _tone(6), 3, true)
	draw_line(point + Vector2(-8, -height + 20), point + Vector2(8, -height + 20), _tone(6), 3, true)
	_draw_fern(point + Vector2(-10, 10), 12, 0.1)

func _draw_outcrop(point: Vector2, radius: float) -> void:
	_draw_oval(point + Vector2(8, 8), Vector2(radius * 1.2, radius * 0.4), Color("#241e20", 0.6))
	var peak := point + Vector2(-2, -radius * 1.8)
	var left := point + Vector2(-radius * 0.85, 4)
	var right := point + Vector2(radius * 0.75, 7)
	draw_colored_polygon(PackedVector2Array([peak, right, point + Vector2(0, 11), left]), _tone(6))
	draw_colored_polygon(PackedVector2Array([peak, point + Vector2(-2, 5), left]), _tone(4))
	draw_line(peak + Vector2(3, 11), point + Vector2(10, 0), Color("#b58156", 0.65), 1.6, true)

func _draw_pillar(point: Vector2, radius: float, kind: int) -> void:
	_draw_oval(point + Vector2(12, 12), Vector2(radius * 1.1, radius * 0.45), Color("#1b2130", 0.7))
	var height := radius * (1.7 if kind == 0 else 1.1)
	draw_rect(Rect2(point + Vector2(-14, -height), Vector2(28, height + 10)), _tone(4))
	draw_rect(Rect2(point + Vector2(-14, -height), Vector2(10, height + 10)), _tone(5))
	draw_rect(Rect2(point + Vector2(-20, -height - 7), Vector2(40, 10)), _tone(5))
	draw_rect(Rect2(point + Vector2(-22, 6), Vector2(44, 11)), _tone(6))
	draw_line(point + Vector2(6, -height + 4), point + Vector2(0, -height + 17), _tone(6), 2, true)

func _draw_ash(point: Vector2, radius: float) -> void:
	_draw_oval(point, Vector2(radius, radius * 0.3), Color("#695047", 0.32))
	for index in 3:
		var start := point + Vector2(index * 6 - 6, 0)
		draw_line(start, start + Vector2(-3, -radius * 0.65), Color("#958166", 0.35), 1.3, true)

func _draw_reeds(point: Vector2, radius: float, shade: float) -> void:
	var color := _tone(2).lerp(_tone(3), shade * 0.7)
	for index in 4:
		var stem := point + Vector2(index * 4 - 6, 0)
		var tip := stem + Vector2(index * 2 - 4, -radius * (0.9 + index * 0.15))
		draw_line(stem, tip, color, 1.5, true)
		draw_line(tip, tip + Vector2(1, -6), _tone(10), 3, true)
		draw_line(stem + Vector2(0, -8), stem + Vector2(index * 4 - 7, -16), color.darkened(0.08), 1, true)

func _draw_oval(point: Vector2, radii: Vector2, color: Color) -> void:
	draw_set_transform(point, 0, Vector2(1, radii.y / maxf(1, radii.x)))
	draw_circle(Vector2.ZERO, radii.x, color)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

