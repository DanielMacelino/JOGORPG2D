extends RefCounted
const MODELS := preload("res://scripts/data/accessory_models.gd")

func run(tree: SceneTree) -> void:
	var save: Node = tree.root.get_node("SaveManager")
	var previous: Dictionary = save.data.duplicate(true)
	save.data = save.DEFAULT_SAVE.duplicate(true)
	save._initialize_progression(false)
	save.data.gold = 10000
	assert(save.unlock_class("assassin"))
	_test_equipment()
	_test_pools()
	await _test_music_and_powers(tree)
	save.data = previous
	save.save_game()
	tree.root.get_node("AudioManager").stop_all()
	print("PASS MATCH CONTENT: 170 real accessory models, every crop used, class visual pools, three powers per class, distinct school offers, guaranteed class/shared choices, real ranged control/AoE/daggers and quiet match-to-boss music lifecycle")

func _test_equipment() -> void:
	var used := {}
	var image := MODELS.SHEET.get_image()
	var total := 0
	for slot in MODELS.RECTS:
		used[slot] = {}
		for index in MODELS.RECTS[slot].size():
			total += 1
			var texture := MODELS.atlas(slot, index)
			assert(texture.filter_clip and Rect2(Vector2.ZERO, MODELS.SHEET.get_size()).encloses(texture.region))
			var bounds := image.get_region(Rect2i(texture.region)).get_used_rect()
			assert(bounds.size.x > 20 and bounds.size.y > 30, "Empty equipment crop: %s %d" % [slot, index])
	for item in ContentCatalog.equipment.values():
		if item.slot == &"weapon": continue
		var slot := str(item.slot)
		assert(item.accessory_visual >= 0 and item.accessory_visual < MODELS.RECTS[slot].size())
		used[slot][item.accessory_visual] = true
		var texture := MODELS.texture_for(item, str(item.class_id), slot) as AtlasTexture
		assert(texture.atlas == MODELS.SHEET and texture.region == MODELS.RECTS[slot][item.accessory_visual])
	for slot in used: assert(used[slot].size() == MODELS.RECTS[slot].size(), "Every supplied model must be represented: " + slot)
	assert(total == 170)
	for owner in ContentCatalog.CLASS_ORDER:
		for slot in MODELS.RECTS: assert(MODELS.texture_for(null, str(owner), slot) != null)

func _test_pools() -> void:
	var manager := AbilityManager.new()
	manager.rng.seed = 1740
	for owner in ContentCatalog.CLASS_ORDER:
		manager.reset(ContentCatalog.classes[owner].starting_ability, str(owner), 6)
		manager.expedition_level = 30
		var active := 0
		for id in manager.chooseable():
			var ability: AbilityData = ContentCatalog.abilities[str(id)]
			assert(ability.available_to(str(owner)) and not ability.combat_label().is_empty())
			active += int(ability.active_power)
		assert(active >= 3, "Every class can fill its three power slots: " + str(owner))
		for roll in 50:
			var cards := manager.roll_choices()
			assert(cards.size() == 3 and cards[0].active_power and not cards[1].active_power and not cards[1].class_ids.is_empty() and (cards[2].class_ids.is_empty() or manager.level_of(cards[2].id) > 0))
			var schools := {}
			for card in cards:
				assert(card.available_to(str(owner)))
				if card.school_id.is_empty(): continue
				assert(not schools.has(card.school_id))
				schools[card.school_id] = true
		var family := "skill_%s_0_" % owner
		assert(manager.grant(StringName(family + "0")))
		assert(not manager.grant(StringName(family + "1")) and not manager.chooseable().has(StringName(family + "1")))
		assert(manager.grant(StringName(family + "0")) and manager.level_of(StringName(family + "0")) == 2)
		var chosen := 0
		for id in manager.chooseable():
			if ContentCatalog.abilities[str(id)].active_power and manager.grant(id): chosen += 1
			if chosen == 3: break
		assert(manager.active_power_count() == 3)
		for id in manager.chooseable():
			var ability: AbilityData = ContentCatalog.abilities[str(id)]
			assert(not ability.active_power or manager.has_ability(id))
	manager.free()

func _test_music_and_powers(tree: SceneTree) -> void:
	var audio: Node = tree.root.get_node("AudioManager")
	var game: ExpeditionGame = load("res://scenes/game.tscn").instantiate()
	game.player_class = "ranger"
	tree.root.add_child(game)
	game.process_mode = Node.PROCESS_MODE_DISABLED
	game.wave_director.stop()
	game.enemy_manager.clear()
	assert(audio.match_stream != null and audio.match_stream.loop and audio.music_player.playing and audio.music_player.stream == audio.match_stream)
	var fade: Tween = audio.music_fade
	fade.custom_step(1.0)
	assert(is_equal_approx(audio.music_player.volume_db, audio.MATCH_VOLUME_DB) and audio.music_player.volume_db <= -12)
	var playback: float = audio.music_player.get_playback_position()
	audio.match_music(true)
	assert(audio.music_player.get_playback_position() >= playback)
	var first := game.enemy_manager.spawn(&"goblin", 1, Vector2(100, 0))
	var second := game.enemy_manager.spawn(&"goblin", 1, Vector2(140, 10))
	for enemy in [first, second]:
		enemy.health = 10000
		enemy.max_health = 10000
	game.enemy_manager._process(1)
	game._cast_special("arrow_rain", 3)
	assert(first.health < 10000 and second.health < 10000)
	game._cast_special("binding_shot", 2)
	var binding: Node
	for child in game.get_children():
		if child.get_script() == game.PROJECTILE_SCRIPT and child.chill_on_hit > 0: binding = child
	assert(binding != null and binding.source_player == game.player and binding.player_team)
	binding._process(0.4)
	assert(first.slow_clock > 0 and first.slow_amount > 0.35)
	game._set_boss_music(true)
	assert(audio.music_player.stream == audio.boss_stream and audio.music_player.playing)
	game._set_boss_music(false)
	assert(not audio.music_player.playing)
	game.player_class = "assassin"
	game.player.configure("assassin", {})
	game._cast_special("dagger_fan", 2)
	var daggers := 0
	for child in game.get_children():
		if child.get_script() == game.PROJECTILE_SCRIPT and child.source_player == game.player and child.chill_on_hit == 0:
			daggers += 1
	assert(daggers == 5)
	audio.match_music(true)
	game._finish_run(false)
	assert(not audio.music_player.playing)
	game.queue_free()
	await tree.process_frame
