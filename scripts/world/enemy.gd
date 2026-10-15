extends CharacterBody2D
class_name ChaserEnemy
const AREA_CASTERS := ["mage", "dark_mage", "crypt_wisp", "fire_witch", "blood_mage", "frost_shaman", "spore_shaman"]
signal spell_requested(position: Vector2, radius: float, damage: float, target: SurvivorPlayer)
const ART := preload("res://scripts/ui/enemy_portrait.gd")
const PIXELS := preload("res://scripts/data/pixel_enemy_sprites.gd")

signal defeated(enemy: ChaserEnemy)
signal damage_received(amount: float)
signal attack_requested(damage: float, position: Vector2, target: SurvivorPlayer)
signal projectile_requested(position: Vector2, direction: Vector2, damage: float, color: Color, target: SurvivorPlayer)
signal boss_telegraph(position: Vector2, radius: float, damage: float, target: SurvivorPlayer)

var data: EnemyData
var kind := &"slime"
var player: SurvivorPlayer
var provoked_by: SurvivorPlayer
var provoke_clock := 0.0
var focus_clock := 0.0
var health := 30.0
var max_health := 30.0
var damage := 8.0
var speed := 55.0
var defense := 0.0
var xp_reward := 5
var gold_reward := 1
var attack_range := 34.0
var hit_cooldown := 0.0
var special_clock := 3.0
var hit_flash := 0.0
var slow_amount := 0.0
var slow_clock := 0.0
var dead := false
var wave_scale := 1.0
var animation_time := 0.0
var moving_blend := 0.0
var spawn_time := 0.0
var attack_time := 0.0
var attack_direction := Vector2.RIGHT
var rng := RandomNumberGenerator.new()
var burn_damage := 0.0
var burn_remaining := 0.0
var burn_clock := 1.0
var objective_target: Node2D

func configure(enemy_data: EnemyData, target: SurvivorPlayer, current_wave: int, stage_difficulty: float = 1.0) -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	collision_layer = 0
	collision_mask = 0
	data = enemy_data
	kind = data.id
	if PIXELS.has_kind(kind) and get_node_or_null("PixelSprite") == null:
		var sprite := preload("res://scripts/world/pixel_enemy_sprite.gd").new()
		sprite.name = "PixelSprite"
		add_child(sprite)
	player = target
	wave_scale = 1.0 + float(maxi(0, current_wave - 1)) * 0.12
	max_health = data.max_health * wave_scale * stage_difficulty * 1.15
	if data.boss:
		max_health = data.max_health * stage_difficulty * 13.5
	health = max_health
	damage = data.damage * 1.70 * (1.0 + float(maxi(0, current_wave - 1)) * 0.10) * (1.0 + (stage_difficulty - 1.0) * 0.45)
	speed = data.speed * 1.12 * (1.0 + minf(0.25, float(maxi(0, current_wave - 1)) * 0.035))
	defense = data.defense
	xp_reward = data.xp
	gold_reward = data.gold
	attack_range = data.attack_range
	rng.seed = randi()
	hit_cooldown = rng.randf_range(0.2, 0.85)
	special_clock = rng.randf_range(2.6, 4.2)
	animation_time = rng.randf_range(0.0, TAU)
	queue_redraw()

