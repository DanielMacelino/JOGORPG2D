extends Node2D
signal volley_requested(position: Vector2, direction: Vector2, damage: float, color: Color, target: SurvivorPlayer)
var spec: Dictionary = {}
var elapsed := 0.0
var fired := false
var pulse_clock := 0.0
var radius := 80.0
var shape := "circle"
var player: SurvivorPlayer

func _ready() -> void:
	shape = str(spec.get("shape", "circle"))
	radius = float(spec.get("radius", 80.0))
	player = spec.get("target")
	add_to_group("danger_area")
	z_index = 0

func _process(delta: float) -> void:
	elapsed += delta
	var duration := float(spec.get("duration", 1.25))
	if elapsed >= duration and not fired:
		fired = true
		pulse_clock = 1.0
		if shape == "fan":
			var count := int(spec.get("count", 5))
			var spread := float(spec.get("spread", 1.0))
			var direction: Vector2 = spec.get("direction", Vector2.RIGHT)
			for index in count:
				volley_requested.emit(global_position, direction.rotated((float(index) / maxf(1, count - 1) - 0.5) * spread), float(spec.damage), spec.color, player)
		else:
			_damage_player()
	if fired and bool(spec.get("lingering", false)):
		pulse_clock -= delta
		if pulse_clock <= 0.0:
			pulse_clock += 1.0
			_damage_player()
	if elapsed >= duration + (3.2 if bool(spec.get("lingering", false)) else 0.30):
		queue_free()
	queue_redraw()

func contains_point(point: Vector2) -> bool:
	var distance := global_position.distance_to(point)
	match shape:
		"ring": return distance <= radius and distance >= float(spec.get("inner", radius * 0.4))
		"line":
			var end: Vector2 = spec.get("end", global_position)
			var segment := end - global_position
			var fraction := clampf((point - global_position).dot(segment) / maxf(segment.length_squared(), 0.001), 0, 1)
			return point.distance_to(global_position + segment * fraction) <= radius
		"fan": return false
	return distance <= radius

func _damage_player() -> void:
	if bool(spec.get("player_team", false)): return
	if NetworkSession.running and NetworkSession.hosting:
		for candidate in get_tree().get_nodes_in_group("survivor_player"):
			if not candidate.is_dead and contains_point(candidate.global_position):
				candidate.take_damage(float(spec.damage), true)
		return
	if is_instance_valid(player) and contains_point(player.global_position):
		player.take_damage(float(spec.damage), true)

func _draw() -> void:
	var color: Color = spec.get("color", Color("#ffc58b"))
	var progress := clampf(elapsed / float(spec.get("duration", 1.25)), 0, 1)
	var fill := Color(color, 0.13 + progress * 0.18)
	match shape:
		"line":
			var end: Vector2 = spec.get("end", global_position)
			var toward := end - global_position
			draw_line(Vector2.ZERO, toward, Color("#29111b"), radius * 2 + 4, true)
			draw_line(Vector2.ZERO, toward, fill, radius * 2, true)
			draw_line(Vector2.ZERO, toward * progress, color, 3, true)
		"ring":
			var inner := float(spec.get("inner", radius * 0.4))
			draw_arc(Vector2.ZERO, (inner + radius) * 0.5, 0, TAU, 64, fill, radius - inner, true)
			draw_arc(Vector2.ZERO, inner, 0, TAU, 48, color, 2, true)
			draw_arc(Vector2.ZERO, radius, 0, TAU * progress, 64, color, 3, true)
		"fan":
			var direction: Vector2 = spec.get("direction", Vector2.RIGHT)
			var spread := float(spec.get("spread", 1.0))
			var count := int(spec.get("count", 5))
			for index in count:
				var axis := direction.rotated((float(index) / maxf(1, count - 1) - 0.5) * spread)
				draw_line(axis * 20, axis * radius, Color(color, 0.40 + progress * 0.45), 2, true)
		_:
			draw_circle(Vector2.ZERO, radius, fill)
			draw_arc(Vector2.ZERO, radius, 0, TAU, 48, Color("#29111b"), 6, true)
			draw_arc(Vector2.ZERO, radius, 0, TAU * progress, 48, color, 3, true)
