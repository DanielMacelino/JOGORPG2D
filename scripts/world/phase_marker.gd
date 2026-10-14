extends Node2D
signal broken
signal sealed
var kind := "altar"
var player: SurvivorPlayer
var max_health := 600.0
var health := 600.0
var progress := 0.0
var complete := false
var radius := 82.0
var font: Font

func _ready() -> void:
	z_index = 1
	font = preload("res://scripts/ui/wild_theme.gd").body_font()
	add_to_group("phase_marker")

func _process(delta: float) -> void:
	if NetworkSession.running and NetworkSession.hosting and kind == "rift":
		for candidate in get_tree().get_nodes_in_group("survivor_player"):
			if not candidate.is_dead and candidate.global_position.distance_to(global_position) < radius:
				player = candidate
				break
	if kind == "rift" and not complete and is_instance_valid(player) and not player.is_dead:
		if global_position.distance_to(player.global_position) < radius:
			progress += delta
			if progress >= 1.6:
				complete = true
				sealed.emit()
	queue_redraw()

func take_damage(amount: float) -> void:
	if kind != "altar" or health <= 0.0:
		return
	health = maxf(0.0, health - amount)
	if health <= 0.0:
		broken.emit()
	queue_redraw()

func _draw() -> void:
	var color := Color("#b0f6da") if complete else (Color("#efbf72") if kind == "altar" else Color("#b999ff"))
	draw_circle(Vector2.ZERO, radius, Color(color, 0.08))
	draw_arc(Vector2.ZERO, radius, 0, TAU, 48, Color(color, 0.75), 2.0, true)
	if kind == "altar":
		draw_colored_polygon(PackedVector2Array([Vector2(-24, 12), Vector2(-20, -26), Vector2(0, -42), Vector2(20, -26), Vector2(24, 12)]), Color("#273e39"))
		draw_polyline(PackedVector2Array([Vector2(-24, 12), Vector2(-20, -26), Vector2(0, -42), Vector2(20, -26), Vector2(24, 12)]), color, 2, true)
		draw_circle(Vector2(0, -16), 8, color)
		draw_rect(Rect2(-34, 24, 68, 6), Color("#071615"))
		draw_rect(Rect2(-33, 25, 66 * health / max_health, 4), color)
	else:
		draw_arc(Vector2.ZERO, 36, 0, TAU, 40, color, 3, true)
		draw_arc(Vector2.ZERO, 45, -PI * 0.5, -PI * 0.5 + TAU * clampf(progress / 1.6, 0, 1), 40, Color("#f4e3bd"), 4, true)
		for index in 6:
			var direction := Vector2.from_angle(index * TAU / 6.0)
			draw_line(direction * 15, direction * 32, color, 2, true)
	if font != null:
		var text := "ALTAR" if kind == "altar" else ("SELADA" if complete else "ENTRE PARA SELAR")
		draw_string(font, Vector2(-65, radius + 20), text, HORIZONTAL_ALIGNMENT_CENTER, 130, 12, color)
