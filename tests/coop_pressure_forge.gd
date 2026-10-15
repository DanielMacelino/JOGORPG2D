extends RefCounted
const COMPARE := preload("res://scripts/systems/equipment_comparison.gd")

func run(tree: SceneTree) -> void:
	assert(str(ProjectSettings.get_setting("application/config/name")).begins_with("Ashenwild Regression"))
	_test_pressure(tree)
	var candidate := EquipmentData.new()
	candidate.stat = &"damage"
	candidate.stat_amount = 10
	candidate.bonuses = {"damage": 2, "defense": 3, "crit_chance": 0.04}
	var equipped := EquipmentData.new()
	equipped.stat = &"damage"
	equipped.stat_amount = 15
	equipped.bonuses = {"crit_chance": 0.06, "speed_pct": 0.10}
	var values := {}
	for row in COMPARE.rows(candidate, equipped): values[row.key] = row
	assert(values.damage.after == 12 and values.damage.before == 15 and values.damage.delta == -3)
	assert(values.defense.delta == 3 and is_equal_approx(values.speed_pct.delta, -0.10))
	assert(is_equal_approx(values.crit_chance.delta, -0.02))
	assert(COMPARE.rows(candidate, null).size() == 3)
	assert(COMPARE.number("crit_chance", 0.04) == "4%")
	assert(COMPARE.number("crit_chance", -0.02, true) == "−2 p.p.")
	assert(COMPARE.number("health", 420) == "420")
	await _test_ui(tree)
	print("PASS: multiplayer enemy/boss damage +20/30/40 percent above party scaling, solo unchanged, craftable action, exact gains/losses, class-specific equipped comparison and no-scroll recipe/compare modes")

func _test_pressure(tree: SceneTree) -> void:
	var session: Node = tree.root.get_node("NetworkSession")
	var old := {"running": session.running, "hosting": session.hosting, "active": session.active, "players": session.players.duplicate(true)}
	session.active = false
	session.running = false
	var arena := Node2D.new()
	tree.root.add_child(arena)
	var player := SurvivorPlayer.new()
	player.configure("warrior", {})
	arena.add_child(player)
	var manager := EnemyManager.new()
	arena.add_child(manager)
	manager.configure(arena, player, ContentCatalog.maps.verdant_reach)
	for kind in [&"slime", &"goblin_king"]:
		var base := manager.spawn(kind, 4, Vector2(500, 0))
		var damage := base.damage
		var health := base.max_health
		for count in range(1, 5):
			session.players = {}
			for peer in count: session.players[peer + 1] = {}
			session.hosting = true
			session.running = true
			var actor := manager.spawn(kind, 4, Vector2(600, 0))
			var boost: float = [1.0, 1.2, 1.3, 1.4][count - 1]
			assert(is_equal_approx(actor.damage, damage * (1 + 0.08 * (count - 1)) * boost))
			assert(is_equal_approx(actor.max_health, health * (1 + 0.8 * (count - 1))))
			session.running = false
	assert(is_equal_approx(EnemyManager.party_damage_pressure(0), 1.0))
	session.running = old.running
	session.hosting = old.hosting
	session.active = old.active
	session.players = old.players
	arena.free()

func _test_ui(tree: SceneTree) -> void:
	var save: Node = tree.root.get_node("SaveManager")
	var previous: Dictionary = save.data.duplicate(true)
	var old_size: Vector2i = tree.root.size
	var old_scale: Vector2i = tree.root.content_scale_size
	save.data = save.DEFAULT_SAVE.duplicate(true)
	save._initialize_progression(false)
	save.data.gold = 100000
	save.data.crystals = 1000
	tree.root.size = Vector2i(1280, 720)
	tree.root.content_scale_size = Vector2i(1280, 720)
	var main: Node = load("res://scenes/main.tscn").instantiate()
	tree.root.add_child(main)
	main._build_page("forge")
	await _settle(tree)
	var panel: Node = main.page_root.find_child("ForgePanel", true, false)
	var all_count: int = panel.matched_recipes.size()
	panel.craftable_button.button_pressed = true
	assert(panel.draft.possible and panel.matched_recipes.size() < all_count and not panel.matched_recipes.is_empty())
	for recipe in panel.matched_recipes: assert(save.can_forge(str(recipe.id)))
	panel.craftable_button.button_pressed = false
	assert(not panel.draft.possible and panel.matched_recipes.size() == all_count)
	panel._select_recipe("forge_void_staff", true)
	assert(panel.draft.comparing)
	var label: Label = panel.find_child("ForgeEquippedComparison", true, false)
	assert(label.text.contains("Tecelã") and label.text.contains(ContentCatalog.equipment.moon_staff.display_name))
	panel.find_child("ForgeCompare", true, false).pressed.emit()
	assert(not panel.draft.comparing and panel.find_child("ForgeIngredients", true, false) != null)
	for resolution in [Vector2i(1280, 720), Vector2i(960, 540), Vector2i(640, 360), Vector2i(390, 844), Vector2i(320, 640)]:
		tree.root.size = resolution
		tree.root.content_scale_size = resolution
		main._build_page("forge")
		await _settle(tree)
		panel = main.page_root.find_child("ForgePanel", true, false)
		for id in ["forge_flame_sword", "forge_void_staff"]:
			panel._select_recipe(id, true)
			await _settle(tree)
			_check_geometry(main, panel, resolution)
			for index in 4:
				panel.draft.compare_page = index
				panel._render_details()
				await _settle(tree)
				_check_geometry(main, panel, resolution)
			panel.find_child("ForgeCompare", true, false).pressed.emit()
			await _settle(tree)
			_check_geometry(main, panel, resolution)
		panel._section(1)
		panel.craftable_button.button_pressed = true
		await _settle(tree)
		_check_geometry(main, panel, resolution)
		panel.craftable_button.button_pressed = false
	main.queue_free()
	await tree.process_frame
	tree.root.size = old_size
	tree.root.content_scale_size = old_scale
	save.data = previous
	save.save_game()
	TalentManager.set_class(str(previous.selected_class))

func _check_geometry(main: Node, panel: Node, resolution: Vector2i) -> void:
	var viewport: Control = main.page_root.find_child("OnlineViewport", true, false)
	assert(viewport.content.scale.x >= 0.94, "Forge comparison layout: %s %s %s min %s available %s" % [resolution, panel.draft.comparing, viewport.content.scale, viewport.content.get_combined_minimum_size(), viewport.size])
	assert(main.page_scroll == null)
	for button in panel.find_children("*", "Button", true, false):
		if not button.is_visible_in_tree(): continue
		var bounds: Rect2 = button.get_global_rect()
		assert(bounds.position.x >= viewport.get_global_rect().position.x - 2 and bounds.end.x <= viewport.get_global_rect().end.x + 2)
		assert(bounds.size.y >= 24)

func _settle(tree: SceneTree) -> void:
	for frame in 12: await tree.process_frame
