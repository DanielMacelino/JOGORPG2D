extends RefCounted
func run(tree: SceneTree) -> void:
	var catalog: Node = tree.root.get_node("ContentCatalog")
	var save: Node = tree.root.get_node("SaveManager")
	var generated := 0
	var families := {}
	for item in catalog.equipment.values():
		if not item.generated: continue
		generated += 1
		assert(catalog.CLASS_ORDER.has(item.class_id) )
		assert(ItemTiers.ORDER[item.tier_index] == str(item.rarity))
		assert(not item.description.is_empty() and item.stat_amount > 0)
		if not families.has(str(item.family_id)): families[str(item.family_id)] = []
		families[str(item.family_id)].append(item)
	assert(generated == 6188 and families.size() == 884)
	var recipes := 0
	for recipe in catalog.forge_recipes:
		if not bool(recipe.get("generated", false)): continue
		recipes += 1
		var item: EquipmentData = catalog.equipment[recipe.result]
		var source: EquipmentData = catalog.equipment[recipe.ingredients[0].id]
		assert(source.family_id == item.family_id and source.class_id == item.class_id and source.slot == item.slot and source.tier_index + 1 == item.tier_index)
		assert(catalog.get_forge_recipe(str(recipe.id)) == recipe)
	assert(recipes == 5304)
	for family in families.values():
		family.sort_custom(func(a: EquipmentData,b: EquipmentData) -> bool: return a.tier_index < b.tier_index)
		assert(family.size() == 7)
		for index in range(1,7): assert(family[index].stat_amount > family[index-1].stat_amount)
	var skill_count := 0
	for skill in catalog.abilities.values():
		if not str(skill.id).begins_with("skill_"): continue
		skill_count += 1
		assert(not skill.bonuses.is_empty() and catalog.abilities.has(skill.visual_id()))
	assert(skill_count == 294)
	save.data = save.DEFAULT_SAVE.duplicate(true)
	save._initialize_progression(false)
	save.data.unlocked_classes = catalog.CLASS_ORDER.duplicate()
	var manager := AbilityManager.new()
	for owner in catalog.CLASS_ORDER:
		manager.reset(&"", str(owner), 0)
		assert(not manager.chooseable().has(&"skill_shared_0_6"))
		manager.reset(&"", str(owner), 6)
		manager.expedition_level = 30
		for id in catalog.abilities:
			var skill: AbilityData = catalog.abilities[id]
			if not str(id).begins_with("skill_"): continue
			if not skill.available_to(str(owner)):
				assert(not manager.grant(skill.id))
				continue
			manager.levels.clear()
			for rank in 3: assert(manager.grant(skill.id))
			var bonuses := manager.accumulated_bonuses()
			for key in skill.bonuses: assert(is_equal_approx(float(bonuses[key]), float(skill.bonuses[key]) * 3))
	manager.free()
	var loot := LootManager.new()
	loot.rng.seed = 99
	for region in catalog.MAP_ORDER:
		for owner in catalog.CLASS_ORDER:
			for difficulty in [0, 3, 6]:
				for sample in 3:
					var result := loot.roll_boss_reward(str(region), str(owner), 10, [], difficulty)
					var item: EquipmentData = catalog.equipment[result.equipment]
					assert(item.region_id == region and (item.class_id == &"" or item.class_id == owner) and item.required_difficulty <= difficulty)
	loot.free()
	# Forge a tier upgrade and ensure a consumed equipped item is replaced by its result.
	save.data.gold = 100000
	save.data.crystals = 10000
	var source_id := "gear_warrior_weapon_verdant_reach_1_0"
	var target_id := "gear_warrior_weapon_verdant_reach_1_1"
	save.data.equipment.append(source_id)
	assert(tree.root.get_node("EquipmentManager").equip("weapon", source_id, "warrior"))
	assert(save.can_forge("forge_" + target_id) and save.forge_item("forge_" + target_id))
	assert(not save.data.equipment.has(source_id) and save.data.equipment.has(target_id))
	assert(save.loadout_for("warrior").weapon == target_id)
	assert(not save.can_forge("forge_gear_warrior_weapon_verdant_reach_1_6"))
	save.load_game()
	assert(save.loadout_for("warrior").weapon == target_id)
	# Test large-catalog filtering and pagination without constructing thousands of nodes.
	var main: Node = load("res://scenes/main.tscn").instantiate()
	tree.root.add_child(main)
	main._build_page("forge")
	for frame in 10: await tree.process_frame
	var panel: Control = main.page_root.find_child("ForgePanel", true, false)
	assert(main.page_scroll == null and panel.list.get_child_count() <= panel.page_size)
	for pair in [[panel.class_picker, "druid"], [panel.slot_picker, "amulet"], [panel.rarity_picker, "divine"]]:
		var picker: OptionButton = pair[0]
		for index in picker.item_count:
			if str(picker.get_item_metadata(index)) == pair[1]:
				picker.select(index)
				picker.item_selected.emit(index)
	panel.search.text = "Esporos"
	panel.search.text_changed.emit(panel.search.text)
	for frame in 5: await tree.process_frame
	assert(panel.matched_recipes.size() == 4)
	# Exercise pagination independently of the adaptive desktop page capacity.
	panel.page_size = 2
	panel._render()
	var first: Array[String] = []
	for card in panel.list.get_children(): first.append(str(card.get_meta("recipe_id")))
	panel.next.pressed.emit()
	assert(int(panel.draft.page) == 1)
	for card in panel.list.get_children(): assert(not first.has(str(card.get_meta("recipe_id"))))
	panel.possible.button_pressed = true
	panel.possible.toggled.emit(true)
	assert(panel.matched_recipes.is_empty(), "Divine crafts stay unavailable before campaign progression")
	main.queue_free()
	await tree.process_frame
	print("PASS: 6188 class equipment, 884 seven-tier families, 5304 indexed upgrade recipes, 294 functional class/shared skills, difficulty gates, regional drops and equipped crafting persistence")
