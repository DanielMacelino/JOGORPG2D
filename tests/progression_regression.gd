extends SceneTree
## The harness uses separate user storage; no player save is changed.
var save: Node
var catalog: Node
var talents: Node
var spawn_count := 0

func _initialize() -> void:
	call_deferred("_run")

func _fresh() -> void:
	save.data = save.DEFAULT_SAVE.duplicate(true)
	save._initialize_progression(false)
	talents.set_class("warrior")

func _run() -> void:
	assert(str(ProjectSettings.get_setting("application/config/name")).begins_with("Ashenwild Regression"), "Use the isolated harness")
	save = root.get_node("SaveManager")
	catalog = root.get_node("ContentCatalog")
	talents = root.get_node("TalentManager")
	await _test_menu_audio()
	await load("res://tests/player_reset.gd").new().run(self)
	await load("res://tests/network_motion.gd").new().run(self)
	_test_migration()
	_test_unlocks()
	_test_tree()
	_test_campaign()
	_test_damage_and_recovery()
	await load("res://tests/content_expansion.gd").new().run(self)
	await load("res://tests/animation_update.gd").new().run(self)
	await _test_class_abilities()
	await _test_summons_and_threat()
	await _test_expeditions()
	await load("res://tests/transmutation.gd").new().run(self)
	await load("res://tests/relics_screen.gd").new().run(self)
	await load("res://tests/upgrades_screen.gd").new().run(self)
	await load("res://tests/characters_screen.gd").new().run(self)
	await load("res://tests/forge_workbench.gd").new().run(self)
	await load("res://tests/inventory_mastery_powers.gd").new().run(self)
	await _test_inventory()
	await _test_ability_labels()
	await _test_menus()
	await load("res://tests/button_responsiveness.gd").new().run(self)
	await load("res://tests/talent_constellations.gd").new().run(self)
	await load("res://tests/session_polish.gd").new().run(self)
	await load("res://tests/regional_features.gd").new().run(self)
	root.get_node("AudioManager").stop_all()
	# The audio mixer drains in wall-clock time even when headless frames run quickly.
	var audio_drain_until := Time.get_ticks_msec() + 300
	while Time.get_ticks_msec() < audio_drain_until:
		await process_frame
	print("PASS: circular class trees, character levels, 60-stage campaigns, difficulty cycles, powers and menus")
	quit()

func _test_migration() -> void:
	var legacy := {"gold": 4321, "crystals": 9, "progression_version": 1, "selected_class": "mage", "account_xp": 3456, "allocated_talents": ["origin", "fury_stem_1"], "settings": {"ui_scale": 1.15}, "unlocked_maps": ["verdant_reach", "hollow_cairn"], "completed_maps": ["verdant_reach"]}
	var file := FileAccess.open(save.SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy))
	file.close()
	save.load_game()
	assert(save.data.gold == 4321 and save.data.crystals == 9)
	assert(is_equal_approx(float(save.data.settings.ui_scale), 1.15))
	assert(talents.character_xp("mage") == 3456 and talents.character_xp("warrior") == 0)
	assert(talents.allocated("mage") == talents.ROOTS, "Old tree points are refunded")
	assert(save.campaign_cleared(0) == 10 and save.phase_unlocked("hollow_cairn", 1, 0))
	save.load_game()
	assert(talents.character_xp("mage") == 3456, "Migration cannot duplicate XP")
	assert(save.campaign_cleared(0) == 10)
	print("PASS: old currencies, settings, XP and completed regions; migration idempotent")

func _test_unlocks() -> void:
	_fresh()
	for id in ["assassin", "druid", "paladin"]:
		assert(not save.unlock_class(id, "gold"))
		var data: ClassData = catalog.classes[id]
		save.data.gold = data.cost_gold
		assert(save.unlock_class(id, "gold"))
		assert(save.data.gold == 0 and str(save.loadout_for(id).weapon) == str(data.starter_weapon))
		assert(not save.unlock_class(id, "gold"))
		assert(talents.character_level(id) == 1)
	_fresh()
	save.data.crystals = catalog.classes.assassin.cost_crystals
	assert(save.unlock_class("assassin", "crystals"))
	assert(save.data.crystals == 0)
	assert(not save.unlock_class("missing", "gold"))

