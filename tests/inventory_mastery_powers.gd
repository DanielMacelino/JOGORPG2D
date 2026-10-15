extends RefCounted

func run(tree: SceneTree) -> void:
	var save: Node = tree.root.get_node("SaveManager")
	var manager: Node = tree.root.get_node("GameManager")
	var previous: Dictionary = save.data.duplicate(true)
	var running: bool = manager.run_active
	manager.run_active = false
	save.data = save.DEFAULT_SAVE.duplicate(true)
	save._initialize_progression(false)
	save.data.gold = 100000000
	for stage in PermanentUpgrades.RATES.size():
		assert(PermanentUpgrades.tier(save.upgrades_for()) == stage)
		for id in PermanentUpgrades.IDS:
			for step in 10:
				var rank: int = save.upgrade_level(id)
				var expected := PermanentUpgrades.bonus(rank) + float(PermanentUpgrades.RATES[stage])
				var cost := PermanentUpgrades.cost(id, save.upgrades_for())
				var gold: int = save.data.gold
				assert(save.buy_upgrade(id, -999999), "Displayed prices never override the real price")
				assert(int(save.data.gold) == gold - cost)
				assert(is_equal_approx(PermanentUpgrades.bonus(save.upgrade_level(id)), expected))
			if id != PermanentUpgrades.IDS.back() or stage == PermanentUpgrades.RATES.size() - 1:
				var gold: int = save.data.gold
				assert(not save.buy_upgrade(id, 0), "No attribute can skip ahead of the collective tier")
				assert(int(save.data.gold) == gold)
	assert(PermanentUpgrades.progress(save.upgrades_for()) == 80)
	assert(is_equal_approx(PermanentUpgrades.bonus(10), 0.002))
	assert(is_equal_approx(PermanentUpgrades.bonus(20), 0.005))
	assert(is_equal_approx(PermanentUpgrades.bonus(30), 0.01))
	for id in ["resilience", "crit_mastery"]:
		var last := 0.0
		for rank in range(1, 71):
			var next := PermanentUpgrades.effective_bonus(id, rank)
			assert(next > last and next < 1.0, "Every purchase must improve the attribute without granting immunity")
			last = next
	assert(not save.buy_upgrade("invalid", 0))
	save.load_game()
	for id in PermanentUpgrades.IDS: assert(save.upgrade_level(id) == 70)
	save.character_meta().upgrades = save.DEFAULT_SAVE.upgrades.duplicate()
	var player := SurvivorPlayer.new()
	player.configure("warrior", {})
	var base_hp := player.max_health
	var base_damage := player.damage
	var base_speed := player.move_speed
	var base_cooldown := player.attack_cooldown
	for id in PermanentUpgrades.IDS: save.upgrades_for()[id] = 1
	player.configure("warrior", {})
	assert(is_equal_approx(player.max_health / base_hp, 1.0002))
	assert(is_equal_approx(player.damage / base_damage, 1.0002))
	assert(is_equal_approx(player.move_speed / base_speed, 1.0002))
	assert(is_equal_approx(base_cooldown / player.attack_cooldown, 1.0002))
	assert(is_equal_approx(player.bonus_gold_xp, 0.0002) and is_equal_approx(player.bonus_xp_only, 0.0002))
	player.take_damage(100.0, true)
	assert(is_equal_approx(player.max_health - player.health, 99.98))
	player.free()
	print("PASS: 560 mastery purchases, collective tier gates, canonical prices, persistence and actual 0.02% character combat bonuses")
	_test_powers()
	await _test_sovereigns(tree)
	await _test_icons(tree, save)
	save.data = previous
	save.save_game()
	manager.run_active = running

func _test_powers() -> void:
	var powers := AbilityManager.new()
	powers.reset(&"arcane_focus", "mage", 6)
	powers.expedition_level = 100
	for id in [&"ember_orb", &"storm_arc", &"starfall"]: assert(powers.grant(id))
	assert(powers.active_power_count() == 3)
	assert(not powers.grant(&"void_rift") and not powers.chooseable().has(&"void_rift"))
	assert(powers.grant(&"storm_arc"), "An owned power still upgrades")
	for id in [&"rapid_hands", &"swift_feet", &"lifesteal", &"arcane_focus", &"skill_mage_4_0"]:
		assert(powers.grant(id), "Passives and innate attributes remain available")
	assert(powers.active_power_count() == 3)
	for iteration in 100:
		var choices := powers.roll_choices()
		assert(choices.size() == 3)
		for choice in choices:
			assert(not choice.active_power or powers.has_ability(choice.id))
	for rank in 3: assert(powers.grant(&"storm_arc"))
	assert(not powers.chooseable().has(&"storm_arc"))
	powers.reset(&"arcane_focus", "mage")
	assert(powers.active_power_count() == 0 and powers.chooseable().has(&"storm_arc"))
	powers.free()
	print("PASS: three active powers, unlimited passive types, innate upgrades, max-rank exclusion and 100 valid choice rolls")

