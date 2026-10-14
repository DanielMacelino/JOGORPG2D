extends Node2D
## Temporary allied spirits: they seek monsters, attack, then expire.
const WOLF := preload("res://assets/art/enemies/wolf.svg")
const GUARDIAN := preload("res://assets/art/enemies/mire_titan.svg")
var summoner: SurvivorPlayer
var enemy_manager: EnemyManager
var kind := "wolf"
var remaining := 14.0
var full_duration := 14.0
var attack_clock := 0.0
var animation_time := 0.0
var moving_blend := 0.0
var attack_time := 0.0
var facing := Vector2.RIGHT
var rank := 1
var target: ChaserEnemy
var search_clock := 0.0

func _ready() -> void:
	full_duration = remaining
	z_index = 3
	add_to_group("forest_companion")

func _physics_process(delta: float) -> void:
	remaining -= delta
	animation_time += delta
	attack_time = maxf(0.0, attack_time - delta)
	if remaining <= 0.0 or not is_instance_valid(summoner) or summoner.is_dead or not is_instance_valid(enemy_manager):
		queue_free()
		return
	attack_clock -= delta
	search_clock -= delta
	if search_clock <= 0.0 or not is_instance_valid(target) or target.dead:
		search_clock = 0.25
		target = null
		var best := 560.0 * 560.0
		for enemy in enemy_manager.nearby(global_position, 560.0):
			var distance := global_position.distance_squared_to(enemy.global_position)
			if distance < best:
				best = distance
				target = enemy
	var destination := summoner.global_position + Vector2.from_angle(float(get_instance_id() % 12) * TAU / 12.0) * 58.0
	if is_instance_valid(target) and not target.dead:
		destination = target.global_position
	var to_target := destination - global_position
	var speed := 335.0 if kind == "wolf" else 255.0
	moving_blend = move_toward(moving_blend, 1.0 if to_target.length() > 32.0 else 0.0, delta * 7.0)
	if not to_target.is_zero_approx():
		facing = to_target.normalized()
	if to_target.length() > 32.0:
		global_position += to_target.normalized() * minf(to_target.length() - 28.0, speed * delta)
	elif is_instance_valid(target) and not target.dead and attack_clock <= 0.0:
		attack_time = 0.22
		attack_clock = (0.72 if kind == "wolf" else 1.15) / (1.0 + summoner.summon_speed_pct)
		var multiplier := 0.55 if kind == "wolf" else (0.65 + rank * 0.10)
		if kind == "ancient":
			multiplier = 1.15
		var previous: SurvivorPlayer = enemy_manager.damage_source
		enemy_manager.damage_source = summoner
		target.take_hit(summoner.damage * multiplier * (1.0 + summoner.summon_damage_pct))
		enemy_manager.damage_source = previous
		if kind != "wolf" and is_instance_valid(target) and not target.dead:
			target.apply_slow(0.25, 1.2)
	queue_redraw()

func _draw() -> void:
	var texture: Texture2D = WOLF if kind == "wolf" else GUARDIAN
	var bounds := Vector2(30, 36) if kind == "wolf" else Vector2(34, 45)
	if kind == "ancient":
		bounds *= 1.4
	var extent := texture.get_size() * minf(bounds.x / texture.get_width(), bounds.y / texture.get_height())
	var stride := sin(animation_time * 12.0) * moving_blend
	var strike := sin((1.0 - attack_time / 0.22) * PI) if attack_time > 0.0 else 0.0
	var bob := -absf(stride) * 2.2
	draw_set_transform(facing * strike * 7.0, stride * 0.05, Vector2(1.0 + absf(stride) * 0.04, 1.0 - absf(stride) * 0.04))
	draw_circle(Vector2(0, 3), extent.x * 0.55, Color("#102627", 0.85))
	draw_arc(Vector2(0, 3), extent.x * 0.5, 0, TAU, 24, Color("#70fff0"), 2.0, true)
	var rect := Rect2(Vector2(-extent.x * 0.5, -extent.y + 10 + bob), extent)
	for offset in [Vector2(-1, 0), Vector2(1, 0)]:
		draw_texture_rect(texture, Rect2(rect.position + offset, rect.size), false, Color("#062221"))
	draw_texture_rect(texture, rect, false, Color("#b1ffd6"))
	# A shrinking turquoise timer separates summoned allies from hostile monsters.
	draw_rect(Rect2(-extent.x * 0.4, -extent.y - 2, extent.x * 0.8, 3), Color("#061a1e"))
	draw_rect(Rect2(-extent.x * 0.4, -extent.y - 2, extent.x * 0.8 * clampf(remaining / full_duration, 0, 1), 3), Color("#70fff0"))
