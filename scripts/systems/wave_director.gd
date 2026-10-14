extends Node
class_name WaveDirector

signal wave_changed(wave: int)
signal spawn_requested(kind: StringName, wave: int)
signal boss_summoned(boss_id: StringName)

const WAVES_BEFORE_BOSS := 4
var wave := 0
var time_in_wave := 0.0
var spawn_clock := 0.0
var boss_spawned := false
var match_time := 0.0
var active := false
var rng := RandomNumberGenerator.new()
var map_data: MapData
var melee_escort_pool: Array[StringName] = []

func configure(stage: MapData) -> void:
	map_data = stage
	melee_escort_pool.clear()
	if stage == null:
		return
	for kind in stage.enemy_pool:
		var enemy: EnemyData = ContentCatalog.enemies.get(str(kind))
		if enemy != null and enemy.attack_style == &"melee" and not ChaserEnemy.AREA_CASTERS.has(str(kind)) and not enemy.boss and not enemy.elite:
			melee_escort_pool.append(kind)

func start() -> void:
	rng.randomize()
	wave = 1
	time_in_wave = 0.0
	spawn_clock = 0.25
	match_time = 0.0
	boss_spawned = false
	active = true
	wave_changed.emit(wave)

func stop() -> void:
	active = false

func _process(delta: float) -> void:
	if not active:
		return
	match_time += delta
	if wave <= WAVES_BEFORE_BOSS:
		time_in_wave += delta
		var wave_duration := map_data.duration / float(WAVES_BEFORE_BOSS) if map_data != null else 36.0
		if time_in_wave >= wave_duration:
			time_in_wave -= wave_duration
			wave += 1
			wave_changed.emit(wave)
			if wave == WAVES_BEFORE_BOSS + 1:
				boss_spawned = true
				boss_summoned.emit(map_data.boss_id if map_data != null else &"goblin_king")
				var escort_count := 6
				if NetworkSession.running and NetworkSession.hosting:
					escort_count += 2 * (NetworkSession.players.size() - 1)
				for member in escort_count:
					spawn_requested.emit(_roll_boss_melee(), wave)
	# The final escort is mainly melee; keep ranged and area tells readable.
	var interval := maxf(0.55, 1.20 - float(wave) * 0.13)
	var density := maxf(0.70, 1.0 - float(map_data.phase_number - 1) * 0.015 - float(map_data.difficulty_tier) * 0.025) if map_data != null else 1.0
	interval *= density
	if boss_spawned:
		interval = 1.4 * density
	spawn_clock -= delta
	if spawn_clock <= 0.0:
		spawn_clock = interval * rng.randf_range(0.82, 1.18)
		var pack_size := 4 if boss_spawned else mini(8, 2 + wave)
		if NetworkSession.running and NetworkSession.hosting:
			pack_size += NetworkSession.players.size() - 1
		if not boss_spawned and map_data != null:
			if map_data.encounter in [&"horde", &"siege"]:
				pack_size += 1
			elif map_data.encounter in [&"altar", &"rifts"]:
				pack_size = maxi(3, pack_size - 1)
		for member in pack_size:
			spawn_requested.emit(_roll_boss_melee() if boss_spawned and member < pack_size - 1 else _roll_enemy(), wave)

func _roll_boss_melee() -> StringName:
	if melee_escort_pool.is_empty():
		return &"slime"
	return melee_escort_pool[rng.randi_range(0, melee_escort_pool.size() - 1)]

func _roll_enemy() -> StringName:
	if map_data == null or map_data.enemy_pool.is_empty():
		return &"slime"
	var phase := map_data.phase_number
	# Conjurers threaten a location rather than chasing; their marked areas reward movement.
	if wave >= 2 and rng.randf() < (0.16 if phase < 5 else 0.23):
		for kind in map_data.enemy_pool:
			if ChaserEnemy.AREA_CASTERS.has(str(kind)):
				return kind
	if wave >= 3 and rng.randf() < (0.015 if wave == 3 else 0.028) + float(phase - 1) * 0.002:
		return map_data.elite_id
	# Introduce the map's faster and ranged species as the encounter develops.
	var available := mini(map_data.enemy_pool.size(), wave + 1 + floori(float(phase - 1) / 3.0))
	if rng.randf() < 0.58 - float(phase - 1) * 0.018:
		available = mini(2, available)
	return map_data.enemy_pool[rng.randi_range(0, available - 1)]
