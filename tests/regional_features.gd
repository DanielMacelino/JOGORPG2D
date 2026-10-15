extends RefCounted
var tree: SceneTree
var save: Node
var catalog: Node

func run(scene_tree: SceneTree) -> void:
	tree = scene_tree
	save = tree.root.get_node("SaveManager")
	catalog = tree.root.get_node("ContentCatalog")
	_test_drops()
	await _test_equipment_effects()
	await _test_objectives()
	await _test_bosses()
	await _test_home()
	await _test_room_layout()
	await _test_records_navigation()
	await _test_choice_resize()

func _test_records_navigation() -> void:
	_fresh()
	save.data.bestiary_kills = {"wolf": 3, "slime": 1, "legacy_unknown": 99}
	save.data.achievements = {"first_blood": true}
	save.data.completed_bounties = ["bounty_wolf"]
	var main = load("res://scenes/main.tscn").instantiate()
	tree.root.add_child(main)
	main._build_page("records")
	for frame in 5: await tree.process_frame
	var records: Control = main.page_root.find_child("RecordsScreen", true, false)
	assert(records.cards.get_child(0).progress_current == 2)
	assert(records.cards.get_child(1).progress_current == 1)
	assert(records.cards.get_child(2).progress_current == 1)
	assert(records.cards.get_child(0).progress_total == catalog.enemies.size())
	assert(main.backdrop_layer.get_child(0).records)
	for page in ["bestiary", "achievements", "bounties", "statistics"]:
		records = main.page_root.find_child("RecordsScreen", true, false)
		records.cards.get_node("Record_" + page).pressed.emit()
		assert(main.page_name == page and not main.backdrop_layer.get_child(0).records)
		main._go_back()
		assert(main.page_name == "records")
		for frame in 5: await tree.process_frame
	main.queue_free()
	await tree.process_frame
	print("PASS: illustrated Records cards, real discovery/achievement/hunt counts, four destinations and return navigation")

func _test_choice_resize() -> void:
	var original: Vector2i = tree.root.size
	var original_scale: Vector2i = tree.root.content_scale_size
	var game := _game()
	game.pending_levelups = 1
	game._show_level_choices()
	var modal: Control = game.level_layer
	var screen: Control = modal.find_child("AbilityChoiceScreen", true, false)
	var ids: Array = screen.choices.duplicate()
	for resolution in [Vector2i(1280, 720), Vector2i(800, 600), Vector2i(640, 480), Vector2i(360, 740), Vector2i(320, 640)]:
		tree.root.content_scale_size = resolution
		tree.root.size = resolution
		for frame in 12:
			await tree.process_frame
		assert(game.level_layer == modal and screen.choices == ids, "Resizing must preserve the offered skills")
		assert(modal.find_children("*", "ScrollContainer", true, false).is_empty())
		assert(game.health_text.get_line_count() == 1 and game.xp_text.get_line_count() == 1)
		var vitals: Control = game.ui_root.find_child("BattleVitals", true, false)
		assert(vitals.get_global_rect().end.x <= tree.root.get_visible_rect().size.x, "Vitals must fit narrow windows")
		assert(not game.wave_label.visible and not game.timer_label.visible, "Choice heading must not overlap the wave display")
		if resolution.x < 820: assert(not game.gold_label.visible and not game.skill_label.visible)
	screen.grid.get_child(0).pressed.emit()
	assert(game.level_layer == null and not tree.paused and game.abilities.level_of(StringName(ids[0])) > 0)
	assert(game.wave_label.visible and game.gold_label.visible and game.skill_label.visible, "HUD details must return after choosing")
	await _dispose(game)
	tree.root.content_scale_size = original_scale
	tree.root.size = original
	print("PASS: real solo skill modal preserves offers on desktop/portrait resize, contains no scroll and grants the selected ability")

func _fresh() -> void:
	save.data = save.DEFAULT_SAVE.duplicate(true)
	save._initialize_progression(false)
	tree.root.get_node("TalentManager").set_class("warrior")

