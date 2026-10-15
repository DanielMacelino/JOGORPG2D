extends RefCounted

func run(tree: SceneTree) -> void:
	assert(str(ProjectSettings.get_setting("application/config/name")).begins_with("Ashenwild Regression"))
	var save: Node = tree.root.get_node("SaveManager")
	var previous: Dictionary = save.data.duplicate(true)
	_test_migration(save)
	_test_ownership(tree, save)
	_test_relics(save)
	await _test_nature(tree, save)
	save.data = previous
	save.save_game()
	TalentManager.set_class(str(previous.selected_class))
	print("PASS CHARACTER NATURE: one-time exact legacy refund, per-character upgrades/relic discoveries/equipment, online class profiles, tiny bonuses, world-2 resistance, animated rootlings, wolves and rooted tree attacks")

func _fresh(save: Node) -> void:
	save.data = save.DEFAULT_SAVE.duplicate(true)
	save._initialize_progression(false)
	save.data.gold = 100000

func _test_migration(save: Node) -> void:
	var legacy := {"gold": 100, "selected_class": "mage", "progression_version": 2, "talent_schema": 3, "upgrades": {"might": 3, "vitality": 2}, "relics": ["blood_pact"], "equipped_relics": ["blood_pact"]}
	var file := FileAccess.open(save.SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy))
	file.close()
	var original := FileAccess.get_file_as_string(save.SAVE_PATH)
	var blocked := ProjectSettings.globalize_path(save.SAVE_PATH + ".inventory_tmp")
	assert(DirAccess.make_dir_absolute(blocked) == OK)
	save.load_game()
	assert(FileAccess.get_file_as_string(save.SAVE_PATH) == original, "A failed migration write must preserve the original save")
	assert(DirAccess.remove_absolute(blocked) == OK)
	save.load_game()
	assert(save.data.gold == 222 and save.data.character_upgrade_refund == 122)
	assert(save.data.character_meta_schema == 1)
	for owner in ContentCatalog.CLASS_ORDER:
		for rank in save.upgrades_for(str(owner)).values(): assert(rank == 0)
	assert(save.has_relic("blood_pact", "mage") and save.is_relic_equipped("blood_pact", "mage"))
	assert(not save.has_relic("blood_pact", "warrior") and not save.is_relic_equipped("blood_pact", "warrior"))
	save.load_game()
	assert(save.data.gold == 222, "Reloading cannot refund a second time")
	assert(save.buy_upgrade("might"))
	assert(save.upgrade_level("might", "mage") == 1 and save.upgrade_level("might", "warrior") == 0)
	save.load_game()
	assert(save.data.gold == 189 and save.upgrade_level("might", "mage") == 1)

func _test_ownership(tree: SceneTree, save: Node) -> void:
	_fresh(save)
	var mage := SurvivorPlayer.new()
	mage.configure("mage", {})
	var base_damage := mage.damage
	var warrior := SurvivorPlayer.new()
	warrior.configure("warrior", {})
	var warrior_damage := warrior.damage
	save.set_selected_class("mage")
	assert(save.buy_upgrade("might"))
	assert(PermanentUpgrades.cost("might", {"might": 0}) == 33)
	assert(is_equal_approx(PermanentUpgrades.bonus(1), 0.0002))
	assert(PermanentUpgrades.percent(0.0002) == "0,02%")
	assert(is_equal_approx(PermanentUpgrades.bonus(70), 0.062))
	mage.configure("mage", {})
	warrior.configure("warrior", {})
	assert(is_equal_approx(mage.damage / base_damage, 1.0002))
	assert(is_equal_approx(warrior.damage, warrior_damage))
	assert(save.buy_upgrade_max("might") and save.upgrade_level("might", "mage") == 10)
	assert(save.upgrade_level("might", "warrior") == 0 and PermanentUpgrades.tier(save.upgrades_for("warrior")) == 0)
	var session: Node = tree.root.get_node("NetworkSession")
	var mage_profile: Dictionary = session.profile("Mago", "mage")
	var warrior_profile: Dictionary = session.profile("Sentinela", "warrior")
	assert(is_equal_approx(float(mage_profile.stats.damage), base_damage * 1.002))
	assert(is_equal_approx(float(warrior_profile.stats.damage), warrior_damage))
	mage.free()
	warrior.free()

