extends RefCounted
const ANIMATOR := preload("res://scripts/world/character_animator.gd")
const GAME := preload("res://scripts/game/game_controller.gd")
const REPLICA := preload("res://scripts/network/world_replica.gd")
const EFFECT := preload("res://scripts/world/skill_effect.gd")
var tree: SceneTree
var save: Node

func run(test_tree: SceneTree) -> void:
	tree = test_tree
	save = tree.root.get_node("SaveManager")
	_test_joint_poses()
	_test_final_escort()
	await _test_battle_animation()
	await _test_victory_rewards()
	print("PASS: six articulated characters, actual attacks and skill effects, melee boss escorts, boss music and paginated expedition loot")

func _fresh() -> void:
	save.data = save.DEFAULT_SAVE.duplicate(true)
	save._initialize_progression(false)

func _settle() -> void:
	for frame in 10:
		await tree.process_frame

func _dispose(game: Node) -> void:
	tree.paused = false
	game.queue_free()
	await _settle()
	tree.root.get_node("AudioManager").stop_all()

func _test_joint_poses() -> void:
	for owner in ANIMATOR.LAYERS:
		var idle := ANIMATOR.pose(owner, {"time": 0.0})
		var walking := ANIMATOR.pose(owner, {"time": 0.12, "moving": 1.0})
		assert(is_zero_approx(float(idle.left_leg)) and is_zero_approx(float(idle.right_leg)))
		assert(absf(float(walking.left_leg)) > 0.1 and is_equal_approx(float(walking.left_leg), -float(walking.right_leg)), "Walking articulates opposite legs")
		var attack := ANIMATOR.pose(owner, {"time": 0.0, "attacking": true, "attack_progress": 0.6, "attack_serial": 1})
		assert(absf(float(attack.weapon)) > 0.01, "Every class moves its actual weapon")
		assert(float(ANIMATOR.pose(owner, {"facing": Vector2.LEFT}).side) == -1.0)
		for texture in ANIMATOR.LAYERS[owner].values():
			assert(texture is Texture2D and texture.get_size() == Vector2(480, 600))
	var left := ANIMATOR.pose("assassin", {"attacking": true, "attack_progress": 0.6, "attack_serial": 1})
	var right := ANIMATOR.pose("assassin", {"attacking": true, "attack_progress": 0.6, "attack_serial": 2})
	assert(float(left.left_weapon) * float(right.left_weapon) < 0.0, "Daggers alternate")

func _test_final_escort() -> void:
	for region in ContentCatalog.MAP_ORDER:
		var stage: MapData = CampaignRules.expedition(str(region), 1, 0)
		var director := WaveDirector.new()
		director.configure(stage)
		assert(not director.melee_escort_pool.is_empty())
		director.start()
		director.wave = 4
		director.time_in_wave = stage.duration / 4.0 - 0.02
		director.spawn_clock = 0.0
		var spawned: Array[StringName] = []
		var bosses: Array[StringName] = []
		director.spawn_requested.connect(func(kind: StringName, _wave: int) -> void: spawned.append(kind))
		director.boss_summoned.connect(func(kind: StringName) -> void: bosses.append(kind))
		director._process(0.03)
		assert(director.wave == 5 and bosses.size() == 1 and spawned.size() == 10, "Six arrival escorts plus a four-monster pack")
		for index in 9:
			var data: EnemyData = ContentCatalog.enemies[str(spawned[index])]
			assert(data.attack_style == &"melee" and not ChaserEnemy.AREA_CASTERS.has(str(data.id)))
		director.free()