func _test_tree() -> void:
	_fresh()
	for target in catalog.CLASS_ORDER:
		assert(talents.trees[str(target)].size() == 193 * 6)
		for category in talents.TREE_ORDER:
			var tree: Dictionary = talents.subtrees[str(target)][category]
			assert(tree.size() == 193)
			var root_id: String = talents.root_id(category)
			var visited: Array = [root_id]
			var pending: Array = [root_id]
			var cost := 0
			var keystones := 0
			var powers := 0
			while not pending.is_empty():
				var current := str(pending.pop_front())
				for neighbor in tree[current].parents:
					assert(tree.has(str(neighbor)) and tree[str(neighbor)].parents.has(current), "Paths stay inside one tree and are bidirectional")
					if not visited.has(str(neighbor)):
						visited.append(str(neighbor))
						pending.append(str(neighbor))
			assert(visited.size() == 193, "Every tree connects all 193 nodes to its center")
			for node in tree.values():
				cost += int(node.cost)
				keystones += int(node.keystone)
				powers += int(node.power)
				assert(str(node.branch) == category)
			assert(cost == 216 and keystones == 6)
			assert(powers == (1 if category == "technique" else 0))
	talents.set_tree("fury")
	var first: String = talents.node_id(1, 0, "fury")
	assert(talents.points() == 1 and not talents.allocate(talents.node_id(2, 0, "fury")))
	assert(talents.allocate(first))
	talents.set_tree("vigor")
	assert(talents.points() == 0, "The six trees share the character's points")
	assert(not talents.allocate(talents.node_id(1, 0, "vigor")))
	var trained = load("res://scripts/world/player.gd").new()
	talents.set_class("mage")
	trained.configure("warrior", {})
	assert(talents.points() == 1 and not talents.is_allocated(first), "Classes remain isolated")
	var boosted_damage: float = trained.damage
	talents.set_class("warrior")
	talents.refund_all()
	var base = load("res://scripts/world/player.gd").new()
	base.configure("warrior", {})
	assert(boosted_damage > base.damage, "Combat sums all trees regardless of the viewed class/category")
	trained.free()
	base.free()
	save.record_run(3, 10, 90.0, 180, "warrior")
	assert(talents.character_level("warrior") > 1 and talents.character_level("mage") == 1)
	assert(not talents.allocate(talents.node_id(8, 0, "technique")))
	var xp: int = talents.character_xp("warrior")
	save.load_game()
	assert(talents.character_xp("warrior") == xp)
	var max_xp := 0
	for level in range(1, talents.MAX_LEVEL): max_xp += talents.level_cost(level)
	save.data.class_progression.warrior.xp = max_xp
	talents.set_tree("technique")
	while talents.points() > 0:
		var advanced := false
		for id in talents.nodes:
			if talents.can_allocate(str(id)):
				assert(talents.allocate(str(id)))
				advanced = true
		assert(advanced)
	assert(talents.tree_allocated("technique") == 192 and talents.spent_points() == 216)
	assert(talents.allocated().size() == 198 and talents.bonuses().class_power)
	talents._validate_allocations()
	assert(talents.tree_allocated("technique") == 192)
	talents.refund_tree("technique")
	assert(talents.points() == 216 and talents.allocated().size() == 6)
	# Schema migration resets old nodes exactly once while preserving XP and currencies.
	var old_gold: int = save.data.gold
	save.data.talent_schema = 2
	save.data.class_progression.warrior.talents = ["origin", "r1_00", "r2_00"]
	save._initialize_progression(false)
	assert(talents.allocated().size() == 6 and talents.points() == 216)
	assert(talents.character_xp() == max_xp and save.data.gold == old_gold)
	assert(talents.allocate(talents.node_id(1, 0, "general")))
	save.save_game()
	save.load_game()
	assert(talents.is_allocated(talents.node_id(1, 0, "general")), "Reload must not refund new progress again")
	talents.set_tree("general")
	print("PASS: 6 classes x 6 independent connected 193-node trees, shared points, class isolation, actual bonuses, powers, refunds and one-time save migration")

