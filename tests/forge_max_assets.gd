extends RefCounted

func run(tree: SceneTree) -> void:
	assert(str(ProjectSettings.get_setting("application/config/name")).begins_with("Ashenwild Regression"))
	var save: Node = tree.root.get_node("SaveManager")
	var previous: Dictionary = save.data.duplicate(true)
	_test_forge(save)
	_test_max(save)
	_test_power(tree, save)
	await _test_bloom(tree, save)
	await _test_bloom_cards(tree)
	save.data = previous
	save.save_game()
	TalentManager.set_class(str(previous.selected_class))
	print("PASS: repeatable forge copies/material counts/persistence/favorites, exact all-or-nothing MAX/tier gates, equipped class power, additional demon, regional escalation and expanding class spell")

func _fresh(save: Node) -> void:
	save.data = save.DEFAULT_SAVE.duplicate(true)
	save._initialize_progression(false)
	save.data.gold = 1000000
	save.data.crystals = 10000

func _test_forge(save: Node) -> void:
	_fresh(save)
	for attempt in 3: assert(save.forge_item("forge_flame_sword"))
	assert(save.equipment_quantity("flame_sword") == 3)
	assert(save.equipment_quantity("field_blade") == 1, "Starter tools remain available")
	assert(save.data.forge_upgrades.forge_flame_sword == 3)
	save.load_game()
	assert(save.equipment_quantity("flame_sword") == 3)
	var source := "gear_warrior_weapon_verdant_reach_1_0"
	var target := "gear_warrior_weapon_verdant_reach_1_1"
	for copy_index in 3: TransmutationRules.add_copy(save.data, source)
	TransmutationRules.add_copy(save.data, target)
	assert(EquipmentManager.equip("weapon", source, "warrior"))
	assert(save.forge_item("forge_" + target))
	assert(save.equipment_quantity(source) == 2 and save.equipment_quantity(target) == 2)
	assert(save.loadout_for("warrior").weapon == source, "A remaining equipped copy must stay equipped")
	assert(save.forge_item("forge_" + target) and save.forge_item("forge_" + target))
	assert(save.equipment_quantity(source) == 0 and save.equipment_quantity(target) == 4)
	assert(save.loadout_for("warrior").weapon == target)
	var before: Dictionary = save.data.duplicate(true)
	assert(not save.forge_item("forge_" + target) and save.data == before)
	save.load_game()
	assert(save.equipment_quantity(target) == 4 and save.loadout_for("warrior").weapon == target)
	save.set_equipment_favorite("field_blade", true)
	before = save.data.duplicate(true)
	assert(not save.forge_item("forge_flame_sword") and save.data == before)
	save.set_equipment_favorite("field_blade", false)
	# Duplicate ingredient entries are aggregated before consuming anything.
	TransmutationRules.add_copy(save.data, source)
	var recipe := {"id": "test_duplicate_recipe", "result": target, "ingredients": [{"id": source, "qty": 1}, {"id": source, "qty": 1}], "gold_cost": 10, "crystal_cost": 0}
	ContentCatalog.forge_recipes.append(recipe)
	ContentCatalog.forge_index[str(recipe.id)] = recipe
	before = save.data.duplicate(true)
	assert(not save.forge_item(str(recipe.id)) and save.data == before)
	TransmutationRules.add_copy(save.data, source)
	assert(save.forge_item(str(recipe.id)))
	assert(save.equipment_quantity(source) == 0 and save.equipment_quantity(target) == 5)
	ContentCatalog.forge_recipes.erase(recipe)
	ContentCatalog.forge_index.erase(str(recipe.id))
	# An unavailable save destination must not consume items or currency.
	save.save_game()
	before = save.data.duplicate(true)
	var saved := FileAccess.get_file_as_string(save.SAVE_PATH)
	var blocked := ProjectSettings.globalize_path(save.SAVE_PATH + ".inventory_tmp")
	assert(DirAccess.make_dir_absolute(blocked) == OK)
	assert(not save.forge_item("forge_flame_sword"))
	assert(save.data == before and FileAccess.get_file_as_string(save.SAVE_PATH) == saved)
	assert(DirAccess.remove_absolute(blocked) == OK)

func _test_max(save: Node) -> void:
	_fresh(save)
	var quote := PermanentUpgrades.max_quote("might", save.upgrades_for())
	var expected := 0
	var simulated: Dictionary = save.upgrades_for().duplicate(true)
	for rank in 10:
		expected += PermanentUpgrades.cost("might", simulated)
		simulated.might = rank + 1
	assert(quote.count == 10 and quote.cost == expected and quote.target == 10)
	save.data.gold = expected - 1
	var before: Dictionary = save.data.duplicate(true)
	assert(not save.buy_upgrade_max("might") and save.data == before)
	save.data.gold = expected
	save.save_game()
	before = save.data.duplicate(true)
	var blocked := ProjectSettings.globalize_path(save.SAVE_PATH + ".inventory_tmp")
	assert(DirAccess.make_dir_absolute(blocked) == OK)
	assert(not save.buy_upgrade_max("might") and save.data == before)
	assert(DirAccess.remove_absolute(blocked) == OK)
	assert(save.buy_upgrade_max("might") and save.data.gold == 0 and save.upgrade_level("might") == 10)
	assert(not save.buy_upgrade_max("might"))
	for id in PermanentUpgrades.IDS: save.upgrades_for()[id] = 10
	save.upgrades_for().might = 7
	quote = PermanentUpgrades.max_quote("might", save.upgrades_for())
	assert(quote.count == 3 and quote.target == 10)
	save.data.gold = quote.cost
	assert(save.buy_upgrade_max("might") and save.data.gold == 0)
	assert(PermanentUpgrades.tier(save.upgrades_for()) == 1 and save.upgrade_level("might") == 10)
	quote = PermanentUpgrades.max_quote("might", save.upgrades_for())
	assert(quote.count == 10 and quote.target == 20)
	save.load_game()
	assert(save.upgrade_level("might") == 10 and save.data.gold == 0)
	assert(PermanentUpgrades.max_quote("missing", save.upgrades_for()).count == 0)