func _physics_process(delta: float) -> void:
	spawn_time += delta
	attack_time = maxf(0.0, attack_time - delta)
	provoke_clock = maxf(0.0, provoke_clock - delta)
	focus_clock -= delta
	if focus_clock <= 0.0:
		focus_clock = 0.35
		_refresh_target()
	if dead or not is_instance_valid(player) or player.is_dead:
		return
	if burn_remaining > 0.0:
		burn_remaining -= delta
		burn_clock -= delta
		if burn_clock <= 0.0:
			burn_clock += 1.0
			take_hit(burn_damage, false, false)
			if dead:
				return
	hit_cooldown = maxf(0.0, hit_cooldown - delta)
	hit_flash = maxf(0.0, hit_flash - delta)
	slow_clock = maxf(0.0, slow_clock - delta)
	if slow_clock <= 0.0:
		slow_amount = 0.0
	animation_time += delta
	if is_instance_valid(objective_target) and provoke_clock <= 0.0:
		_process_objective_target(delta)
		return
	var to_player := player.global_position - global_position
	var distance := to_player.length()
	var direction := to_player.normalized() if distance > 0.01 else Vector2.ZERO
	if attack_time <= 0.0: attack_direction = direction
	var ranged := data.attack_style == &"ranged"
	var target_distance := attack_range
	if ranged:
		target_distance = data.attack_range
	if not data.boss and AREA_CASTERS.has(str(kind)):
		special_clock -= delta
		if special_clock <= 0.0 and distance < 410.0:
			special_clock = 5.8
			play_attack(direction)
			spell_requested.emit(player.global_position, 74.0, damage * 1.1, player)
	if distance > target_distance:
		velocity = direction.rotated(sin(animation_time * 0.7 + float(get_instance_id() % 17)) * 0.13) * speed * (1.0 - slow_amount)
		moving_blend = move_toward(moving_blend, 1.0, delta * 5.0)
		move_and_slide()
	else:
		velocity = -direction * speed * 0.62 * (1.0 - slow_amount) if ranged and distance < 145.0 else Vector2.ZERO
		if not velocity.is_zero_approx():
			move_and_slide()
		moving_blend = move_toward(moving_blend, 0.0, delta * 6.0)
		if hit_cooldown <= 0.0:
			hit_cooldown = rng.randf_range(1.35, 1.9) if ranged else (0.85 if data.boss else 1.0)
			play_attack(direction)
			if ranged:
				projectile_requested.emit(global_position, direction, damage, data.projectile_color, player)
			else:
				attack_requested.emit(damage, global_position, player)
	queue_redraw()

func play_attack(direction: Vector2) -> void:
	attack_direction = direction
	attack_time = 0.24
	queue_redraw()

func provoke(target: SurvivorPlayer, duration: float) -> void:
	if is_instance_valid(target) and not target.is_dead:
		provoked_by = target
		provoke_clock = maxf(provoke_clock, duration)
		player = target

func _refresh_target() -> void:
	if provoke_clock > 0.0 and is_instance_valid(provoked_by) and not provoked_by.is_dead:
		player = provoked_by
		return
	var best_score := INF
	var best: SurvivorPlayer
	for candidate in get_tree().get_nodes_in_group("survivor_player"):
		if candidate is SurvivorPlayer and candidate.get_parent() == get_parent() and not candidate.is_dead:
			var score: float = candidate.threat_score(global_position)
			if score < best_score:
				best_score = score
				best = candidate
	if best != null:
		player = best

func apply_slow(amount: float, duration: float) -> void:
	slow_amount = maxf(slow_amount, clampf(amount, 0.0, 0.8) * (0.45 if data.boss else 1.0))
	slow_clock = maxf(slow_clock, duration)

func apply_burn(amount: float, duration: float) -> void:
	if amount <= 0.0 or dead:
		return
	burn_damage = maxf(burn_damage, amount)
	burn_remaining = maxf(burn_remaining, duration)

func _process_objective_target(delta: float) -> void:
	var toward := objective_target.global_position - global_position
	moving_blend = move_toward(moving_blend, 1.0 if toward.length() > 46.0 else 0.0, delta * 6.0)
	if toward.length() > 46.0:
		global_position += toward.normalized() * speed * (1.0 - slow_amount) * delta
	elif hit_cooldown <= 0.0 and objective_target.has_method("take_damage"):
		hit_cooldown = 1.2
		play_attack(toward.normalized())
		objective_target.take_damage(damage * 0.65)
	queue_redraw()

func take_hit(incoming: float, critical: bool = false, knockback: bool = true) -> void:
	if dead:
		return
	var actual := maxf(1.0, incoming - defense)
	damage_received.emit(minf(maxf(health, 0.0), actual))
	health -= actual
	hit_flash = 0.15
	_show_damage(actual, critical)
	if knockback and not data.boss and is_instance_valid(player):
		global_position += (global_position - player.global_position).normalized() * (3.0 if data.elite else 9.0)
	if health <= 0.0:
		dead = true
		defeated.emit(self)
	queue_redraw()

func play_death() -> void:
	if not is_inside_tree():
		return
	collision_layer = 0
	collision_mask = 0
	var death_tween := create_tween()
	death_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	death_tween.set_parallel(true)
	death_tween.tween_property(self, "scale", Vector2(0.62, 0.18), 0.26).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	death_tween.tween_property(self, "modulate:a", 0.0, 0.24).set_ease(Tween.EASE_IN)
	death_tween.tween_property(self, "rotation", rotation + 0.22, 0.24).set_ease(Tween.EASE_IN)
	death_tween.chain().tween_callback(queue_free)