func _test_campaign() -> void:
	_fresh()
	assert(save.phase_unlocked("verdant_reach", 1, 0))
	assert(not save.complete_phase("verdant_reach", 2, 0), "Cannot skip phases")
	assert(not save.complete_phase("verdant_reach", 1, 1), "Cannot skip difficulties")
	assert(not save.complete_phase("missing", 1, 0))
	assert(not save.complete_phase("verdant_reach", 0, 0))
	assert(not save.complete_phase("verdant_reach", 11, 0))
	for tier in range(8):
		assert(save.campaign_cleared(tier) == 0)
		for ordinal in CampaignRules.TOTAL_PHASES:
			var map_id: String = catalog.MAP_ORDER[floori(float(ordinal) / 10.0)]
			var phase := ordinal % 10 + 1
			assert(save.complete_phase(map_id, phase, tier))
			assert(save.campaign_cleared(tier) == ordinal + 1)
			assert(save.complete_phase(map_id, phase, tier))
			assert(save.campaign_cleared(tier) == ordinal + 1, "Repeats cannot skip ahead")
			if ordinal < 59:
				assert(int(save.data.highest_difficulty) == tier)
		assert(int(save.data.highest_difficulty) == tier + 1)
		assert(save.phase_unlocked("verdant_reach", 1, tier + 1))
	assert(CampaignRules.difficulty_name(0) == "Fácil")
	assert(CampaignRules.difficulty_name(6) == "Deus")
	assert(CampaignRules.difficulty_name(7) == "Deus II")
	assert(CampaignRules.difficulty_name(8) == "Deus III")
	assert(CampaignRules.strength(1, 1) > CampaignRules.strength(0, 1))
	assert(CampaignRules.strength(2, 10) > CampaignRules.strength(2, 1))
	var base: MapData = catalog.maps.verdant_reach
	var later := CampaignRules.expedition("verdant_reach", 10, 1)
	assert(later.difficulty > base.difficulty and base.phase_number == 1, "Runtime map clones must not alter catalog")
	save.load_game()
	assert(int(save.data.highest_difficulty) == 8 and save.campaign_cleared(7) == 60)
	print("PASS: 60 phases per difficulty, repeats, gates, 8 cycles and saved campaign")

func _grant_power(class_id: String) -> void:
	var xp := 0
	for level in range(1, 40):
		xp += talents.level_cost(level)
	save.data.class_progression[class_id].xp = xp
	talents.set_class(class_id)
	for ring in range(1, 9):
		assert(talents.allocate(talents.node_id(ring, 0, "technique")))
	assert(talents.bonuses(class_id).class_power)

