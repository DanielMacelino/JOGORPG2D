extends Node2D
## Temporary allied spirits: they seek monsters, attack, then expire.
const WOLF := preload("res://assets/art/enemies/wolf.svg")
const GUARDIAN := preload("res://assets/art/enemies/mire_titan.svg")
const ROOTLING := preload("res://assets/art/allies/amgguard.png")
var summoner: SurvivorPlayer
var enemy_manager: EnemyManager
var kind := "wolf":
	set(value):
		kind = value
		if is_node_ready(): _sync_visual()
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
var attack_reach := 32.0
var rootling_sprite: Sprite2D

func _ready() -> void:
	full_duration = remaining
	z_index = 3
	add_to_group("forest_companion")
	_sync_visual()

func _sync_visual() -> void:
	# An unreliable delta can deliver the kind after the first position packet.
	# Build the native sprite when that identity arrives as well as on initial spawn.
	if kind == "rootling" and not is_instance_valid(rootling_sprite):
		rootling_sprite = Sprite2D.new()
		rootling_sprite.name = "RootlingSprite"
		rootling_sprite.texture = ROOTLING
		rootling_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		rootling_sprite.region_enabled = true
		rootling_sprite.region_filter_clip_enabled = true
		rootling_sprite.region_rect = Rect2(0, 0, 40, 40)
		rootling_sprite.centered = false
		rootling_sprite.offset = Vector2(-20, -28)
		rootling_sprite.scale = Vector2.ONE * 2.0
		add_child(rootling_sprite)
	if is_instance_valid(rootling_sprite): rootling_sprite.visible = kind == "rootling"

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
	var tree := kind in ["grove_tree", "ancient"]
	var reach := 270.0 if tree else 32.0
	var speed := 335.0 if kind == "wolf" else 255.0
	moving_blend = move_toward(moving_blend, 1.0 if not tree and to_target.length() > reach else 0.0, delta * 7.0)
	if not to_target.is_zero_approx():
		facing = to_target.normalized()
	if not tree and to_target.length() > reach:
		global_position += to_target.normalized() * minf(to_target.length() - 28.0, speed * delta)
	elif is_instance_valid(target) and not target.dead and to_target.length() <= reach and attack_clock <= 0.0:
		attack_time = 0.22
		attack_reach = to_target.length()
		attack_clock = (0.72 if kind in ["wolf", "rootling"] else 1.15) / (1.0 + summoner.summon_speed_pct)
		var multiplier := attack_multiplier()
		if kind == "ancient": multiplier *= 1.0 + summoner.power_damage
		# Excess troop-count bonuses strengthen the bounded army instead of spawning unbounded entities.
		multiplier *= 1.0 + maxf(0.0, float(summoner.summon_count - 4)) * 0.04
		var previous: SurvivorPlayer = enemy_manager.damage_source
		enemy_manager.damage_source = summoner
		target.take_hit(summoner.damage * multiplier * (1.0 + summoner.summon_damage_pct))
		enemy_manager.damage_source = previous
		if kind != "wolf" and is_instance_valid(target) and not target.dead:
			target.apply_slow(0.45 if tree else 0.25, 2.0 if tree else 1.2)
	queue_redraw()

func attack_multiplier() -> float:
	match kind:
		"rootling": return 1.40
		"wolf": return 1.45 + rank * 0.12
		"grove_tree": return 1.25 + rank * 0.20
		"ancient": return 2.4
	return 1.40 + rank * 0.22

func _draw() -> void:
	if kind == "rootling":
		draw_circle(Vector2(0, 3), 24, Color("#102627", 0.8))
		draw_arc(Vector2(0, 3), 22, 0, TAU, 24, Color("#70fff0"), 1.5, true)
		if is_instance_valid(rootling_sprite):
			var frame := clampi(floori((1.0 - attack_time / 0.22) * 8), 0, 7) if attack_time > 0 else floori(animation_time * (9 if moving_blend > 0.1 else 5)) % 8
			rootling_sprite.region_rect = Rect2(frame * 40, 0, 40, 40)
			rootling_sprite.flip_h = facing.x < 0
		_draw_timer(48, -36)
		return
	if kind in ["grove_tree", "ancient"]:
		_draw_tree()
		return
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

func _draw_timer(width: float, height: float) -> void:
	draw_rect(Rect2(-width * 0.5, height, width, 3), Color("#061a1e"))
	draw_rect(Rect2(-width * 0.5, height, width * clampf(remaining / maxf(0.001, full_duration), 0, 1), 3), Color("#70fff0"))

func _draw_tree() -> void:
	var scale_amount := 1.25 if kind == "ancient" else 1.0
	draw_set_transform(Vector2.ZERO, sin(animation_time * 2) * 0.025, Vector2.ONE * scale_amount)
	draw_circle(Vector2(0, 3), 30, Color("#102627", 0.85))
	draw_arc(Vector2(0, 3), 27, 0, TAU, 32, Color("#70fff0"), 1.5, true)
	draw_line(Vector2(-18, 3), Vector2(0, -16), Color("#917451"), 6, true)
	draw_line(Vector2(19, 3), Vector2(0, -16), Color("#917451"), 6, true)
	draw_line(Vector2(0, 0), Vector2(0, -54), Color("#7e6440"), 13, true)
	for branch in [Vector2(-26, -54), Vector2(25, -61), Vector2(-5, -78)]:
		draw_line(Vector2(0, -32), branch, Color("#a08750"), 5, true)
		draw_circle(branch, 20, Color("#245845"))
		draw_circle(branch + Vector2(-4, -5), 14, Color("#5c9f62"))
	draw_circle(Vector2(-4, -42), 2, Color("#aaffdf"))
	draw_circle(Vector2(4, -42), 2, Color("#aaffdf"))
	if attack_time > 0:
		var root := PackedVector2Array([Vector2.ZERO, facing.rotated(0.12) * attack_reach * 0.45, facing * attack_reach])
		draw_polyline(root, Color("#70e7ac", attack_time / 0.22), 4, true)
	_draw_timer(48, -103)