func _game(phase: int = 1, owner: String = "warrior", region: String = "verdant_reach") -> Node2D:
	_fresh()
	if not save.is_class_unlocked(owner):
		save.data.gold = 10000
		assert(save.unlock_class(owner))
	for previous in range(1, phase):
		assert(save.complete_phase("verdant_reach", previous, 0))
	var game = load("res://scenes/game.tscn").instantiate()
	game.player_class = owner
	game.phase_number = phase
	game.map_id = region
	tree.root.add_child(game)
	game.set_process(false)
	game.player.set_physics_process(false)
	game.wave_director.set_process(false)
	game.phase_director.set_process(false)
	return game

func _dispose(game: Node) -> void:
	tree.paused = false
	game.queue_free()
	await tree.process_frame
	await tree.process_frame

func _test_drops() -> void:
	var regional := 0
	for item in catalog.equipment.values():
		regional += int(item.region_id != &"" and not item.generated)
	assert(regional == 60)
	var loot = load("res://scripts/systems/loot_manager.gd").new()
	loot.rng.seed = 773
	for region in catalog.MAP_ORDER:
		for owner in catalog.CLASS_ORDER:
			_fresh()
			var found: Array[String] = []
			for index in 5:
				var reward: Dictionary = loot.roll_boss_reward(str(region), str(owner), index + 1)
				var item: EquipmentData = catalog.equipment[reward.equipment]
				assert(item.region_id == region and (item.class_id == &"" or item.class_id == owner))
				assert(not found.has(str(item.id)), "Prefer undiscovered regional drops")
				found.append(str(item.id))
				save.unlock_equipment(str(item.id), str(owner))
			assert(loot.roll_boss_reward(str(region), str(owner), 10).crystals == 2)
	loot.free()
	print("PASS: 60 regional items, six regions x six class drop pools, discoveries and final-stage crystals")

func _equip(id: String, owner: String) -> void:
	save.unlock_equipment(id, owner)
	var item: EquipmentData = catalog.equipment[id]
	assert(tree.root.get_node("EquipmentManager").equip(str(item.slot), id, owner))

func _test_equipment_effects() -> void:
	var game = _game(1, "ranger")
	_equip("hollow_cairn_ranger", "ranger")
	_equip("hollow_cairn_signet", "ranger")
	game.player.configure("ranger", {})
	assert(game.player.projectile_bounces == 2)
	var first: ChaserEnemy = game.enemy_manager.spawn(&"goblin", 1, Vector2(60, 0))
	var second: ChaserEnemy = game.enemy_manager.spawn(&"goblin", 1, Vector2(160, 0))
	for enemy in [first, second]:
		enemy.health = 1000
		enemy.max_health = 1000
		enemy.set_physics_process(false)
	var shot = load("res://scripts/world/projectile.gd").new()
	shot.enemy_manager = game.enemy_manager
	shot.speed = 400
	shot.damage = 10
	game.add_child(shot)
	shot.set_process(false)
	shot._process(0.2)
	assert(is_equal_approx(first.health, 990) and shot.bounces_left == 1)
	shot._process(0.2)
	assert(is_equal_approx(second.health, 992), "Ricochet deals 80% damage to another actual monster")
	_equip("ember_crater_signet", "ranger")
	_equip("frostwood_charm", "ranger")
	game.player.configure("ranger", {})
	assert(is_equal_approx(game.player.burn_on_hit, 0.18) and is_equal_approx(game.player.chill_on_hit, 0.22))
	first.apply_burn(5.0, 3.0)
	first.apply_slow(game.player.chill_on_hit, 2.0)
	var before: float = first.health
	first._physics_process(1.0)
	assert(is_equal_approx(first.health, before - 5.0) and first.slow_amount > 0)
	save.load_game()
	assert(str(save.loadout_for("ranger").ring) == "ember_crater_signet")
	await _dispose(game)
	game = _game(1, "druid")
	_equip("sunken_mire_druid", "druid")
	_equip("sunken_mire_charm", "druid")
	game.player.configure("druid", {})
	assert(is_equal_approx(game.player.summon_duration, 7.0) and is_equal_approx(game.player.summon_damage_pct, 0.25))
	game.summon_clock = 0
	game._process(0.01)
	assert(tree.get_nodes_in_group("forest_companion").size() == 2)
	for companion in tree.get_nodes_in_group("forest_companion"):
		assert(companion.kind == "rootling" and is_equal_approx(companion.remaining, 23.0))
	await _dispose(game)
	print("PASS: equipped ricochet, burn, slow, duration and summon damage; effects persist with class loadouts")

