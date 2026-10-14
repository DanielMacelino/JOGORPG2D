extends RefCounted

func run(tree: SceneTree) -> void:
	assert(str(ProjectSettings.get_setting("application/config/name")).begins_with("Ashenwild Regression"))
	var save: Node = tree.root.get_node("SaveManager")
	var previous: Dictionary = save.data.duplicate(true)
	var old_size: Vector2i = tree.root.size
	var old_scale: Vector2i = tree.root.content_scale_size
	save.data = save.DEFAULT_SAVE.duplicate(true)
	save._initialize_progression(false)
	# Measure the recipe debit independently of the first-forge achievement reward.
	save.data.achievements.first_forge = true
	save.data.gold = 100000
	save.data.crystals = 1000
	var source := "gear_warrior_weapon_verdant_reach_1_0"
	var target := "gear_warrior_weapon_verdant_reach_1_1"
	save.data.equipment.append(source)
	save.data.equipment_quantities[source] = 2
	tree.root.size = Vector2i(1280, 720)
	tree.root.content_scale_size = Vector2i(1280, 720)
	var main: Node = load("res://scenes/main.tscn").instantiate()
	tree.root.add_child(main)
	main._build_page("inventory")
	main._build_page("forge")
	await _settle(tree)
	var panel: Node = main.page_root.find_child("ForgePanel", true, false)
	assert(panel.sidebar.visible and panel.recipe_frame.visible and panel.detail_frame.visible)
	assert(panel.page_size == 5 and panel.list.get_child_count() == 5)
	var last_power := INF
	for recipe in panel.matched_recipes:
		var item: EquipmentData = ContentCatalog.equipment[str(recipe.result)]
		assert(item.power_score() <= last_power + 0.01)
		last_power = item.power_score()
	panel._select_recipe("forge_" + target)
	var ingredient: Label = panel.find_child("IngredientQuantity", true, false)
	assert(ingredient.text == "2 / 1")
	var recipe: Dictionary = ContentCatalog.get_forge_recipe("forge_" + target)
	var gold: int = save.data.gold
	var crystals: int = save.data.crystals
	var page_before: int = panel.draft.page
	panel.find_child("ForgeSelectedAction", true, false).pressed.emit()
	await _settle(tree)
	assert(save.data.equipment.has(target) and save.equipment_quantity(source) == 1)
	assert(save.data.gold == gold - int(recipe.gold_cost) and save.data.crystals == crystals - int(recipe.crystal_cost))
	assert(panel.draft.page == page_before and panel.draft.selected == "forge_" + target)
	assert(panel.find_child("ForgeSelectedAction", true, false).disabled)
	assert(panel.find_child("IngredientQuantity", true, false).text == "1 / 1")
	assert(panel.notice.text.contains("criado"))
	save.load_game()
	assert(save.data.equipment.has(target) and save.equipment_quantity(source) == 1)
	panel._filter("category", "weapons")
	panel._filter("weapon", "bow")
	assert(not panel.matched_recipes.is_empty())
	for row in panel.matched_recipes:
		var item: EquipmentData = ContentCatalog.equipment[str(row.result)]
		assert(item.slot == &"weapon" and item.class_id == &"ranger")
	panel._filter("category", "all")
	panel._filter("order", "cost")
	var last_cost := -1
	for row in panel.matched_recipes:
		assert(int(row.gold_cost) >= last_cost)
		last_cost = int(row.gold_cost)
	panel._filter("order", "power")
	for resolution in [Vector2i(1280, 720), Vector2i(960, 540), Vector2i(640, 360), Vector2i(390, 844), Vector2i(320, 640)]:
		for scale in [0.85, 1.2]:
			tree.root.size = resolution
			tree.root.content_scale_size = resolution
			save.data.settings.ui_scale = scale
			main._build_page("forge")
			await _settle(tree)
			panel = main.page_root.find_child("ForgePanel", true, false)
			for category in ["all", "weapons", "armor", "accessories"]:
				panel._filter("category", category)
				panel._filter("rarity", "legendary")
				for section in 3:
					panel._section(section)
					await _settle(tree)
					_check(main, panel, resolution)
			panel._filter("rarity", "all")
			panel._filter("query", "no such equipment xyz")
			panel._section(1)
			await _settle(tree)
			assert(panel.matched_recipes.is_empty())
			_check(main, panel, resolution)
			panel._filter("query", "")
			panel._filter("category", "all")
	main._go_back()
	assert(main.page_name == "inventory")
	main.queue_free()
	await tree.process_frame
	tree.root.size = old_size
	tree.root.content_scale_size = old_scale
	save.data = previous
	save.save_game()
	print("PASS: forge cabinet, 5 desktop cards, canonical power/cost sorting, categories and weapon types, real ingredient counts, exact consumption/costs, crafted selection/persistence and no-scroll three-section layout at 5 resolutions/2 scales")

func _check(main: Node, panel: Node, resolution: Vector2i) -> void:
	var viewport: Control = main.page_root.find_child("OnlineViewport", true, false)
	assert(main.page_scroll == null)
	assert(viewport.content.scale.x >= 0.94, "Forge must fit without shrinking: %s factor %s min %s viewport %s category %s section %s" % [resolution, viewport.content.scale, viewport.content.get_combined_minimum_size(), viewport.size, panel.draft.category, panel.draft.section])
	assert(viewport.content.get_global_rect().end.y <= viewport.get_global_rect().end.y + 2)
	for label in panel.find_children("ForgeCurrency*", "Label", true, false): assert(label.autowrap_mode == TextServer.AUTOWRAP_OFF)
	for button in panel.find_children("*", "Button", true, false):
		if not button.is_visible_in_tree(): continue
		var bounds: Rect2 = button.get_global_rect()
		assert(bounds.position.x >= viewport.get_global_rect().position.x - 2 and bounds.end.x <= viewport.get_global_rect().end.x + 2, "Forge button overflow %s %s %s" % [resolution, button.name, bounds])
		assert(bounds.size.x >= 24 and bounds.size.y >= 24)
	for scroll in panel.find_children("*", "ScrollContainer", true, false): assert(not scroll.is_visible_in_tree())

func _settle(tree: SceneTree) -> void:
	for frame in 12: await tree.process_frame