func _show_damage(amount: float, critical: bool) -> void:
	if not is_inside_tree() or get_tree().get_nodes_in_group("damage_popup").size() >= 32:
		return
	if not critical and not data.elite and not data.boss and rng.randf() > 0.3:
		return
	var popup := preload("res://scripts/world/floating_text.gd").new()
	popup.text = str(roundi(amount)) if not critical else str(roundi(amount)) + "!"
	popup.color = Color("#ffe28a") if critical else Color("#fff0dc")
	popup.scale = Vector2.ONE * (1.28 if critical else 1.0)
	popup.position = global_position + Vector2(rng.randf_range(-11.0, 11.0), -28)
	get_parent().add_child(popup)
	popup.add_to_group("damage_popup")

func _draw() -> void:
	var pixel_sprite := get_node_or_null("PixelSprite")
	if pixel_sprite != null:
		pixel_sprite.pose(kind, animation_time, moving_blend, attack_time, attack_direction, hit_flash, spawn_time)
		var radius := 35.0 if data.boss else (22.0 if data.elite else 17.0)
		draw_arc(Vector2(0, 4), radius, 0, TAU, 32, Color("#f5ba78", 0.6), 1.2, true)
		if data.elite or data.boss:
			var top := -94.0 if data.boss else -60.0
			if data.boss and PIXELS.has_kind(kind):
				top = minf(top, -PIXELS.foot_for(str(kind), "idle", 0).y * float(PIXELS.LAYOUTS[str(kind)].scale) - 12.0)
			var bar := Rect2(-radius, top, radius * 2, 4)
			draw_rect(bar.grow(1), Color("#071914"))
			draw_rect(Rect2(bar.position, Vector2(bar.size.x * clampf(health / maxf(1, max_health), 0, 1), bar.size.y)), Color("#efaf79"))
		return
	var bob := sin(animation_time * (11.0 if moving_blend > 0.1 else 2.7)) * (1.5 * moving_blend + 0.45)
	var sway := sin(animation_time * 7.0) * 0.025 * moving_blend
	var strike := sin((1.0 - attack_time / 0.24) * PI) if attack_time > 0.0 else 0.0
	var arrival := clampf(spawn_time / 0.35, 0.0, 1.0)
	var growth := 0.75 + 0.25 * sin(arrival * PI / 2.0)
	draw_set_transform(Vector2(0, bob) + attack_direction * strike * 5.0, sway + strike * attack_direction.x * 0.07, Vector2(growth, growth))
	var footprint := 66.0 if data != null and data.boss else (40.0 if data != null and data.elite else 28.0)
	var texture: Texture2D = ART.PORTRAITS.get(str(data.art_id if data != null and data.art_id != &"" else kind), ART.PORTRAITS.goblin)
	var rect := Rect2(-footprint * 0.5, -footprint * 0.95, footprint, footprint * 1.25)
	for offset in [Vector2(-1.2, 0), Vector2(1.2, 0), Vector2(0, -1.2), Vector2(0, 1.2)]:
		draw_texture_rect(texture, Rect2(rect.position + offset, rect.size), false, Color("#09141b"))
	draw_arc(Vector2(0, 6), footprint * 0.45, 0, TAU, 24, Color("#ffb095", 0.65), 1.2, true)
	draw_texture_rect(texture, Rect2(-footprint * 0.5, -footprint * 0.95, footprint, footprint * 1.25), false, Color(1.6, 1.6, 1.6) if hit_flash > 0 else Color.WHITE)
	if has_meta("objective_elite"):
		draw_arc(Vector2(0, 8), footprint * 0.56, 0, TAU, 32, Color("#ffe0a0"), 2.2, true)
		var mark := Vector2(0, -65)
		draw_colored_polygon(PackedVector2Array([mark + Vector2(0, -5), mark + Vector2(5, 0), mark + Vector2(0, 5), mark + Vector2(-5, 0)]), Color("#ffe0a0"))
	if burn_remaining > 0.0:
		for index in 3:
			draw_circle(Vector2(footprint * 0.3 + index * 3, -10 - index * 5), 2.2, Color("#ffc382", 0.9))
	if data != null and (data.elite or data.boss):
		var width := 46.0 if data.boss else 34.0
		var y := -76.0 if data.boss else -54.0
		draw_rect(Rect2(-width * 0.5 - 1, y - 1, width + 2, 5), Color("#09141b"))
		draw_rect(Rect2(-width * 0.5, y, width * clampf(health / maxf(1, max_health), 0, 1), 3), Color("#ff9f87"))
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