func _test_objectives() -> void:
	for region in catalog.MAP_ORDER:
		var titles: Array[String] = []
		for phase in range(1, 11):
			var data := CampaignRules.expedition(str(region), phase, 0)
			assert(not titles.has(data.phase_title) and not CampaignRules.phase_objective(phase).is_empty())
			titles.append(data.phase_title)
	var game = _game(3)
	game._on_boss_summoned(game.map_data.boss_id)
	game.boss.take_hit(game.boss.max_health + 1)
	assert(not game.run_finished and save.data.crystals == 0, "Boss loot is withheld until the objective is complete")
	for index in 3:
		game.phase_director._process(23)
		for enemy in game.enemy_manager.living_enemies():
			if enemy.has_meta("objective_elite"):
				enemy.take_hit(enemy.health + 1)
	assert(game.run_finished and game.phase_director.kills == 3 and save.phase_completed("verdant_reach", 3, 0))
	assert(save.data.crystals > 0 and game.reward_banked)
	await _dispose(game)
	game = _game(4)
	game.phase_director._process(13)
	var invader: ChaserEnemy = game.enemy_manager.enemies[0]
	var altar: Node2D = game.phase_director.altar
	invader.position = altar.position + Vector2(40, 0)
	invader.hit_cooldown = 0
	var health: float = altar.health
	invader._physics_process(0.1)
	assert(altar.health < health, "Raiders actually attack the altar")
	altar.take_damage(altar.max_health + 1)
	assert(game.run_finished and not save.phase_completed("verdant_reach", 4, 0))
	await _dispose(game)
	game = _game(5)
	for rift in game.phase_director.rifts:
		game.player.position = rift.position
		rift._process(1.7)
	assert(game.phase_director.objective_complete() and game.phase_director.sealed_count == 3)
	game._on_boss_summoned(game.map_data.boss_id)
	game.boss.take_hit(game.boss.max_health + 1)
	assert(save.phase_completed("verdant_reach", 5, 0))
	await _dispose(game)
	for phase in [2, 8, 9, 10]:
		game = _game(phase)
		game.phase_director._process(13)
		assert(not game.enemy_manager.enemies.is_empty() if phase != 8 else not tree.get_nodes_in_group("danger_area").is_empty())
		await _dispose(game)
	print("PASS: ten distinct phase titles per region; hunts, altar failure, rift sealing, hordes, anomalies and reward gates")

func _test_bosses() -> void:
	var signatures: Array[String] = []
	for region in catalog.MAP_ORDER:
		var game = _game(1, "warrior", str(region))
		game._on_boss_summoned(game.map_data.boss_id)
		game.boss.set_physics_process(false)
		var brain = game.boss.get_node("BossBrain")
		brain.set_process(false)
		var signature := ""
		for turn in 2:
			brain.attack_index = turn
			for spec in brain.patterns():
				signature += "%s:%s:%s:%s;" % [spec.shape, spec.radius, spec.get("inner", 0), spec.get("count", 0)]
				game._on_boss_pattern(spec)
				var pattern: Node2D = game.get_child(game.get_child_count() - 1)
				pattern.set_process(false)
				if spec.shape == "ring":
					assert(not pattern.contains_point(pattern.position), "Ring centers are safe")
					assert(pattern.contains_point(pattern.position + Vector2((float(spec.radius) + float(spec.inner)) * 0.5, 0)))
				elif spec.shape == "line":
					assert(pattern.contains_point((pattern.position + Vector2(spec.end)) * 0.5))
				elif spec.shape == "fan":
					var previous := tree.get_nodes_in_group("hostile_projectile").size()
					pattern._process(1.3)
					assert(tree.get_nodes_in_group("hostile_projectile").size() == previous + int(spec.count))
		assert(not signatures.has(signature), "Every boss has a distinct attack signature")
		signatures.append(signature)
		game.boss.health = game.boss.max_health * 0.49
		brain._process(0.01)
		assert(brain.second_phase and game.boss_name_label.text.contains("FÚRIA"))
		await _dispose(game)
	print("PASS: six unique boss attack signatures, real volleys, safe ring centers, line hit regions and half-health transitions")