func _test_class_abilities() -> void:
	assert(catalog.classes.warrior.max_health > catalog.classes.paladin.max_health * 2)
	assert(catalog.classes.warrior.damage < catalog.classes.assassin.damage)
	assert(catalog.classes.mage.max_health == catalog.classes.ranger.max_health)
	assert(catalog.classes.ranger.damage == catalog.classes.assassin.damage)
	assert(catalog.classes.ranger.attack_cooldown <= 0.25 and catalog.classes.assassin.attack_cooldown <= 0.25)
	assert(catalog.classes.ranger.speed > catalog.classes.mage.speed)
	assert(catalog.classes.mage.damage > catalog.classes.paladin.damage and catalog.classes.mage.attack_range > 400)
	for class_id in catalog.CLASS_ORDER:
		_fresh()
		if not save.is_class_unlocked(str(class_id)):
			save.data.gold = 10000
			assert(save.unlock_class(str(class_id)))
		var game = load("res://scenes/game.tscn").instantiate()
		game.player_class = str(class_id)
		root.add_child(game)
		game.set_process(false)
		game.wave_director.set_process(false)
		game.player.set_physics_process(false)
		var pool: Array[StringName] = game.abilities.chooseable()
		var exclusive := 0
		for id in pool:
			var ability: AbilityData = catalog.abilities[str(id)]
			assert(ability.available_to(str(class_id)) and (not ability.unlock_only or ability.id == game.player.class_data.starting_ability))
			exclusive += int(ability.class_ids.size() == 1)
			game.abilities.reset(game.player.class_data.starting_ability, str(class_id))
			game.player.rebuild_run_stats(game.abilities.accumulated_bonuses())
			for rank in 3:
				assert(game.abilities.grant(id))
				game._apply_stat_ability(ability)
			var totals: Dictionary = game.abilities.accumulated_bonuses()
			var starting: AbilityData = catalog.abilities[str(game.player.class_data.starting_ability)]
			for key in ability.bonuses:
				assert(is_equal_approx(float(totals[key]), float(ability.bonuses[key]) * 3 + float(starting.bonuses.get(key, 0.0))))
			var base: Dictionary = game.player.base_run_stats
			assert(is_equal_approx(game.player.damage, float(base.damage) * (1.0 + float(totals.get("damage_pct", 0.0)))))
			assert(is_equal_approx(game.player.attack_cooldown, float(base.attack_cooldown) / (1.0 + float(totals.get("attack_speed_pct", 0.0)))))
			assert(is_equal_approx(game.player.max_health, float(base.max_health) * (1.0 + float(totals.get("health_pct", 0.0)))))
			assert(is_equal_approx(game.player.move_speed, float(base.move_speed) * (1.0 + float(totals.get("speed_pct", 0.0)))))
			var cooldown: float = game.player.attack_cooldown
			game.player.rebuild_run_stats(totals)
			assert(is_equal_approx(cooldown, game.player.attack_cooldown), "Rebuilding does not apply bonuses twice")
			while game.abilities.level_of(id) < 5:
				assert(game.abilities.grant(id))
			assert(not game.abilities.grant(id), "Rank five is the limit")
		assert(exclusive >= 4)
		assert(not game.abilities.grant(&"missing"))
		for id in catalog.abilities:
			if not catalog.abilities[id].available_to(str(class_id)):
				assert(not game.abilities.grant(StringName(id)), "Another class's ability cannot be granted")
		game.abilities.reset(game.player.class_data.starting_ability, str(class_id))
		for id in [&"rapid_hands", &"hunters_pace"]:
			for rank in 3:
				assert(game.abilities.grant(id))
		game.player.rebuild_run_stats(game.abilities.accumulated_bonuses())
		assert(is_equal_approx(game.player.attack_cooldown, float(game.player.base_run_stats.attack_cooldown) / 1.63), "Three +16% choices and three +5% choices total +63%")
		game.queue_free()
		await process_frame
	print("PASS: six class identities, exclusive/shared pools, additive bonuses for every passive, rank limits and cross-skill stacking")

