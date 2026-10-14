extends Node2D

signal collected(value: int)

var value := 1
var player: SurvivorPlayer
var phase := 0.0
var picked_up := false

func _ready() -> void:
	add_to_group("gold_drop")

func _process(delta: float) -> void:
	if NetworkSession.running and NetworkSession.hosting:
		var nearest := INF
		for candidate in get_tree().get_nodes_in_group("survivor_player"):
			if not candidate.is_dead and candidate.global_position.distance_squared_to(global_position) < nearest:
				nearest = candidate.global_position.distance_squared_to(global_position)
				player = candidate
	if picked_up or not is_instance_valid(player):
		return
	phase += delta
	var distance := global_position.distance_to(player.global_position)
	var magnet := player.pickup_radius * 0.85
	if distance < magnet or phase > 14.0:
		global_position += (player.global_position - global_position).normalized() * minf(distance, (360.0 + maxf(0.0, magnet - distance) * 2.2) * delta)
	if distance < 25.0:
		picked_up = true
		collected.emit(value)
		queue_free()
	queue_redraw()

func _draw() -> void:
	var bob := sin(phase * 5.0) * 2.0
	draw_circle(Vector2(0, bob), 8.0, Color("#211505", 0.95))
	draw_colored_polygon(PackedVector2Array([Vector2(0, -7 + bob), Vector2(6, -1 + bob), Vector2(4, 6 + bob), Vector2(-4, 6 + bob), Vector2(-6, -1 + bob)]), Color("#ffd96e"))
	draw_line(Vector2(-2, -2 + bob), Vector2(2, 2 + bob), Color("#fff9db"), 1.5, true)
	draw_arc(Vector2(0, bob), 8, 0, TAU, 24, Color("#ffe9a6"), 1.5, true)