func _test_home() -> void:
	_fresh()
	var original: Vector2i = tree.root.size
	var main = load("res://scenes/main.tscn").instantiate()
	tree.root.add_child(main)
	var longest: Array = catalog.abilities.values()
	longest.sort_custom(func(a: AbilityData, b: AbilityData) -> bool: return a.rank_description(5).length() > b.rank_description(5).length())
	for resolution in [Vector2i(1920, 1080), Vector2i(1280, 720), Vector2i(960, 540), Vector2i(800, 600), Vector2i(640, 480), Vector2i(540, 900), Vector2i(390, 844), Vector2i(320, 640)]:
		for scale in [1.0, 1.2]:
			tree.root.size = resolution
			save.data.settings.ui_scale = scale
			main._build_page("home")
			for frame in 10:
				await tree.process_frame
			var home = main.page_root.find_child("HomeScreen", true, false)
			assert(home != null and home.navigation.get_child_count() == 5)
			assert(main.page_root.get_combined_minimum_size().x <= tree.root.get_visible_rect().size.x + 1, "Home must fit the window")
			assert(home.find_child("HomePlay", true, false).size.x <= home.size.x)
			var play: Button = home.find_child("HomePlay", true, false)
			assert(home.find_child("HomePrepare", true, false) == null, "Character preparation belongs to the main Character tile")
			var utilities: Control = home.find_child("HomeUtilities", true, false)
			assert(absf(play.position.x - utilities.position.x) <= 1 and absf(play.size.x - utilities.size.x) <= 1, "Main actions must share alignment and width")
			var gap := utilities.position.y - play.position.y - play.size.y
			assert(gap >= 6 and gap <= 10, "Main actions must stay together")
			var settings: Button = home.find_child("HomeSettings", true, false)
			var online: Button = home.find_child("HomeOnline", true, false)
			assert(settings.get_parent() == online.get_parent() and absf(settings.size.y - online.size.y) <= 1, "Home utility buttons must form one aligned group")
			assert(home.hero_row.size.y - home.copy_column.size.y <= 2, "Hero must not reserve empty vertical space")
			assert(home.find_child("HomeIdentity", true, false).size.y <= 130, "Character details must remain a compact group")
			for tile in home.navigation.get_children():
				assert(tile.size.x > 70 and tile.size.x <= home.size.x)
			main._build_page("prepare")
			for frame in 10:
				await tree.process_frame
			var preparation = main.page_root.find_child("PrepareScreen", true, false)
			assert(preparation != null and preparation.cards.get_child_count() == 6)
			assert(main.page_root.get_combined_minimum_size().x <= tree.root.get_visible_rect().size.x + 1, "Preparation must fit the window")
			for tile in preparation.cards.get_children():
				assert(tile.size.x <= preparation.size.x and tile.size.x >= 160)
				assert(tile.copy_label.position.y + tile.copy_label.get_minimum_size().y <= tile.size.y - 2, "Card descriptions must fit")
			main._build_page("records")
			for frame in 5: await tree.process_frame
			var records: Control = main.page_root.find_child("RecordsScreen", true, false)
			assert(records != null and records.cards.get_child_count() == 4)
			for currency in records.find_children("RecordsCurrency*", "Label", true, false):
				assert(currency.get_line_count() == 1, "Currency labels must never wrap character by character")
			assert(main.page_root.get_combined_minimum_size().x <= tree.root.get_visible_rect().size.x + 1, "Records must fit the window")
			for column in records.cards.columns:
				assert(absf(records.cards.get_child(column).size.x - records.cards.get_child(0).size.x) <= 1, "Record columns must have equal width")
			for tile in records.cards.get_children():
				assert(tile.art != null and tile.size.x <= records.size.x)
				assert(tile.details.get_combined_minimum_size().y <= tile.size.y - 41, "Record card text must fit")
			main._build_page("online")
			for frame in 5:
				await tree.process_frame
			assert(main.page_root.get_combined_minimum_size().x <= tree.root.get_visible_rect().size.x + 1, "Online lobby must fit the window")
			assert(main.page_root.find_child("OnlineAddress", true, false) != null)
			var online_screen: Control = main.page_root.find_child("OnlineScreen", true, false)
			var back_count := 0
			for button in main.page_root.find_children("*", "Button", true, false):
				if button.text.contains("VOLTAR"): back_count += 1
			assert(back_count == 1, "Online page must contain exactly one Back button")
			for label in online_screen.find_children("*", "Label", true, false):
				assert(not label.text.contains("?"), "Online text must preserve accents and symbols")
			assert(online_screen.mode_buttons.size() == 2)
			var character: OptionButton = online_screen.find_child("OnlineClass", true, false)
			for selected in character.item_count:
				character.select(selected)
				character.item_selected.emit(selected)
				assert(online_screen.portrait.class_id == str(character.get_item_metadata(selected)), "Online portrait must follow the selected class")
			for currency in online_screen.find_children("OnlineCurrency*", "Label", true, false):
				assert(currency.get_line_count() == 1, "Online currency labels must not stack letters")
			assert(online_screen.portrait.size.x <= online_screen.size.x)
			assert(main.page_scroll == null, "Online page must not use a scroll container")
			var online_view: Control = main.page_root.find_child("OnlineViewport", true, false)
			assert(online_view.content.get_global_rect().end.y <= online_view.get_global_rect().end.y + 1, "Online content must fit vertically")
			if online_screen.section_switch.visible:
				online_screen.section_switch.get_child(1).pressed.emit()
				for frame in 5: await tree.process_frame
			var modes: TabContainer = online_screen.find_child("OnlineModes", true, false)
			assert(not modes.tabs_visible, "Native tabs must be replaced by the styled mode buttons")
			online_screen.mode_buttons[1].pressed.emit()
			await tree.process_frame
			assert(main.online_draft.tab == 1 and online_screen.find_child("OnlineAddress", true, false).is_visible_in_tree())
			online_screen.mode_buttons[0].pressed.emit()
			await tree.process_frame
			assert(online_screen.find_child("OnlineRegion", true, false).is_visible_in_tree())

			var screen: Control = load("res://scripts/ui/ability_choice_screen.gd").new()
			for index in 3:
				screen.choices.append(str(longest[index].id))
				screen.ranks[longest[index].id] = 4
			screen.reward_text = "RELÍQUIA ENCONTRADA · Martelo do Juramento"
			main.add_child(screen)
			for frame in 12:
				await tree.process_frame
			assert(screen.find_children("*", "ScrollContainer", true, false).is_empty(), "Skill choices must never scroll")
			for card in screen.grid.get_children():
				assert(card.get_global_rect().end.y <= screen.size.y + 1, "Every skill must be visible")
				assert(card.text_content.get_combined_minimum_size().y * card.text_content.scale.y <= card.size.y - card.text_content.position.y - 9, "Skill text must fit: %s %s size=%s text=%s scale=%s" % [resolution, card.ability.id, card.size, card.text_content.get_combined_minimum_size(), card.text_scale])
				assert(card.text_scale >= 0.70, "Skill text must remain legible: %s %s scale=%s card=%s" % [resolution, card.ability.id, card.text_scale, card.size])
			screen.queue_free()
			await tree.process_frame
	save.data.campaign_progress["0"] = 11
	main._build_page("online")
	await tree.process_frame
	var region: OptionButton = main.page_root.find_child("OnlineRegion", true, false)
	region.select(1)
	region.item_selected.emit(1)
	var phase: OptionButton = main.page_root.find_child("OnlinePhase", true, false)
	phase.select(1)
	phase.item_selected.emit(1)
	assert(main.page_name == "online" and main.online_draft.map == "hollow_cairn" and int(main.online_draft.phase) == 2, "Map selection must stay inside online setup")
	var nickname: LineEdit = main.page_root.find_child("OnlineNickname", true, false)
	nickname.text = "Amigos da Véspera"
	nickname.text_changed.emit(nickname.text)
	main._build_page("home")
	main._build_page("online")
	await tree.process_frame
	assert(main.page_root.find_child("OnlineNickname", true, false).text == "Amigos da Véspera" and int(main.online_draft.phase) == 2, "Online setup must survive page navigation and resizing")
	for id in ["warrior", "mage", "ranger", "assassin", "druid", "paladin"]:
		main.selected_class = id
		main._build_page("prepare")
		for frame in 10:
			await tree.process_frame
		var preparation = main.page_root.find_child("PrepareScreen", true, false)
		assert(preparation.class_id == id and preparation.portrait.class_id == id)
	for index in 6:
		main._build_page("prepare")
		await tree.process_frame
		var preparation = main.page_root.find_child("PrepareScreen", true, false)
		var tile: Button = preparation.cards.get_child(index)
		var target: String = tile.page
		tile.pressed.emit()
		assert(main.page_name == target, "Preparation routes must work")
	for index in 5:
		main._build_page("home")
		await tree.process_frame
		var home = main.page_root.find_child("HomeScreen", true, false)
		var tile: Button = home.navigation.get_child(index)
		var page: String = tile.page
		tile.pressed.emit()
		assert(main.page_name == page)
	for page in ["prepare", "records"]:
		main._build_page(page)
		await tree.process_frame
		assert(main.page_root.find_children("*", "Button", true, false).size() >= (7 if page == "prepare" else 5))
	main.selected_class = "warrior"
	main._build_page("home")
	await tree.process_frame
	main.page_root.find_child("HomePlay", true, false).pressed.emit()
	assert(main.active_game != null and main.active_game.phase_number == main.selected_phase)
	main._return_to_menu()
	main.queue_free()
	await tree.process_frame
	tree.root.size = original
	print("PASS: home, preparation, online setup and skill choices at eight resolutions and two text scales; aligned utility buttons, inline maps, persistent drafts and three choices without scrolling")

