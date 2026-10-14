extends Node2D

signal collected(value: int)

var value := 5
var player: SurvivorPlayer
var bonus := 0.0
var phase := 0.0
var collected_now := false

func _ready() -> void:
	add_to_group("xp_drop")

func _process(delta: float) -> void:
	if NetworkSession.running and NetworkSession.hosting:
		var nearest := INF
		for candidate in get_tree().get_nodes_in_group("survivor_player"):
			if not candidate.is_dead and candidate.global_position.distance_squared_to(global_position) < nearest:
				nearest = candidate.global_position.distance_squared_to(global_position)
				player = candidate
	if collected_now or not is_instance_valid(player):
		return
	phase += delta
	var distance := global_position.distance_to(player.global_position)
	var magnet := player.pickup_radius
	if distance < magnet or phase > 14.0:
		var direction := (player.global_position - global_position).normalized()
		global_position += direction * minf(distance, (400.0 + maxf(0.0, magnet - distance) * 3.2) * delta)
	if distance < 26.0:
		collected_now = true
		collected.emit(roundi(value * (1.0 + bonus)))
		queue_free()
	queue_redraw()

func _draw() -> void:
	var bob := sin(phase * 4.0) * 2.0
	draw_circle(Vector2(0, bob), 9.0, Color("#071725", 0.95))
	draw_colored_polygon(PackedVector2Array([Vector2(0, -8 + bob), Vector2(7, bob), Vector2(0, 8 + bob), Vector2(-7, bob)]), Color("#71e5d0"))
	draw_circle(Vector2.ZERO, 2.5, Color("#e0fff1"))
	draw_polyline(PackedVector2Array([Vector2(0, -8 + bob), Vector2(7, bob), Vector2(0, 8 + bob), Vector2(-7, bob), Vector2(0, -8 + bob)]), Color("#b3fff4"), 1.0, true)
