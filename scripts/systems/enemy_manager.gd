extends Node
class_name EnemyManager

signal enemy_died(enemy: ChaserEnemy)
signal player_hit(damage: float, position: Vector2, target: SurvivorPlayer)
signal enemy_shot(position: Vector2, direction: Vector2, damage: float, color: Color, target: SurvivorPlayer)
signal boss_attack(position: Vector2, radius: float, damage: float, target: SurvivorPlayer)
signal enemy_spell(position: Vector2, radius: float, damage: float, target: SurvivorPlayer)
signal damage_dealt(amount: float)
signal boss_pattern(spec: Dictionary)
signal boss_enraged

const MAX_ENEMIES := 144
const CELL_SIZE := 128.0

var world: Node2D
var player: SurvivorPlayer
var enemies: Array[ChaserEnemy] = []
var rng := RandomNumberGenerator.new()
var map_data: MapData
var spatial_cells: Dictionary = {}
var spatial_clock := 0.0
var damage_source: SurvivorPlayer

func configure(world_root: Node2D, target: SurvivorPlayer, stage: MapData = null) -> void:
	world = world_root
	player = target
	map_data = stage
	rng.randomize()

func spawn(kind: StringName, wave: int, forced_position := Vector2.INF) -> ChaserEnemy:
	var enemy_data: EnemyData = ContentCatalog.enemies.get(str(kind), ContentCatalog.enemies.get("slime"))
	if enemies.size() >= MAX_ENEMIES and not enemy_data.boss and kind != &"loot_mimic":
		return null
	var sovereign := enemy_data.boss and map_data != null and map_data.phase_number == 10
	if sovereign:
		enemy_data = enemy_data.duplicate() as EnemyData
		enemy_data.display_name += " · Soberano"
	var enemy: ChaserEnemy = preload("res://scenes/enemies/pixel_enemy.tscn").instantiate() if preload("res://scripts/data/pixel_enemy_sprites.gd").has_kind(kind) else preload("res://scripts/world/enemy.gd").new()
	enemy.configure(enemy_data, player, wave, map_data.difficulty if map_data != null else 1.0)
	# Later regions cannot carry first-region fragile fodder into one-hit clears by fresh heroes.
	if map_data != null and map_data.stage_index >= 1 and not enemy_data.boss:
		var health_floor := (90.0 + 30.0 * float(map_data.stage_index - 1)) * enemy.wave_scale * CampaignRules.strength(map_data.difficulty_tier, map_data.phase_number)
		enemy.max_health = maxf(enemy.max_health, health_floor)
		enemy.health = enemy.max_health
	if enemy_data.boss and map_data != null and map_data.phase_number == 5:
		enemy.max_health *= 1.6
		enemy.health = enemy.max_health
	if sovereign:
		enemy.max_health *= 2.8
		enemy.health = enemy.max_health
		enemy.damage *= 1.30
		enemy.speed *= 1.08
	if NetworkSession.running and NetworkSession.hosting:
		var party_size := clampi(NetworkSession.players.size(), 1, 4)
		enemy.max_health *= 1.0 + 0.80 * (party_size - 1)
		enemy.health = enemy.max_health
		enemy.damage *= (1.0 + 0.08 * (party_size - 1)) * party_damage_pressure(party_size)
	var collision := CollisionShape2D.new()
	var body_shape := CircleShape2D.new()
	if enemy_data.boss:
		body_shape.radius = 33.0
	elif enemy_data.elite:
		body_shape.radius = 21.0
	else:
		body_shape.radius = 15.0
	collision.shape = body_shape
	enemy.add_child(collision)
	if forced_position.is_finite():
		enemy.global_position = forced_position
	else:
		enemy.global_position = _spawn_position()
	enemy.defeated.connect(_on_enemy_defeated)
	enemy.attack_requested.connect(_on_enemy_attack)
	enemy.projectile_requested.connect(_on_enemy_shot)
	enemy.boss_telegraph.connect(_on_boss_attack)
	enemy.spell_requested.connect(func(position: Vector2, radius: float, amount: float, victim: SurvivorPlayer) -> void: enemy_spell.emit(position, radius, amount, victim))
	enemy.damage_received.connect(func(amount: float) -> void: damage_dealt.emit(amount))
	enemy.z_index = 4 if enemy_data.boss else 2
	world.add_child(enemy)
	if enemy_data.boss:
		var brain := preload("res://scripts/systems/boss_brain.gd").new()
		brain.name = "BossBrain"
		brain.actor = enemy
		brain.sovereign = sovereign
		brain.attack_requested.connect(func(spec: Dictionary) -> void: boss_pattern.emit(spec))
		brain.enraged.connect(func() -> void: boss_enraged.emit())
		enemy.add_child(brain)
	enemies.append(enemy)
	_index_enemy(enemy)
	return enemy