func _test_sovereigns(tree: SceneTree) -> void:
	var world := Node2D.new()
	tree.root.add_child(world)
	var player := SurvivorPlayer.new()
	player.configure("warrior", {})
	world.add_child(player)
	player.set_physics_process(false)
	for region in ContentCatalog.MAP_ORDER:
		var ordinary := EnemyManager.new()
		world.add_child(ordinary)
		ordinary.configure(world, player, CampaignRules.expedition(str(region), 9, 0))
		var normal := ordinary.spawn_boss(ordinary.map_data.boss_id, 5)
		normal.set_physics_process(false)
		normal.get_node("BossBrain").set_process(false)
		var elite := EnemyManager.new()
		world.add_child(elite)
		elite.configure(world, player, CampaignRules.expedition(str(region), 10, 0))
		var boss := elite.spawn_boss(elite.map_data.boss_id, 5)
		boss.set_physics_process(false)
		var brain = boss.get_node("BossBrain")
		brain.set_process(false)
		assert(boss.max_health > normal.max_health * 3.0 and boss.damage > normal.damage * 1.25)
		assert(brain.sovereign and boss.data.display_name.ends_with("Soberano"))
		var base_patterns: Array = normal.get_node("BossBrain").patterns()
		assert(brain.patterns().size() > base_patterns.size())
		boss.health = boss.max_health * 0.24
		brain._process(0.0)
		assert(brain.second_phase and brain.final_phase)
		for spec in brain._sovereign_patterns(boss.position, player.position, Vector2.RIGHT, boss.damage):
			assert(spec.duration >= 1.35 and spec.damage > 0)
		var director := WaveDirector.new()
		director.configure(elite.map_data)
		var escorts: Array[StringName] = []
		director.spawn_requested.connect(func(kind: StringName, _wave: int) -> void:
			if director.boss_spawned: escorts.append(kind))
		director.start()
		for wave in 4: director._process(elite.map_data.duration / 4.0)
		assert(escorts.size() >= 10)
		assert(CampaignRules.reward_multiplier(0, 10) > CampaignRules.reward_multiplier(0, 9) * 1.6)
		director.free()
		boss.queue_free()
		normal.queue_free()
		ordinary.queue_free()
		elite.queue_free()
		await tree.process_frame
	world.queue_free()
	await tree.process_frame
	print("PASS: six phase-10 sovereigns, massive health, regional extra patterns, final rage, escorts and increased rewards")

func _test_icons(tree: SceneTree, save: Node) -> void:
	save.data.equipment = []
	for id in ContentCatalog.equipment:
		var item: EquipmentData = ContentCatalog.equipment[id]
		if str(item.class_id) == "warrior":
			save.data.equipment.append(str(id))
			if save.data.equipment.size() == 40: break
	var panel = load("res://scripts/ui/inventory_panel.gd").new()
	tree.root.add_child(panel)
	panel.select_filter("")
	var items: Array = panel.owned_items()
	for index in range(1, items.size()): assert(items[index - 1].power_score() >= items[index].power_score())
	assert(not panel.item_scroll is ScrollContainer)
	for button in panel.item_list.get_children():
		assert(button is Button and button.text.is_empty())
		assert(button.tooltip_text.contains("PODER:") and button.tooltip_text.contains("Clique para equipar"))
		var tip: Control = button._make_custom_tooltip(button.tooltip_text)
		tree.root.add_child(tip)
		assert(tip.get_child(0).text.contains("Origem:"))
		tip.queue_free()
	var first_id: String = panel.item_list.get_child(0).get_meta("item_id")
	assert(panel.equip_item(first_id))
	assert(str(save.loadout_for("warrior").get(str(ContentCatalog.equipment[first_id].slot))) == first_id)
	panel.queue_free()
	await tree.process_frame
	print("PASS: icon-only inventory, descending power score, full hover details and click-to-equip")
