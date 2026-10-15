extends RefCounted
const MODELS := preload("res://scripts/data/weapon_models.gd")

func run(tree: SceneTree) -> void:
	var save: Node = tree.root.get_node("SaveManager")
	var previous: Dictionary = save.data.duplicate(true)
	var image := MODELS.SHEET.get_image()
	assert(image.get_size() == Vector2i(448, 448) and image.detect_alpha() != Image.ALPHA_NONE)
	var used := {}
	var extras := 0
	var extra_recipes := 0
	for item in ContentCatalog.equipment.values():
		var owner := str(item.class_id)
		var cell := MODELS.cell_for(item, owner)
		if cell.x >= 0:
			used[cell] = true
			var texture := MODELS.atlas(cell.x, cell.y)
			assert(texture.filter_clip and texture.atlas == MODELS.SHEET)
			assert(image.get_region(Rect2i(texture.region)).get_used_rect().has_area(), "Empty equipment cell: %s %s" % [item.id, cell])
		if owner == "warrior" and item.slot == &"weapon":
			var shield: AtlasTexture = MODELS.shield_for(item)
			used[Vector2i(shield.region.position / 32)] = true
		if str(item.family_id).begins_with("sheet_"):
			extras += 1
			assert(item.generated and item.stat_amount > 0 and item.required_difficulty == ItemTiers.REQUIRED_DIFFICULTIES[item.tier_index])
			assert(str(item.rarity) == ItemTiers.ORDER[item.tier_index])
			if item.tier_index > 0:
				var recipe := ContentCatalog.get_forge_recipe("forge_" + str(item.id))
				assert(not recipe.is_empty() and recipe.ingredients[0].id == "gear_%s_%d" % [item.family_id, item.tier_index - 1])
				extra_recipes += 1
	assert(extras == 140 and extra_recipes == 120)
	var occupied := 0
	for row in 14:
		for column in 14:
			var has_pixels := image.get_region(Rect2i(column * 32, row * 32, 32, 32)).get_used_rect().has_area()
			if has_pixels:
				occupied += 1
				assert(used.has(Vector2i(column, row)), "Unused original model: %s %s" % [column, row])
	assert(occupied == 91 and used.size() == 91)
	for owner in ContentCatalog.CLASS_ORDER:
		var id := str(ContentCatalog.classes[owner].starter_weapon)
		var cell := MODELS.cell_for(ContentCatalog.equipment[id], str(owner))
		assert(cell.x == int(MODELS.COLUMNS[owner]))
	# A saved equipped item still exists and drives the actual player model.
	save.data = save.DEFAULT_SAVE.duplicate(true)
	save._initialize_progression(false)
	var id := "gear_sheet_shield_1_0"
	save.unlock_equipment(id)
	assert(EquipmentManager.equip("weapon", id, "warrior"))
	save.load_game()
	var player := SurvivorPlayer.new()
	player.configure("warrior", {})
	assert(player.equipped_weapon_id == id and player.animation_state().weapon_id == id)
	assert((MODELS.shield_for(ContentCatalog.equipment[id]) as AtlasTexture).region.position.x == 160)
	player.free()
	var profile: Dictionary = tree.root.get_node("NetworkSession").profile("Armas", "warrior")
	assert(profile.weapon == id)
	var main: Node = load("res://scenes/main.tscn").instantiate()
	tree.root.add_child(main)
	main._build_page("forge")
	for frame in 16: await tree.process_frame
	var forge: Node = main.page_root.find_child("ForgePanel", true, false)
	forge._filter("category", "weapons")
	forge._filter("weapon", "hammer")
	for frame in 16: await tree.process_frame
	assert(not forge.matched_recipes.is_empty())
	for recipe in forge.matched_recipes:
		assert(preload("res://scripts/ui/equipment_icon.gd").weapon_type(ContentCatalog.equipment[recipe.result]) == "hammer")
	forge._filter("weapon", "spear")
	for frame in 16: await tree.process_frame
	assert(not forge.matched_recipes.is_empty())
	main.queue_free()
	await tree.process_frame
	save.data = previous
	save.save_game()
	TalentManager.set_class(str(previous.selected_class))
	print("PASS: all 91 original models used, class columns, paired evolving shields, 140 real new items/120 recipes, native atlas filtering, saved equipped model/profile and accurate weapon type filters")