func _test_power(tree: SceneTree, save: Node) -> void:
	_fresh(save)
	var equipment: Node = tree.root.get_node("EquipmentManager")
	var old_power: int = equipment.character_power("warrior")
	TransmutationRules.add_copy(save.data, "flame_sword")
	TransmutationRules.add_copy(save.data, "moon_staff")
	assert(equipment.character_power("warrior") == old_power, "Unequipped gear must not contribute")
	var mage_power: int = equipment.character_power("mage")
	assert(equipment.equip("weapon", "flame_sword", "warrior"))
	assert(equipment.character_power("warrior") == roundi(ContentCatalog.equipment.flame_sword.power_score()))
	assert(equipment.character_power("mage") == mage_power)
	TransmutationRules.add_copy(save.data, "flame_sword")
	assert(equipment.character_power("warrior") == roundi(ContentCatalog.equipment.flame_sword.power_score()))
	TransmutationRules.add_copy(save.data, "warden_helm")
	assert(equipment.equip("helmet", "warden_helm", "warrior"))
	assert(equipment.character_power("warrior") == roundi(ContentCatalog.equipment.flame_sword.power_score() + ContentCatalog.equipment.warden_helm.power_score()))
	var previous := 0.0
	for region in ContentCatalog.MAP_ORDER:
		var stage := CampaignRules.expedition(str(region), 1, 0)
		assert(stage.difficulty > previous)
		previous = stage.difficulty
	assert(CampaignRules.expedition("hollow_cairn", 1, 0).difficulty > CampaignRules.expedition("verdant_reach", 10, 0).difficulty)
	assert(ContentCatalog.maps.hollow_cairn.enemy_pool.has(&"demon_a"))
	assert(not ContentCatalog.maps.verdant_reach.enemy_pool.has(&"demon_a"))

func _test_bloom(tree: SceneTree, save: Node) -> void:
	_fresh(save)
	var ability: AbilityData = ContentCatalog.abilities.arcane_bloom
	assert(ability.active_power and ability.available_to("mage") and ability.available_to("druid"))
	for owner in ["warrior", "ranger", "assassin", "paladin"]: assert(not ability.available_to(owner))
	assert(ability.hud_total(3) == "190%")
	var game: ExpeditionGame = load("res://scenes/game.tscn").instantiate()
	game.player_class = "mage"
	tree.root.add_child(game)
	game.process_mode = Node.PROCESS_MODE_DISABLED
	game.wave_director.stop()
	game.enemy_manager.clear()
	game.player.position = Vector2.ZERO
	var targets: Array[ChaserEnemy] = []
	for distance in [35, 120, 180]:
		var enemy := game.enemy_manager.spawn(&"demon_a", 1, Vector2(distance, 0))
		enemy.health = 10000
		enemy.max_health = 10000
		targets.append(enemy)
	game.enemy_manager._process(1)
	game._cast_special("arcane_bloom", 1)
	var bloom: Node = game.find_child("ArcaneBloom", true, false)
	assert(bloom != null and bloom.bloom_sprite is Sprite2D)
	assert(bloom.bloom_sprite.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST)
	bloom._process(0.20)
	assert(targets[0].health < 10000 and targets[1].health == 10000)
	var first_hit := targets[0].health
	bloom._process(0.50)
	assert(targets[0].health == first_hit and targets[1].health < 10000 and targets[2].health == 10000)
	var second_hit := targets[1].health
	bloom._process(0.10)
	assert(targets[0].health == first_hit and targets[1].health == second_hit)
	assert(is_equal_approx(game.special_clocks.arcane_bloom, 7.5))
	game.queue_free()
	await tree.process_frame

func _test_bloom_cards(tree: SceneTree) -> void:
	var old_size := tree.root.size
	var old_scale := tree.root.content_scale_size
	var old_preference: float = SaveManager.data.settings.ui_scale
	for resolution in [Vector2i(1280, 720), Vector2i(640, 480), Vector2i(640, 360), Vector2i(390, 844)]:
		for preference in [0.85, 1.2]:
			tree.root.size = resolution
			tree.root.content_scale_size = resolution
			SaveManager.data.settings.ui_scale = preference
			var screen: Control = load("res://scripts/ui/ability_choice_screen.gd").new()
			screen.choices.assign(["arcane_bloom", "glacial_ring", "roots_snare"])
			screen.ranks = {"arcane_bloom": 4, "glacial_ring": 4, "roots_snare": 4}
			screen.reward_text = "RELÍQUIA ENCONTRADA · Martelo do Juramento"
			tree.root.add_child(screen)
			for frame in 16: await tree.process_frame
			for card in screen.grid.get_children():
				assert(card.text_scale >= 0.70, "Spell text at %s: %s scale=%s card=%s" % [resolution, card.ability.id, card.text_scale, card.size])
				assert(card.get_global_rect().end.y <= screen.size.y + 1)
				assert(card.text_content.get_combined_minimum_size().y * card.text_content.scale.y <= card.size.y - card.text_content.position.y - 9)
			screen.queue_free()
			await tree.process_frame
	tree.root.size = old_size
	tree.root.content_scale_size = old_scale
	SaveManager.data.settings.ui_scale = old_preference