func _test_summons_and_threat() -> void:
	_fresh()
	save.data.gold = 10000
	assert(save.unlock_class("druid"))
	var game = load("res://scenes/game.tscn").instantiate()
	game.player_class = "druid"
	root.add_child(game)
	game.set_process(false)
	game.wave_director.set_process(false)
	var enemy = game.enemy_manager.spawn(&"elite", 1, Vector2(80, 0))
	enemy.set_physics_process(false)
	enemy.health = 5000.0
	enemy.max_health = 5000.0
	game._summon_companions("wolf", 2, 14.0)
	assert(get_nodes_in_group("forest_companion").size() == 2)
	var before: float = enemy.health
	for companion in get_nodes_in_group("forest_companion"):
		companion._physics_process(0.8)
		companion._physics_process(0.8)
	assert(enemy.health < before and game.player.total_damage_dealt > 0.0, "Summons deal actual damage")
	var initial_summon_bonus: float = game.player.summon_damage_pct
	for rank in 3:
		game._choose_ability(&"wolf_pack")
		game._choose_ability(&"living_bark")
	assert(game.player.summon_count == 3 and is_equal_approx(game.player.summon_damage_pct, initial_summon_bonus + 0.54))
	game._summon_companions("wolf", 2 + game.player.summon_count, 14 + game.player.summon_duration)
	assert(get_nodes_in_group("forest_companion").size() == 5, "Recasting replaces the previous pack")
	game._cast_special("ancient_guardian", 3)
	assert(get_nodes_in_group("forest_companion").size() == 7)
	for companion in get_nodes_in_group("forest_companion"):
		companion.remaining = 0.01
		companion._physics_process(0.02)
	await process_frame
	await process_frame
	assert(get_nodes_in_group("forest_companion").is_empty(), "Every summoned monster expires")
	game.queue_free()
	await process_frame
	_fresh()
	game = load("res://scenes/game.tscn").instantiate()
	game.player_class = "mage"
	root.add_child(game)
	game.set_process(false)
	game.wave_director.set_process(false)
	var tank = load("res://scripts/world/player.gd").new()
	tank.configure("warrior", {})
	tank.position = Vector2(300, 0)
	game.add_child(tank)
	enemy = game.enemy_manager.spawn(&"goblin", 1, Vector2(80, 0))
	enemy._refresh_target()
	assert(enemy.player == tank, "The Sentinela draws attention despite being farther away")
	enemy.provoke(game.player, 2.0)
	enemy._refresh_target()
	assert(enemy.player == game.player, "Explicit provocation overrides ordinary threat")
	enemy.provoke_clock = 0.0
	enemy._refresh_target()
	assert(enemy.player == tank)
	enemy.position = Vector2(280, 0)
	enemy.hit_cooldown = 0.0
	var mage_health: float = game.player.health
	var tank_health: float = tank.health
	enemy._physics_process(0.01)
	assert(tank.health < tank_health and game.player.health == mage_health, "The hit damages the chosen player")
	game.queue_free()
	await process_frame
	print("PASS: summoned monsters pursue, damage, stack, refresh and expire; threat, provocation and damage target the correct player")

func _test_damage_and_recovery() -> void:
	_fresh()
	var player = load("res://scripts/world/player.gd").new()
	player.configure("warrior", {})
	player.defense = 5.0
	var initial_health: float = player.health
	player.take_damage(4.0)
	player.take_damage(20.0)
	assert(is_equal_approx(player.health, initial_health - 15.0), "A weak hit cannot shield a stronger attack")
	player.take_damage(4.0)
	assert(is_equal_approx(player.health, initial_health - 15.0), "Weak hits still share a grace period")
	player.invulnerability = 0.0
	player.defense = 100.0
	player.take_damage(12.0, true)
	assert(is_equal_approx(player.health, initial_health - 27.0), "Marked areas reward dodging even with armor")
	player.lifesteal = 0.24
	player.health = initial_health * 0.2
	var before: float = player.health
	var budget: float = player.life_recovery_budget
	player.record_damage(100000.0)
	player.record_damage(100000.0)
	assert(is_equal_approx(player.health, before + budget), "Multi-target hits share the recovery budget")
	player.health = 1.0
	player.invulnerability = 0.0
	player.damaged.connect(func(_amount: float) -> void: player.heal(10.0))
	player.take_damage(15.0, true)
	assert(player.is_dead and player.health == 0.0, "Recovery triggered by a lethal hit cannot resurrect the player")
	player.free()
	print("PASS: stronger hits, grace period, dangerous areas and bounded life recovery")

