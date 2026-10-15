extends RefCounted

func nodes(node: Node, kind: String) -> Array[Node]:
	var result: Array[Node] = []
	if node.is_class(kind): result.append(node)
	for child in node.get_children(): result.append_array(nodes(child, kind))
	return result

func equipment_icons(node: Node) -> Array[Node]:
	return nodes(node, "Control").filter(func(control: Node) -> bool: return control.get_script() == preload("res://scripts/ui/equipment_icon.gd"))

func settle(tree: SceneTree) -> void:
	for frame in 8: await tree.process_frame

func click(main: Node, text: String) -> void:
	for button in nodes(main.page_scroll if main.page_scroll != null else main.page_root, "Button"):
		if button.text == text:
			button.pressed.emit()
			return
	assert(false, "Missing filter: " + text)

func labels(main: Node) -> String:
	var text := ""
	for label in nodes(main.page_root, "Label"): text += label.text + "\n"
	return text

func run(tree: SceneTree) -> void:
	var save: Node = tree.root.get_node("SaveManager")
	save.data = save.DEFAULT_SAVE.duplicate(true)
	save._initialize_progression(false)
	save.data.gold = 100000
	var main = load("res://scenes/main.tscn").instantiate()
	tree.root.add_child(main)
	var previous_size: Vector2i = tree.root.size
	var previous_scale: Vector2i = tree.root.content_scale_size
	tree.root.size = Vector2i(390, 844)
	tree.root.content_scale_size = Vector2i(390, 844)
	main._build_page("prepare")
	main._build_page("upgrades")
	await settle(tree)
	assert(main.page_scroll == null, "Upgrades no longer need scrolling")
	var upgrade_panel: Node = main.page_root.find_child("UpgradesPanel", true, false)
	upgrade_panel.set_filter("strength")
	var page_before: int = upgrade_panel.page_index
	main._buy_upgrade("might", 100)
	await settle(tree)
	assert(save.upgrade_level("might") == 1)
	assert(upgrade_panel == main.page_root.find_child("UpgradesPanel", true, false))
	assert(upgrade_panel.page_index == page_before and upgrade_panel.filter_id == "strength", "Buying upgrades must preserve navigation")
	for filter_name in ["Força", "Habilidades", "Movimento", "Defesa", "Economia", "Todos"]:
		click(main, filter_name)
		await settle(tree)
		assert(main.page_scroll == null and upgrade_panel.page_index == 0)
		var buy_count := 0
		for button in nodes(main.page_root, "Button"):
			if button.is_visible_in_tree() and button.text.begins_with("APRIMORAR"): buy_count += 1
		assert(buy_count > 0 and (buy_count == 1 if filter_name == "Movimento" else true))
	main._go_back()
	assert(main.page_name == "prepare", "Back must return to the preceding page")
	main._build_page("forge")
	await settle(tree)
	var forge = main.page_root.find_child("ForgePanel", true, false)
	var all_count: int = forge.matched_recipes.size()
	var all_icons := equipment_icons(main.page_root).size()
	var mage_index := 0
	for index in forge.class_picker.item_count:
		if str(forge.class_picker.get_item_metadata(index)) == "mage": mage_index = index
	forge.class_picker.select(mage_index)
	forge.class_picker.item_selected.emit(mage_index)
	await settle(tree)
	assert(forge.matched_recipes.size() < all_count and equipment_icons(main.page_root).size() > 0)
	for icon in equipment_icons(main.page_root): assert(icon.item != null and icon.item.class_id in [&"", &"mage"])
	forge.class_picker.select(0)
	forge.class_picker.item_selected.emit(0)
	await settle(tree)
	assert(forge.matched_recipes.size() == all_count and equipment_icons(main.page_root).size() == all_icons)
	main._go_back()
	assert(main.page_name == "prepare")
	main.queue_free()
	await tree.process_frame
	tree.root.size = previous_size
	tree.root.content_scale_size = previous_scale

	var manager := AbilityManager.new()
	manager.reset(&"", "mage")
	manager.levels = {"rapid_hands": 4}
	assert(manager.grant(&"rapid_hands") and manager.level_of(&"rapid_hands") == 5)
	assert(not manager.grant(&"rapid_hands") and not manager.chooseable().has(&"rapid_hands"))
	for index in 30:
		for ability in manager.roll_choices(): assert(ability.id != &"rapid_hands")
	var screen = load("res://scripts/ui/ability_choice_screen.gd").new()
	screen.choices = [&"rapid_hands", &"keen_edge"]
	screen.ranks = {"rapid_hands": 5, "keen_edge": 4}
	tree.root.add_child(screen)
	await settle(tree)
	assert(screen.grid.get_child_count() == 1 and screen.grid.get_child(0).current_rank == 4)
	var rank_text := ""
	for label in nodes(screen, "Label"): rank_text += label.text
	assert(rank_text.contains("4 → 5"))
	screen.queue_free()
	manager.free()
	await tree.process_frame

	var player := SurvivorPlayer.new()
	player.configure("mage", {})
	var ally := SurvivorPlayer.new()
	ally.configure("ranger", {})
	var before := player.health
	player.take_damage(999.0, true, ally)
	var projectile := Node.new()
	projectile.set_meta("team", "players")
	player.take_damage(999.0, true, projectile)
	assert(player.health == before and not player.is_dead, "Allied attacks must never damage players")
	projectile.set_meta("team", "enemies")
	player.take_damage(5.0, true, projectile)
	assert(player.health < before)
	player.free()
	ally.free()
	projectile.free()

	var enemy := ChaserEnemy.new()
	var boss_data: EnemyData = tree.root.get_node("ContentCatalog").enemies["goblin_king"]
	enemy.configure(boss_data, null, 5)
	assert(is_equal_approx(enemy.max_health, boss_data.max_health * 13.5))
	enemy.free()
	assert(CampaignRules.reward_multiplier(0, 5) > CampaignRules.reward_multiplier(0, 6))
	print("PASS: upgrade scroll, filters, forge icons, page history, max-rank exclusion, 4→5 labels, friendly-fire protection and boss health")
