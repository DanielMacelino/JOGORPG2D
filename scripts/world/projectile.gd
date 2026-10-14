extends Node2D

var direction := Vector2.RIGHT
var speed := 450.0
var damage := 10.0
var player_team := true
var magic := false
var splash_radius := 0.0
var lifetime := 2.2
var elapsed := 0.0
var color := Color("#e5d38d")
var enemies: Array[ChaserEnemy] = []
var enemy_manager: EnemyManager
var player: SurvivorPlayer
var source_player: SurvivorPlayer
var critical := false
var pierce_left := 0
var hit_ids: Dictionary = {}
var spent := false
var bounces_left := 0
var burn_on_hit := 0.0
var chill_on_hit := 0.0
var rng := RandomNumberGenerator.new()
var trail_points: Array[Vector2] = []

func _ready() -> void:
	set_meta("team", "players" if player_team else "enemies")
	if player_team and get_parent().has_method("configure_projectile"):
		get_parent().configure_projectile(self)
	add_to_group("friendly_projectile" if player_team else "hostile_projectile")

func _process(delta: float) -> void:
	if spent:
		return
	elapsed += delta
	var previous_position := global_position
	trail_points.append(global_position)
	if trail_points.size() > 7:
		trail_points.pop_front()
	global_position += direction.normalized() * speed * delta
	if player_team:
		var candidates: Array[ChaserEnemy] = enemy_manager.nearby(global_position, 36.0 + speed * delta) if is_instance_valid(enemy_manager) else enemies.duplicate()
		for enemy in candidates:
			if not is_instance_valid(enemy) or enemy.dead or hit_ids.has(enemy.get_instance_id()):
				continue
			var hit_radius := 34.0 if enemy.data.boss else 23.0
			if _segment_distance_squared(enemy.global_position, previous_position, global_position) <= hit_radius * hit_radius:
				hit_ids[enemy.get_instance_id()] = true
				_deal_hit(enemy, damage, critical)
				if not enemy.dead:
					enemy.apply_burn(damage * burn_on_hit, 3.0)
					if chill_on_hit > 0.0:
						enemy.apply_slow(chill_on_hit, 2.0)
				if splash_radius > 0.0:
					var splash_targets: Array[ChaserEnemy] = enemy_manager.nearby(global_position, splash_radius) if is_instance_valid(enemy_manager) else enemies.duplicate()
					var splash_hits := 0
					for other in splash_targets:
						if is_instance_valid(other) and not other.dead and other != enemy and global_position.distance_squared_to(other.global_position) <= splash_radius * splash_radius:
							_deal_hit(other, damage * 0.68)
							splash_hits += 1
							if splash_hits >= 14:
								break
				if bounces_left > 0 and _ricochet(enemy.global_position):
					queue_redraw()
					return
				if pierce_left <= 0:
					_add_burst()
					return
				pierce_left -= 1
	else:
		if NetworkSession.running and NetworkSession.hosting:
			for candidate in get_tree().get_nodes_in_group("survivor_player"):
				if not candidate.is_dead and _segment_distance_squared(candidate.global_position, previous_position, global_position) < 18.0 * 18.0:
					candidate.take_damage(damage, false, self)
					_add_burst()
					return
			player = null
		if is_instance_valid(player) and _segment_distance_squared(player.global_position, previous_position, global_position) < 18.0 * 18.0:
			player.take_damage(damage, false, self)
			_add_burst()
			return
	if elapsed >= lifetime:
		queue_free()
	queue_redraw()

func _deal_hit(enemy: ChaserEnemy, amount: float, crit: bool = false) -> void:
	var previous: SurvivorPlayer = enemy_manager.damage_source if is_instance_valid(enemy_manager) else null
	if is_instance_valid(enemy_manager) and is_instance_valid(source_player):
		enemy_manager.damage_source = source_player
	enemy.take_hit(amount, crit)
	if is_instance_valid(enemy_manager):
		enemy_manager.damage_source = previous

func _ricochet(origin: Vector2) -> bool:
	var next: ChaserEnemy
	var distance := 240.0 * 240.0
	var candidates: Array[ChaserEnemy] = enemy_manager.nearby(origin, 240.0) if is_instance_valid(enemy_manager) else enemies.duplicate()
	for candidate in candidates:
		if not is_instance_valid(candidate) or candidate.dead or hit_ids.has(candidate.get_instance_id()):
			continue
		var squared := origin.distance_squared_to(candidate.global_position)
		if squared < distance:
			distance = squared
			next = candidate
	if next == null:
		return false
	bounces_left -= 1
	direction = (next.global_position - origin).normalized()
	global_position = origin + direction * 24.0
	damage *= 0.80
	lifetime += 0.4
	return true

func _segment_distance_squared(point: Vector2, start: Vector2, end: Vector2) -> float:
	var segment := end - start
	var weight := clampf((point - start).dot(segment) / maxf(segment.length_squared(), 0.001), 0.0, 1.0)
	return point.distance_squared_to(start + segment * weight)

func _add_burst() -> void:
	spent = true
	if splash_radius > 0.0 and get_tree().get_nodes_in_group("combat_burst").size() < 18:
		var burst := preload("res://scripts/world/burst_effect.gd").new()
		burst.radius = splash_radius
		burst.color = color
		burst.global_position = global_position
		get_parent().add_child(burst)
		burst.add_to_group("combat_burst")
	queue_free()

func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE * 0.78)
	for index in range(1, trail_points.size()):
		var progress := float(index) / float(trail_points.size())
		var alpha := progress * (0.3 if magic else 0.17)
		var width := (1.0 + progress * (4.5 if magic else 2.0))
		draw_line(to_local(trail_points[index - 1]), to_local(trail_points[index]), Color(color, alpha), width, true)
	if magic:
		var pulse := 1.0 + sin(elapsed * 24.0) * 0.1
		draw_circle(Vector2.ZERO, 6.3 * pulse, Color("#08141e", 0.92))
		draw_circle(Vector2.ZERO, 8.5 * pulse, Color(color, 0.14))
		draw_arc(Vector2.ZERO, 7.0 * pulse, elapsed * 1.9, elapsed * 1.9 + PI * 1.45, 20, Color(color.lightened(0.35), 0.82), 1.4, true)
		draw_circle(Vector2.ZERO, 4.2 * pulse, color)
		draw_circle(Vector2(-1, -1), 1.4, Color.WHITE)
	else:
		draw_line(-direction.normalized() * 12.0, direction.normalized() * 5.0, Color("#08141e"), 5.5, true)
		draw_line(-direction.normalized() * 11.0, direction.normalized() * 4.0, color, 3.0, true)
		draw_circle(Vector2.ZERO, 2.5, Color.WHITE)
