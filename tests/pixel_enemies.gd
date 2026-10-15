extends RefCounted
const SPRITES := preload("res://scripts/data/pixel_enemy_sprites.gd")

func run(tree: SceneTree) -> void:
	var save: Node = tree.root.get_node("SaveManager")
	var old: Dictionary = save.data.duplicate(true)
	save.data = save.DEFAULT_SAVE.duplicate(true)
	save._initialize_progression(false)
	for kind in SPRITES.LAYOUTS:
		var sheet: Texture2D = SPRITES.texture_for(kind)
		var image := sheet.get_image()
		assert(image.detect_alpha() != Image.ALPHA_NONE)
		for action in ["idle", "walk", "attack"]:
			var sequence: Vector2i = SPRITES.LAYOUTS[kind][action]
			for index in sequence.y:
				var rect := SPRITES.frame_rect(kind, action, index)
				assert(Rect2(Vector2.ZERO, sheet.get_size()).encloses(rect))
				assert(image.get_region(Rect2i(rect)).get_used_rect().has_area(), "%s %s %s is empty" % [kind, action, index])
		var actor: ChaserEnemy = load("res://scenes/enemies/pixel_enemy.tscn").instantiate()
		actor.configure(ContentCatalog.enemies[kind], null, 4)
		var sprite: Sprite2D = actor.get_node("PixelSprite")
		sprite.pose(StringName(kind), 0.3, 1.0, 0.0, Vector2.LEFT, 0.0, 1.0)
		var walking := sprite.region_rect
		assert(sprite.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST and sprite.flip_h)
		assert(is_equal_approx(sprite.scale.x, float(SPRITES.LAYOUTS[kind].scale)) and sprite.scale.x == sprite.scale.y)
		sprite.pose(StringName(kind), 0.3, 0.0, 0.12, Vector2.RIGHT, 0.1, 1.0)
		assert(not sprite.flip_h and sprite.self_modulate.r > 1.0 and sprite.region_rect != walking)
		actor.free()
	for region in ContentCatalog.MAP_ORDER:
		var stage := CampaignRules.expedition(str(region), 10, 0)
		assert(stage.enemy_pool.has(&"red_orb") and stage.enemy_pool.has(&"barrel_beast"))
		var director := WaveDirector.new()
		stage.duration = 4
		director.configure(stage)
		var chest_waves: Array[int] = []
		var bosses: Array[StringName] = []
		director.spawn_requested.connect(func(kind: StringName, wave: int) -> void:
			if kind == &"loot_mimic": chest_waves.append(wave))
		director.boss_summoned.connect(func(kind: StringName) -> void: bosses.append(kind))
		director.start()
		for step in 6: director._process(1.01)
		assert(chest_waves == [4] and bosses == [stage.boss_id])
		director.wave = 2
		var kinds := {}
		for roll in 1000: kinds[str(director._roll_enemy())] = true
		assert(kinds.has("red_orb") and kinds.has("barrel_beast") and not kinds.has("loot_mimic"))
		director.free()
	assert(CampaignRules.expedition("verdant_reach", 9, 0).boss_id == &"goblin_king")
	assert(CampaignRules.expedition("verdant_reach", 10, 0).boss_id == &"minotaur")
	assert(CampaignRules.expedition("hollow_cairn", 10, 0).boss_id == &"death_lord")
	var game: ExpeditionGame = load("res://scenes/game.tscn").instantiate()
	game.phase_number = 10
	tree.root.add_child(game)
	game.wave_director.stop()
	game.phase_director.set_process(false)
	game.enemy_manager.clear()
	var chest := game.enemy_manager.spawn(&"loot_mimic", 4, Vector2(200, 0))
	chest.set_physics_process(false)
	assert(chest.data.elite and not chest.data.boss and chest.has_node("PixelSprite"))
	chest.take_hit(chest.health + chest.defense + 1)
	assert(not game.run_finished and game.mimic_loot_awarded and game.run_items.size() == 1)
	var item := str(game.run_items[0].id)
	var count: int = save.equipment_quantity(item)
	assert(ContentCatalog.equipment[item].class_id in [&"", &"warrior"])
	game._award_mimic_loot(Vector2.ZERO)
	assert(game.run_items.size() == 1 and save.equipment_quantity(item) == count)
	assert(save.grant_equipment_drop(item, game.drop_receipt + ":loot_mimic") == OK)
	assert(save.equipment_quantity(item) == count)
	save.load_game()
	assert(save.equipment_quantity(item) == count)
	var boss := game.enemy_manager.spawn_boss(game.map_data.boss_id, 5)
	boss.set_physics_process(false)
	var brain: Node = boss.get_node("BossBrain")
	brain.set_process(false)
	assert(boss.kind == &"minotaur" and brain.sovereign and brain.patterns().size() >= 3)
	brain.attack_index = 1
	assert(brain.patterns()[0].shape == "ring")
	await tree.process_frame
	game.queue_free()
	await tree.process_frame
	save.data = old
	save.save_game()
	TalentManager.set_class(str(old.selected_class))
	print("PASS: fourteen transparent pixel sheets, valid animated frames/nearest/anchors, reusable Sprite2D scenes, additional creatures, one wave-4 mimic, immediate persisted class loot/no duplicate, phase-10 Minotaur and sovereign attacks")