static func party_damage_pressure(player_count: int) -> float:
	# Additional damage pressure grows with party size; solo remains unchanged.
	return 1.0 if player_count <= 1 else 1.0 + 0.10 * clampi(player_count, 2, 4)

func _process(delta: float) -> void:
	spatial_clock -= delta
	if spatial_clock > 0.0:
		return
	spatial_clock = 0.1
	spatial_cells.clear()
	for enemy in enemies:
		if is_instance_valid(enemy) and not enemy.dead:
			_index_enemy(enemy)

func _index_enemy(enemy: ChaserEnemy) -> void:
	var cell := Vector2i(floori(enemy.global_position.x / CELL_SIZE), floori(enemy.global_position.y / CELL_SIZE))
	if not spatial_cells.has(cell):
		spatial_cells[cell] = []
	spatial_cells[cell].append(enemy)

func nearby(position: Vector2, radius: float) -> Array[ChaserEnemy]:
	var result: Array[ChaserEnemy] = []
	# Expand by one cell for the maximum movement between grid refreshes.
	var min_cell := Vector2i(floori((position.x - radius - 28.0) / CELL_SIZE), floori((position.y - radius - 28.0) / CELL_SIZE))
	var max_cell := Vector2i(floori((position.x + radius + 28.0) / CELL_SIZE), floori((position.y + radius + 28.0) / CELL_SIZE))
	for x in range(min_cell.x, max_cell.x + 1):
		for y in range(min_cell.y, max_cell.y + 1):
			var cell_enemies: Array = spatial_cells.get(Vector2i(x, y), [])
			for enemy in cell_enemies:
				if is_instance_valid(enemy) and not enemy.dead:
					result.append(enemy)
	return result

func spawn_boss(kind: StringName, wave: int) -> ChaserEnemy:
	return spawn(kind, wave)

func living_enemies() -> Array[ChaserEnemy]:
	var result: Array[ChaserEnemy] = []
	for enemy in enemies:
		if is_instance_valid(enemy) and not enemy.dead:
			result.append(enemy)
	return result

func _spawn_position() -> Vector2:
	var direction := Vector2.RIGHT.rotated(rng.randf_range(0.0, TAU))
	var p := player.global_position + direction * rng.randf_range(440.0, 620.0)
	p.x = clampf(p.x, -1200.0, 1200.0)
	p.y = clampf(p.y, -830.0, 830.0)
	if p.distance_to(player.global_position) < 280.0:
		p = player.global_position - direction * 370.0
	return p

func _on_enemy_defeated(enemy: ChaserEnemy) -> void:
	enemy_died.emit(enemy)
	enemies.erase(enemy)
	enemy.play_death()

func _on_enemy_attack(damage: float, position: Vector2, target: SurvivorPlayer) -> void:
	player_hit.emit(damage, position, target)

func _on_enemy_shot(position: Vector2, direction: Vector2, damage: float, color: Color, target: SurvivorPlayer) -> void:
	enemy_shot.emit(position, direction, damage, color, target)

func _on_boss_attack(position: Vector2, radius: float, damage: float, target: SurvivorPlayer) -> void:
	boss_attack.emit(position, radius, damage, target)

func clear() -> void:
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	enemies.clear()
	spatial_cells.clear()