func _test_expeditions() -> void:
	for index in catalog.MAP_ORDER.size():
		_fresh()
		var class_id: String = str(catalog.CLASS_ORDER[index])
		if not save.is_class_unlocked(class_id):
			save.data.gold = 10000
			assert(save.unlock_class(class_id, "gold"))
		_grant_power(class_id)
		var map_id: String = str(catalog.MAP_ORDER[index])
		for ordinal in range(index * 10):
			assert(save.complete_phase(str(catalog.MAP_ORDER[floori(float(ordinal) / 10.0)]), ordinal % 10 + 1, 0))
		var game = load("res://scenes/game.tscn").instantiate()
		game.player_class = class_id
		game.map_id = map_id
		root.add_child(game)
		game.player.invulnerability = 999
		game.wave_director.set_process(false)
		game.set_process(false)
		assert(game.player.class_power and game.player.character_level == 40)
		var enemy = game.enemy_manager.spawn(game.map_data.enemy_pool[0], 1, Vector2(80, 0))
		var health_before: float = enemy.health
		game.player.health = game.player.max_health * 0.5
		game._cast_class_power()
		if class_id == "ranger":
			assert(get_nodes_in_group("friendly_projectile").size() >= 5)
			for arrow in get_nodes_in_group("friendly_projectile"):
				arrow._process(0.1)
		else:
			assert(enemy.dead or enemy.health < health_before, "Each class power must cause actual damage")
		if class_id == "druid" or class_id == "paladin":
			assert(game.player.health > game.player.max_health * 0.5)
		var removed = game.enemy_manager.spawn(game.map_data.enemy_pool[0], 1, Vector2(300, 300))
		game.enemy_manager.enemies.erase(removed)
		removed.free()
		for actor in game.enemy_manager.nearby(Vector2(300, 300), 64):
			assert(is_instance_valid(actor))
		spawn_count = 0
		game.wave_director.spawn_requested.connect(_count_spawn)
		for tick in 120:
			game.wave_director._process(0.1)
		assert(spawn_count >= 21)
		game.wave_director.start()
		for wave in range(4):
			game.wave_director._process(game.map_data.duration / 4.0)
		assert(game.boss != null and game.boss.data.id == game.map_data.boss_id)
		game.boss.take_hit(game.boss.max_health + 999)
		assert(game.run_finished and game.result_layer != null)
		assert(save.phase_completed(map_id, 1, 0) and save.phase_unlocked(map_id, 2, 0))
		assert(not save.phase_unlocked(str(catalog.MAP_ORDER[(index + 1) % 6]), 1, 0) if index < 5 else true)
		assert(save.data.crystals > 0 and talents.character_xp(class_id) > 0)
		paused = false
		game.queue_free()
		await process_frame
		await process_frame
	print("PASS: all 6 class powers, actual damage/healing/projectiles, regional bosses and rewards")

func _count_spawn(_kind: StringName, _wave: int) -> void:
	spawn_count += 1

