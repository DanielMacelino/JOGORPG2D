extends Control

var time := 0.0
var motes: Array[Dictionary] = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for index in 34:
		var seed_value := float(index) * 137.71
		motes.append({
			"x": fposmod(seed_value * 2.71, 1.0),
			"y": fposmod(seed_value * 1.83, 1.0),
			"speed": 5.0 + float(index % 7) * 2.0,
			"phase": seed_value,
			"size": 1.0 + float(index % 3) * 0.45
		})

func _process(delta: float) -> void:
	time += delta
	queue_redraw()

func _draw() -> void:
	for mote in motes:
		var x: float = mote.x
		var y: float = fposmod(float(mote.y) - time * float(mote.speed) / maxf(300.0, size.y), 1.0)
		var phase: float = float(mote.phase)
		var drift := sin(time * 0.7 + phase) * 9.0
		var point := Vector2(x * size.x + drift, y * size.y)
		var pulse := 0.22 + 0.2 * (0.5 + 0.5 * sin(time * 1.7 + phase))
		var radius: float = float(mote.size)
		draw_circle(point, radius * 3.5, Color(0.88, 0.62, 0.31, pulse * 0.13))
		draw_colored_polygon(PackedVector2Array([point + Vector2(0, -radius * 2.0), point + Vector2(radius * 0.7, 0), point + Vector2(0, radius * 2.0), point + Vector2(-radius * 0.7, 0)]), Color(0.98, 0.78, 0.47, pulse))
