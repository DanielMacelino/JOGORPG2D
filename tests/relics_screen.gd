extends RefCounted

func run(tree: SceneTree) -> void:
	assert(str(ProjectSettings.get_setting("application/config/name")).begins_with("Ashenwild Regression"))
	var save: Node = tree.root.get_node("SaveManager")
	var previous: Dictionary = save.data.duplicate(true)
	var old_size: Vector2i = tree.root.size
	var old_scale: Vector2i = tree.root.content_scale_size
	save.data = save.DEFAULT_SAVE.duplicate(true)
	save._initialize_progression(false)
	var main: Control = load("res://scenes/main.tscn").instantiate()
	tree.root.add_child(main)
	main._build_page("relics")
	await _settle(tree)
	var panel: Control = main.page_root.find_child("RelicsPanel", true, false)
	assert(panel != null and main.page_scroll == null)
	assert(panel.count_label.text.contains("0/12"))
	assert(panel.find_child("SelectedRelicAction", true, false).disabled)
	panel.toggle_relic("blood_pact")
	assert(save.get_equipped_relics().is_empty(), "Locked relic cannot be equipped")
	panel.select_relic("blood_pact")
	assert(panel.find_child("RelicUnlockCondition", true, false).text == "Derrote um chefe com este personagem.")
	var textures: Dictionary = {}
	for data in ContentCatalog.relics:
		textures[panel.COPY.texture(str(data.id)).resource_path] = true
	assert(textures.size() == 12, "Each relic needs its own illustration")
	for id in ["blood_pact", "golden_compass", "soul_lantern", "cursed_eye", "mirror_shield"]:
		save.unlock_relic(id)
	for id in ["blood_pact", "golden_compass", "soul_lantern"]:
		panel.toggle_relic(id)
	assert(save.get_equipped_relics().size() == 3)
	panel.toggle_relic("cursed_eye")
	assert(save.get_equipped_relics().size() == 3 and not save.is_relic_equipped("cursed_eye"))
	assert(panel.find_child("SelectedRelicAction", true, false).disabled)
	panel.find_child("RelicSlot0", true, false).pressed.emit()
	assert(panel.selected_id == "blood_pact")
	panel.find_child("SelectedRelicAction", true, false).pressed.emit()
	assert(not save.is_relic_equipped("blood_pact"))
	panel.toggle_relic("cursed_eye")
	assert(save.is_relic_equipped("cursed_eye"))
	save.load_game()
	assert(save.get_equipped_relics().size() == 3 and save.is_relic_equipped("cursed_eye"))
	for resolution in [Vector2i(1280, 720), Vector2i(960, 540), Vector2i(640, 360), Vector2i(390, 844), Vector2i(360, 640)]:
		for scale in [0.85, 1.2]:
			tree.root.size = resolution
			tree.root.content_scale_size = resolution
			save.data.settings.ui_scale = scale
			main._build_page("relics")
			await _settle(tree)
			panel = main.page_root.find_child("RelicsPanel", true, false)
			assert(panel.selected_id == "cursed_eye", "Selection survives responsive rebuild")
			var all_ids: Dictionary = {}
			panel.page_index = 0
			for index in ceili(12.0 / panel.page_size):
				panel._refresh_cards()
				for id in panel.visible_ids: all_ids[id] = true
				panel._change_page(1)
			assert(all_ids.size() == 12, "All relics accessible without scrolling")
			for section in 2:
				panel._set_section(section)
				await _settle(tree)
				var viewport: Control = main.page_root.find_child("OnlineViewport", true, false)
				assert(viewport.content.get_global_rect().end.y <= viewport.get_global_rect().end.y + 2)
				assert(viewport.content.scale.x >= 0.93, "Relics should fit without shrinking text: %s %s factor %s minimum %s viewport %s" % [resolution, scale, viewport.content.scale, viewport.content.get_combined_minimum_size(), viewport.size])
				for currency in panel.find_children("RelicCurrency*", "Label", true, false):
					assert(currency.autowrap_mode == TextServer.AUTOWRAP_OFF)
				for scroll in panel.find_children("*", "ScrollContainer", true, false):
					assert(not scroll.is_visible_in_tree())
				var back_buttons := panel.find_children("RelicsBack", "Button", true, false)
				assert(back_buttons.size() == 1)
				for button in panel.find_children("*", "Button", true, false):
					if not button.is_visible_in_tree(): continue
					var bounds: Rect2 = button.get_global_rect()
					assert(bounds.position.x >= viewport.get_global_rect().position.x - 2)
					assert(bounds.end.x <= viewport.get_global_rect().end.x + 2)
					assert(bounds.size.y >= 20 and bounds.size.x >= 20)
			# The longest descriptions and locked achievement requirements also have to fit.
			for data in ContentCatalog.relics:
				panel.select_relic(str(data.id), true)
				await _settle(tree)
				var viewport: Control = main.page_root.find_child("OnlineViewport", true, false)
				assert(viewport.content.scale.x >= 0.93, "Relic details overflow: %s at %s, factor %s" % [data.id, resolution, viewport.content.scale])
			panel.select_relic("cursed_eye")
	main.queue_free()
	await tree.process_frame
	tree.root.size = old_size
	tree.root.content_scale_size = old_scale
	save.data = previous
	save.save_game()
	print("PASS: relic artwork, real unlocks, 3 slots, equip/remove persistence, full pagination, selection retention, no scroll and 5 resolutions / 2 scales")

func _settle(tree: SceneTree) -> void:
	for frame in 16: await tree.process_frame