func _test_relics(save: Node) -> void:
	_fresh(save)
	save.record_run(5, 1500, 100, 20, "warrior", 1, 2, 100, true, 1, 5)
	assert(save.has_relic("blood_pact", "warrior") and save.has_relic("ancient_tome", "warrior"))
	assert(not save.has_relic("blood_pact", "mage") and not save.has_relic("soul_lantern", "mage"))
	assert(save.equip_relic("blood_pact", "warrior"))
	assert(save.equip_relic("golden_compass", "warrior"))
	assert(save.equip_relic("soul_lantern", "warrior"))
	assert(not save.equip_relic("cursed_eye", "warrior"))
	save.record_run(1, 0, 1, 0, "mage")
	assert(not save.has_relic("soul_lantern", "mage"), "Global achievements must not unlock another hero's relics")
	save.record_run(5, 20, 30, 1, "mage", 1, 0, 20, true)
	assert(save.has_relic("blood_pact", "mage") and save.equip_relic("blood_pact", "mage"))
	assert(save.get_equipped_relics("warrior").size() == 3 and save.get_equipped_relics("mage").size() == 1)
	save.unequip_relic("blood_pact", "mage")
	assert(save.is_relic_equipped("blood_pact", "warrior") and not save.is_relic_equipped("blood_pact", "mage"))
	save.load_game()
	assert(save.has_relic("blood_pact", "mage") and save.get_equipped_relics("warrior").size() == 3)
	assert(save.get_equipped_relics("ranger").is_empty())

func _test_nature(tree: SceneTree, save: Node) -> void:
	_fresh(save)
	assert(save.unlock_class("druid"))
	var game: ExpeditionGame = load("res://scenes/game.tscn").instantiate()
	game.player_class = "druid"
	tree.root.add_child(game)
	game.process_mode = Node.PROCESS_MODE_DISABLED
	game.enemy_manager.clear()
	game.wave_director.stop()
	game.player.position = Vector2.ZERO
	var enemy := game.enemy_manager.spawn(&"elite", 1, Vector2(100, 0))
	enemy.health = 10000
	enemy.max_health = 10000
	game._summon_companions("rootling", 2, 16)
	var roots: Array[Node] = tree.get_nodes_in_group("forest_companion")
	assert(roots.size() == 2)
	for root in roots:
		assert(root.kind == "rootling" and root.get_node("RootlingSprite") is Sprite2D)
		assert(root.get_node("RootlingSprite").texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST)
		root.position = enemy.position - Vector2(20, 0)
		root._physics_process(0.8)
	assert(enemy.health < 10000 and game.player.total_damage_dealt > 0)
	game.enemy_manager._process(1)
	game._cast_special("nature_pack", 3)
	game._cast_special("living_grove", 5)
	var wolves := 0
	var trees := 0
	for companion in tree.get_nodes_in_group("forest_companion"):
		if companion.kind == "wolf": wolves += 1
		if companion.kind == "grove_tree":
			trees += 1
			companion.position = enemy.position - Vector2(180, 0)
			var before: Vector2 = companion.position
			var health := enemy.health
			companion._physics_process(0.1)
			assert(companion.position == before and enemy.health < health)
			assert(enemy.slow_amount >= 0.45 and companion.attack_reach > 100)
	assert(wolves == 2 and trees == 3)
	for power in ["nature_pack", "living_grove", "ancient_guardian", "roots_snare"]:
		assert(ContentCatalog.abilities[power].active_power and ContentCatalog.abilities[power].available_to("druid"))
	assert(not ContentCatalog.abilities.ember_orb.available_to("druid"))
	assert(not ContentCatalog.abilities.thorn_aura.available_to("druid"))
	game._summon_companions("rootling", 100, 16)
	var current := 0
	for companion in tree.get_nodes_in_group("forest_companion"):
		if companion.kind == "rootling": current += 1
	assert(current == 6)
	var stage := CampaignRules.expedition("hollow_cairn", 1, 0)
	game.enemy_manager.map_data = stage
	var mage := SurvivorPlayer.new()
	mage.configure("mage", {})
	for kind in stage.enemy_pool:
		var monster := game.enemy_manager.spawn(kind, 1, Vector2(300, 0))
		assert(monster.max_health >= 90 and monster.max_health > mage.damage * 1.12 * mage.crit_multiplier)
	assert(stage.difficulty > 3.0)
	mage.free()
	game.queue_free()
	await tree.process_frame
