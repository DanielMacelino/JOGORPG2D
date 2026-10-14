extends Node
signal completed
signal failed
const MARKER := preload("res://scripts/world/phase_marker.gd")
var world: Node2D
var stage: MapData
var quota := 0
var kills := 0
var sealed_count := 0
var event_clock := 12.0
var events := 0
var altar: Node2D
var rifts: Array[Node2D] = []
var announced_complete := false

func configure(game: Node2D, map_data: MapData) -> void:
	world = game
	stage = map_data

func _ready() -> void:
	if stage.encounter in [&"hunt", &"siege"]:
		quota = 3 if stage.phase_number == 3 else (5 if stage.phase_number == 6 else 4)
	elif stage.encounter == &"altar":
		altar = MARKER.new()
		altar.player = world.player
		altar.max_health = 600.0 * stage.difficulty
		altar.health = altar.max_health
		altar.position = Vector2(0, -100)
		altar.broken.connect(func() -> void: failed.emit())
		world.add_child(altar)
	elif stage.encounter == &"rifts":
		for point in [Vector2(-240, -170), Vector2(250, -120), Vector2(0, 230)]:
			var rift := MARKER.new()
			rift.kind = "rift"
			rift.player = world.player
			rift.position = point
			rift.sealed.connect(_rift_sealed)
			world.add_child(rift)
			rifts.append(rift)

func _process(delta: float) -> void:
	if world.run_finished:
		return
	event_clock -= delta
	if event_clock > 0.0:
		return
	events += 1
	match stage.encounter:
		&"horde":
			event_clock = 26.0
			_spawn_pack(8 + mini(5, events))
			world._show_notice("MARÉ DA NOITE · UMA NOVA HORDA SE APROXIMA")
		&"hunt", &"siege":
			event_clock = 22.0
			var marked := 0
			for enemy in world.enemy_manager.living_enemies():
				marked += int(enemy.has_meta("objective_elite"))
			if kills + marked < quota:
				var enemy: ChaserEnemy = world.enemy_manager.spawn(stage.elite_id, maxi(1, world.wave_director.wave))
				if enemy != null:
					enemy.set_meta("objective_elite", true)
					world._show_notice("CAÇADA · UM CAMPEÃO MARCADO ENTROU NA ARENA")
			if stage.encounter == &"siege":
				_spawn_pack(8)
		&"altar":
			event_clock = 18.0 if stage.phase_number == 7 else 24.0
			for index in (6 if stage.phase_number == 7 else 4):
				var point: Vector2 = altar.position + Vector2.from_angle(float(index) * TAU / 6.0 + events) * 300.0
				var kind: StringName = stage.enemy_pool[index % mini(3, stage.enemy_pool.size())]
				var enemy: ChaserEnemy = world.enemy_manager.spawn(kind, maxi(1, world.wave_director.wave), point)
				if enemy != null:
					enemy.objective_target = altar
			world._show_notice("DEFENDA O ALTAR · INTERCEPTE OS INVASORES")
		&"rifts":
			event_clock = 14.0
			for rift in rifts:
				if not rift.complete:
					world._on_enemy_spell(rift.position + Vector2(110, 0), 58, 8.0 * stage.difficulty)
		&"anomaly":
			event_clock = 16.0
			for offset in [Vector2(-125, 0), Vector2(125, 0), Vector2(0, 110)]:
				world._on_enemy_spell(world.player.position + offset, 66, 10.0 * stage.difficulty)
			world._show_notice("TEMPESTADE ARCANA · PROCURE UMA PASSAGEM SEGURA")
		&"throne":
			event_clock = 32.0
			world.enemy_manager.spawn(stage.elite_id, maxi(1, world.wave_director.wave))
		_:
			event_clock = 60.0

func _spawn_pack(count: int) -> void:
	for index in count:
		world.enemy_manager.spawn(stage.enemy_pool[index % stage.enemy_pool.size()], maxi(1, world.wave_director.wave))

func record_enemy(enemy: ChaserEnemy) -> void:
	if enemy.has_meta("objective_elite"):
		kills += 1
		_check_complete()

func _rift_sealed() -> void:
	sealed_count += 1
	world.experience.add_experience(12)
	world._show_notice("FENDA SELADA · %d/3" % sealed_count)
	_check_complete()

func _check_complete() -> void:
	if objective_complete() and not announced_complete:
		announced_complete = true
		completed.emit()

func objective_complete() -> bool:
	match stage.encounter:
		&"hunt", &"siege": return kills >= quota
		&"rifts": return sealed_count >= 3
		&"altar": return is_instance_valid(altar) and altar.health > 0.0
	return true

func status() -> String:
	var objective := "Sobreviva às ondas e derrote o guardião."
	match stage.encounter:
		&"hunt", &"siege": objective = "Campeões marcados: %d/%d · Derrote o guardião." % [kills, quota]
		&"altar": objective = "Altar: %d%% de vida · Proteja-o e derrote o guardião." % roundi(altar.health / altar.max_health * 100)
		&"rifts": objective = "Fendas seladas: %d/3 · Entre nos círculos e derrote o guardião." % sealed_count
		&"anomaly": objective = "Desvie da tempestade arcana e derrote o guardião."
		&"throne": objective = "Derrote os campeões e o soberano desta região."
	return "%s · %s" % [stage.phase_title.to_upper(), objective]
