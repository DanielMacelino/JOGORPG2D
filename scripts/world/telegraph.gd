extends Node2D

var radius := 96.0
var damage := 15.0
var duration := 1.1
var elapsed := 0.0
var player: SurvivorPlayer
var enemies: Array[ChaserEnemy] = []
var fired := false
var lingering := false
var pulse_clock := 0.0
var player_team := false

func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()
	if elapsed >= duration and not fired:
		fired = true
		_damage_targets()
		pulse_clock = 1.0
	if lingering and fired:
		pulse_clock -= delta
		if pulse_clock <= 0.0:
			pulse_clock = 1.0
			_damage_targets()
	if elapsed >= duration + (3.2 if lingering else 0.23):
		queue_free()

func _damage_targets() -> void:
	if player_team: return
	if NetworkSession.running and NetworkSession.hosting:
		for candidate in get_tree().get_nodes_in_group("survivor_player"):
			if not candidate.is_dead and global_position.distance_to(candidate.global_position) <= radius:
				candidate.take_damage(damage, true, self)
	elif is_instance_valid(player) and global_position.distance_to(player.global_position) <= radius:
		player.take_damage(damage, true, self)

func _draw() -> void:
	var progress := clampf(elapsed / duration, 0.0, 1.0)
	var pulse := 0.13 + 0.2 * progress
	draw_arc(Vector2.ZERO, radius + 2, 0, TAU, 48, Color("#24101d", 0.95), 6.0, true)
	draw_circle(Vector2.ZERO, radius, Color("#ff536c", pulse))
	draw_arc(Vector2.ZERO, radius, 0, TAU, 48, Color("#ffd1bb", 0.80), 1.5, true)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU * progress, 44, Color("#ff8490", 0.9), 3.0, true)
	if fired:
		if lingering:
			draw_circle(Vector2.ZERO, radius, Color("#b96861", 0.20 + sin(elapsed * 7.0) * 0.05))
			draw_arc(Vector2.ZERO, radius * 0.82, 0.0, TAU, 40, Color("#ffc196", 0.75), 2.0, true)
		else:
			draw_circle(Vector2.ZERO, radius, Color("#ffe3c1", 0.19 * (1.0 - (elapsed - duration) / 0.23)))
