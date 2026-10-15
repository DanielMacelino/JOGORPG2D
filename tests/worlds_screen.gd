extends RefCounted

func run(tree: SceneTree) -> void:
	var save: Node = tree.root.get_node("SaveManager")
	var old: Dictionary = save.data.duplicate(true)
	var old_size: Vector2i = tree.root.size
	var old_scale: Vector2i = tree.root.content_scale_size
	save.data = save.DEFAULT_SAVE.duplicate(true)
	save._initialize_progression(false)
	var main: Node = load("res://scenes/main.tscn").instantiate()
	tree.root.add_child(main)
	for ui_scale in [1.0, 1.2]:
		save.data.settings.ui_scale = ui_scale
		for resolution in [Vector2i(1280, 720), Vector2i(1024, 578), Vector2i(800, 600), Vector2i(640, 360), Vector2i(390, 844), Vector2i(320, 640)]:
			tree.root.size = resolution
			main._build_page("maps")
			await _settle(tree)
			var panel: Node = main.page_root.find_child("WorldsPanel", true, false)
			var fit: Node = main.page_root.find_child("OnlineViewport", true, false)
			assert(fit != null and main.page_scroll == null)
			assert(fit.content.scale.x >= 0.85, "World readability %s scale %s: %s" % [resolution, ui_scale, fit.content.scale])
			assert(panel.world_list.get_child_count() == 6)
			assert(panel.find_child("WorldPhases", true, false).get_child_count() == 10)
			assert(main.backdrop_layer.get_child(0).worlds, "Atlas backdrop must replace the castle backdrop on this page")
			assert(panel.find_child("WorldBanner", true, false).IMAGE.resource_path == "res://assets/art/world-atlas.png")
			if not panel.short_window:
				assert(panel.find_child("WorldRewards", true, false).get_child_count() == 3, "Keep rewards visible at the reference resolution")
				if not panel.narrow: assert(panel.find_child("WorldPhaseLegend", true, false) != null)
			for stage in panel.find_child("WorldPhases", true, false).get_children():
				assert(stage.region_theme == ContentCatalog.maps[panel.browse].theme)
				assert(stage.disabled == not stage.available)
			var picker: OptionButton = panel.find_child("WorldDifficulty", true, false)
			assert(picker.selected == 0 and not picker.is_item_disabled(0) and picker.is_item_disabled(1))
			for button in main.page_root.find_children("*", "BaseButton", true, false):
				if not button.is_visible_in_tree(): continue
				var rect: Rect2 = button.get_global_rect()
				assert(rect.size.x >= 24 and rect.size.y >= 24, "World hit area %s %s: %s" % [resolution, button.name, rect])
				assert(rect.position.x >= -1 and rect.end.x <= tree.root.get_visible_rect().size.x + 1)
				assert(rect.end.y <= tree.root.get_visible_rect().size.y + 1, "World vertical bounds %s %s: %s" % [resolution, button.name, rect])
			panel.find_child("World_hollow_cairn", true, false).pressed.emit()
			await _settle(tree)
			assert(panel.browse == "hollow_cairn" and panel.find_child("WorldStart", true, false).disabled)
			assert(panel.find_child("WorldPhase_10", true, false).region_theme == &"graveyard")
			assert(main.selected_map == "verdant_reach", "Inspecting a locked world cannot change the playable destination")
			panel.find_child("World_verdant_reach", true, false).pressed.emit()
			await _settle(tree)
			assert(not panel.find_child("WorldStart", true, false).disabled)
			if panel.narrow:
				panel.find_child("WorldSection_0", true, false).pressed.emit()
				await _settle(tree)
				assert(panel.world_list.is_visible_in_tree() and not panel.details_frame.visible)
				for card in panel.world_list.get_children():
					var rect: Rect2 = card.get_global_rect()
					assert(rect.size.x >= 24 and rect.size.y >= 24 and rect.end.y <= tree.root.get_visible_rect().size.y + 1)
				panel.find_child("WorldSection_1", true, false).pressed.emit()
				await _settle(tree)
	# One clear of a world is insufficient; all sixty stages are required.
	for ordinal in 59:
		assert(save.complete_phase(str(ContentCatalog.MAP_ORDER[floori(float(ordinal) / 10)]), ordinal % 10 + 1, 0))
	assert(save.campaign_cleared(0) == 59 and int(save.data.highest_difficulty) == 0)
	assert(not save.phase_unlocked("verdant_reach", 1, 1))
	assert(save.complete_phase("sunken_mire", 10, 0))
	assert(int(save.data.highest_difficulty) == 1 and save.campaign_cleared(1) == 0)
	main._build_page("maps")
	await _settle(tree)
	var panel: Node = main.page_root.find_child("WorldsPanel", true, false)
	var picker: OptionButton = panel.find_child("WorldDifficulty", true, false)
	assert(not picker.is_item_disabled(1) and picker.is_item_disabled(2))
	picker.item_selected.emit(1)
	await _settle(tree)
	assert(main.selected_difficulty == 1 and main.selected_map == "verdant_reach" and main.selected_phase == 1)
	assert(save.phase_completed("sunken_mire", 10, 0) and not save.phase_completed("verdant_reach", 1, 1))
	# Launch uses the world being previewed, even when a different destination was saved.
	main._select_difficulty(0)
	await _settle(tree)
	panel = main.page_root.find_child("WorldsPanel", true, false)
	panel.find_child("WorldPhase_05", true, false).pressed.emit()
	await _settle(tree)
	assert(main.selected_map == "sunken_mire" and main.selected_phase == 5)
	assert(save.data.selected_map == "sunken_mire" and int(save.data.selected_phase) == 5)
	panel = main.page_root.find_child("WorldsPanel", true, false)
	panel.find_child("World_hollow_cairn", true, false).pressed.emit()
	await _settle(tree)
	panel.find_child("WorldStart", true, false).pressed.emit()
	await _settle(tree)
	assert(main.active_game.map_id == "hollow_cairn" and main.active_game.phase_number == 10)
	main._return_to_menu()
	await _settle(tree)
	main._build_page("maps")
	await _settle(tree)
	main.page_root.find_child("WorldsBack", true, false).pressed.emit()
	assert(main.page_name == "home")
	assert(not main.backdrop_layer.get_child(0).worlds, "Leaving the atlas must restore the menu artwork")
	main.queue_free()
	await tree.process_frame
	tree.root.size = old_size
	tree.root.content_scale_size = old_scale
	save.data = old
	save.save_game()
	TalentManager.set_class(str(old.selected_class))
	print("PASS: illustrated world atlas, landmarks, visible rewards and legends, 6 regions/10 phases, locked previews, real launch, difficulty picker, 59/60 gate and next cycle, six resolutions/two scales without scrolling")

func _settle(tree: SceneTree) -> void:
	for frame in 20: await tree.process_frame