func _test_inventory() -> void:
	_fresh()
	save.data.gold = 10000
	assert(save.unlock_class("paladin", "gold"))
	for id in ["wind_boots", "ember_signet", "oak_charm"]:
		save.unlock_equipment(id)
	save.set_selected_class("paladin")
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main._build_page("inventory")
	for frame in 5:
		await process_frame
	var panel = main.page_root.find_child("InventoryPanel", true, false)
	assert(panel != null and panel.visible_item_ids.size() == 4)
	assert(panel.orbit.slot_buttons.size() == 6 and panel.filter_dropdown.item_count == 7)
	panel.filter_dropdown.item_selected.emit(2)
	assert(panel.visible_item_ids.is_empty() and main.inventory_selected_slot == "helmet")
	panel.orbit.slot_buttons.weapon.pressed.emit()
	assert(panel.visible_item_ids == ["oath_hammer"] and panel.filter_dropdown.selected == 1)
	panel.orbit.slot_buttons.ring.pressed.emit()
	assert(panel.visible_item_ids == ["ember_signet"])
	var equip: Button = panel.item_list.find_child("EquipItem", true, false)
	assert(not equip.disabled)
	equip.pressed.emit()
	assert(str(save.loadout_for("paladin").ring) == "ember_signet")
	assert(not save.loadout_for("warrior").has("ring"), "Equipping preserves other characters")
	assert(str(panel.orbit.slot_buttons.ring.item.id) == "ember_signet")
	assert(panel.item_list.find_child("EquipItem", true, false).disabled)
	assert(not panel.equip_item("field_blade") and not panel.equip_item("missing"))
	save.unlock_equipment("dawn_helm")
	panel.select_filter("helmet")
	assert(panel.visible_item_ids == ["dawn_helm"] and panel.equip_item("dawn_helm"))
	save.load_game()
	assert(str(save.loadout_for("paladin").helmet) == "dawn_helm")
	assert(str(save.loadout_for("paladin").ring) == "ember_signet")
	panel.select_filter("")
	assert(panel.visible_item_ids.size() == 5)
	var original_size: Vector2i = root.size
	for resolution in [Vector2i(1280, 720), Vector2i(960, 540), Vector2i(390, 844)]:
		root.size = resolution
		for frame in 8:
			await process_frame
		panel = main.page_root.find_child("InventoryPanel", true, false)
		assert(panel != null and panel.visible_item_ids.size() == 5)
		assert(panel.body.vertical == (panel.size.x < 820.0))
		assert(main.page_scroll == null and not panel.item_scroll is ScrollContainer, "Arsenal must use pagination instead of scrolling")
		var viewport: Control = main.page_root.find_child("OnlineViewport", true, false)
		assert(viewport.content.get_global_rect().end.y <= viewport.get_global_rect().end.y + 1, "Arsenal must fit vertically")
		assert(panel.orbit.portrait.class_id == "paladin", "Arsenal reuses the actual selected character asset")
		for label in panel.find_children("*", "Label", true, false):
			assert(not label.text.contains("?"), "Arsenal text must preserve accents")

		assert(main.page_root.get_combined_minimum_size().x <= root.get_visible_rect().size.x + 1.0, "Inventory must fit the window width")
		for button in panel.orbit.slot_buttons.values():
			assert(Rect2(Vector2.ZERO, panel.orbit.size).encloses(button.get_rect()), "Equipment cards must remain inside the portrait panel")
			assert(button.box.get_combined_minimum_size().x <= button.box.size.x + 1.0, "Equipment text must fit its card")
			assert(button.box.get_combined_minimum_size().y <= button.box.size.y + 1.0, "Equipment text must fit its card height")
		for card in panel.item_list.get_children():
			assert(card.size.x <= panel.item_scroll.size.x + 1.0, "Owned items cannot overflow horizontally")
	panel.select_filter("")
	# Populate more than one icon page to verify pagination of a real collection.
	for id in catalog.equipment:
		var gear: EquipmentData = catalog.equipment[id]
		if str(gear.class_id) == "paladin":
			save.unlock_equipment(str(id))
			if panel.owned_items().size() > panel.page_size:
				break
	panel._refresh_items()
	var displayed: Array[String] = []
	var first_page: Array[String] = []
	for card in panel.item_list.get_children():
		if card.has_meta("item_id"): first_page.append(str(card.get_meta("item_id")))
	assert(first_page.size() == panel.page_size and not panel.next_page.disabled)
	displayed.append_array(first_page)
	panel.next_page.pressed.emit()
	assert(panel.page_index == 1 and panel.previous_page.disabled == false)
	for card in panel.item_list.get_children():
		if card.has_meta("item_id"):
			assert(not first_page.has(str(card.get_meta("item_id"))))
			displayed.append(str(card.get_meta("item_id")))
	assert(displayed.size() == panel.visible_item_ids.size(), "All owned items remain accessible through pages")
	panel.select_filter("ring")
	assert(panel.page_index == 0, "Changing filters resets the inventory page")
	panel.forge_requested.emit()
	assert(main.page_name == "forge")
	main.queue_free()
	await process_frame
	root.size = original_size
	print("PASS: inventory filters, slot clicks, equip buttons, class isolation, persistence and three window sizes")