func _test_battle_animation() -> void:
	_fresh()
	var audio: Node = tree.root.get_node("AudioManager")
	assert(audio.boss_stream != null and audio.boss_stream.loop)
	for owner in ContentCatalog.CLASS_ORDER:
		var game := GAME.new()
		game.player_class = str(owner)
		tree.root.add_child(game)
		game.wave_director.stop()
		game.phase_director.set_process(false)
		game.set_process(false)
		var enemy: ChaserEnemy = game.enemy_manager.spawn(&"slime", 1, Vector2(65, 0))
		enemy.set_physics_process(false)
		enemy.health = 100000
		enemy.max_health = 100000
		game.enemy_manager._process(1.0)
		game._try_basic_attack()
		assert(game.player.attack_serial == 1 and game.player.attack_time > 0.0)
		var row: Dictionary = REPLICA._row(game.player, "P", "P1")
		assert(row.v.attack_serial == 1 and row.v.attack_duration > 0)
		game._cast_special("glacial_ring", 2)
		game._cast_special("roots_snare", 2)
		game._cast_special("sunfire", 2)
		assert(tree.get_nodes_in_group("skill_effect").size() >= 3)
		for effect in tree.get_nodes_in_group("skill_effect"):
			var packet: Dictionary = REPLICA._row(effect, "F", str(effect.get_instance_id()))
			assert(packet.v.kind == effect.kind and packet.v.radius == effect.radius)
		for kind in ["frost", "fire", "holy", "roots", "summon", "blades", "shadow", "arrows", "void", "time", "taunt", "starfall", "arcane"]:
			game._spawn_skill(Vector2.ZERO, kind, 100.0, Color.CYAN)
		await _settle()
		game._on_boss_summoned(game.map_data.boss_id)
		assert(game.boss_music_active and audio.music_player.stream == audio.boss_stream and audio.music_player.playing)
		var playback: float = audio.music_player.get_playback_position()
		game._set_boss_music(true)
		assert(audio.music_player.get_playback_position() >= playback, "Snapshots never restart the boss track")
		game.boss.take_hit(game.boss.max_health + 1)
		assert(not game.boss_music_active and not audio.music_player.playing)
		await _dispose(game)

func _test_victory_rewards() -> void:
	_fresh()
	var game := GAME.new()
	tree.root.add_child(game)
	game.wave_director.stop()
	game.phase_director.set_process(false)
	game.set_process(false)
	var previous_size: Vector2i = tree.root.size
	var previous_scale: Vector2i = tree.root.content_scale_size
	for value in range(2, 7):
		game._on_level_up(value)
	assert(game.run_items.size() == 5)
	game._on_boss_summoned(game.map_data.boss_id)
	game.boss.take_hit(game.boss.max_health + 1)
	assert(game.run_finished and game.run_items.size() == 6)
	var rewards: Control = game.result_layer.find_child("RunRewards", true, false)
	assert(rewards != null and rewards.items.size() == 6)
	for entry in rewards.items:
		assert(save.data.equipment.has(str(entry.id)))
	var encountered: Array[String] = []
	while true:
		for card in rewards.cards.get_children():
			encountered.append(str(card.get_meta("equipment_id")))
		if rewards.next.disabled:
			break
		rewards.next.pressed.emit()
	assert(encountered.size() == 6 and rewards.cards.get_child_count() <= 2)
	for resolution in [Vector2i(1280, 720), Vector2i(800, 600), Vector2i(640, 360), Vector2i(390, 844)]:
		tree.root.size = resolution
		tree.root.content_scale_size = resolution
		await _settle()
		var viewport: Control = game.result_layer.get_child(1)
		var rect: Rect2 = viewport.content.get_global_rect()
		assert(rect.position.x >= 0.0 and rect.position.y >= 0.0 and rect.end.x <= resolution.x + 1 and rect.end.y <= resolution.y + 1, "Victory and every loot page fit the window")
		assert(game.result_layer.find_children("*", "ScrollContainer", true, false).is_empty())
		for card in rewards.cards.get_children():
			assert(not card.tooltip_text.is_empty() and card.find_children("*", "Control", true, false).size() > 0)
	tree.root.size = previous_size
	tree.root.content_scale_size = previous_scale
	await _dispose(game)