func _test_room_layout() -> void:
	var session: Node = tree.root.get_node("NetworkSession")
	assert(not session.active)
	var old_players: Dictionary = session.players
	var old_config: Dictionary = session.config
	var old_hosting: bool = session.hosting
	var original_size := tree.root.size
	var original_scale := tree.root.content_scale_size
	var original_ui_scale: float = float(save.data.settings.ui_scale)
	save.data.settings.ui_scale = 1.2
	session.active = true
	session.config = {"map": "verdant_reach", "phase": 1, "tier": 0, "port": 24567}
	for host in [true, false]:
		session.hosting = host
		for count in [1, 2, 4]:
			session.players = {}
			for index in count:
				session.players[index + 1] = {"name": "Viajante %d" % (index + 1), "class": ["warrior", "mage", "ranger", "druid"][index], "stats": {"character_level": index + 1}}
			for resolution in [Vector2i(1280, 720), Vector2i(640, 480), Vector2i(320, 640)]:
				tree.root.size = resolution
				tree.root.content_scale_size = resolution
				var container: Control = load("res://scripts/ui/menu/online_viewport.gd").new()
				container.content = VBoxContainer.new()
				container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
				tree.root.add_child(container)
				var screen: Control = load("res://scripts/ui/menu/online_screen.gd").new()
				screen.draft = {"address": "26.12.34.56"}
				container.content.add_child(screen)
				for frame in 8: await tree.process_frame
				assert(screen.get_combined_minimum_size().x <= resolution.x, "Created room must fit: %s" % resolution)
				assert(container.content.get_global_rect().end.y <= container.get_global_rect().end.y + 1, "Created lobby must fit vertically without scrolling")
				var portraits := screen.find_children("OnlineMemberPortrait*", "Control", true, false)
				assert(portraits.size() == count)
				for index in count:
					assert(portraits[index].class_id == session.players[index + 1].class)
				assert((screen.find_child("OnlineWaitingSlots", true, false) != null) == (count < 4))
				assert(screen.find_child("OnlineRoster", true, false) != null and screen.find_child("OnlineGroupDestination", true, false) != null)
				if host:
					assert(screen.find_child("OnlineStart", true, false).disabled == (count < 2))
				else:
					assert(screen.find_child("OnlineStart", true, false) == null)
					assert(screen.find_child("OnlineAwaitHost", true, false).disabled)
				for label in screen.find_children("*", "Label", true, false):
					assert(not label.text.contains("?"))
				container.queue_free()
				await tree.process_frame
	session.active = false
	session.hosting = old_hosting
	session.players = old_players
	session.config = old_config
	save.data.settings.ui_scale = original_ui_scale
	tree.root.size = original_size
	tree.root.content_scale_size = original_scale
	print("PASS: created lobby shows actual class portraits for 1/2/4 players, vacancies, host controls and client destination at desktop/tablet/phone widths")