func _test_ability_labels() -> void:
	var original_size: Vector2i = root.size
	var original_scale: Vector2i = root.content_scale_size
	for resolution in [Vector2i(1280, 720), Vector2i(390, 844)]:
		root.size = resolution
		root.content_scale_size = resolution
		await process_frame
		var list := VBoxContainer.new()
		list.theme = load("res://scripts/ui/wild_theme.gd").create_theme()
		list.custom_minimum_size.x = resolution.x - 36
		root.add_child(list)
		for ability in catalog.abilities.values():
			if ability.unlock_only:
				continue
			var card = load("res://scripts/ui/level_choice_card.gd").new()
			card.configure(ability, 2)
			list.add_child(card)
		for frame in 12:
			await process_frame
		for card in list.get_children():
			assert(card.text_content.get_combined_minimum_size().y <= card.size.y - 26 + 1, "Skill description and cumulative total must fit the choice card")
		list.queue_free()
		await process_frame
	root.size = original_size
	root.content_scale_size = original_scale
	assert(catalog.abilities.rapid_hands.rank_description(3).contains("+48%"))
	print("PASS: cumulative ability descriptions and card height on desktop and narrow screens")

func _test_menus() -> void:
	_fresh()
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	for page in ["home", "characters", "abilities", "talents", "maps", "bestiary", "statistics"]:
		main._build_page(page)
		await process_frame
		await process_frame
	main._select_talent_class(1)
	assert(main.selected_class == "mage" and talents.class_id == "mage")
	await process_frame
	main._select_class("warrior")
	main._start_game(false)
	var game = main.active_game
	game.wave_director.set_process(false)
	game._on_boss_summoned(&"goblin_king")
	game.boss.take_hit(game.boss.max_health + 999)
	main._next_stage()
	assert(main.active_game.map_id == "verdant_reach" and main.active_game.phase_number == 2)
	assert(not paused)
	main._return_to_menu()
	await process_frame
	for phase in range(2, 11):
		assert(save.complete_phase("verdant_reach", phase, 0))
	main.selected_phase = 10
	main._next_stage()
	assert(main.active_game.map_id == "hollow_cairn" and main.active_game.phase_number == 1)
	main._return_to_menu()
	await process_frame
	for ordinal in range(10, 60):
		assert(save.complete_phase(str(catalog.MAP_ORDER[floori(float(ordinal) / 10.0)]), ordinal % 10 + 1, 0))
	main.selected_map = "sunken_mire"
	main.selected_phase = 10
	main._next_stage()
	assert(main.active_game.map_id == "verdant_reach" and main.active_game.phase_number == 1 and main.active_game.difficulty_tier == 1)
	main._return_to_menu()
	await process_frame
	main._build_page("maps")
	await process_frame
	main.queue_free()
	await process_frame
	print("PASS: menus, class selector, phase 1→2, region boundary and difficulty boundary")

func _test_menu_audio() -> void:
	var audio: Node = root.get_node("AudioManager")
	assert(audio.menu_stream != null and audio.menu_stream.get_length() > 1.0)
	assert(audio.click_stream != null and audio.click_stream.get_length() > 0.0)
	audio.menu_music(true)
	assert(audio.music_player.playing and audio.menu_stream.loop)
	var playback: float = audio.music_player.get_playback_position()
	audio.menu_music(true)
	assert(audio.music_player.get_playback_position() >= playback)
	var button := Button.new()
	root.add_child(button)
	assert(button.pressed.is_connected(audio.play_click))
	button.pressed.emit()
	var played := false
	for effect in audio.effect_players:
		if effect.stream == audio.click_stream and effect.playing:
			played = true
	assert(played, "Menu buttons use the supplied click sound")
	audio.menu_music(false)
	assert(not audio.music_player.playing)
	button.queue_free()
	audio.stop_all()
	await process_frame
