extends RefCounted

func run(tree: SceneTree) -> void:
	assert(str(ProjectSettings.get_setting("application/config/name")).begins_with("Ashenwild Regression"))
	var save: Node = tree.root.get_node("SaveManager")
	var previous: Dictionary = save.data.duplicate(true)
	var old_size: Vector2i = tree.root.size
	var old_scale: Vector2i = tree.root.content_scale_size
	save.data = save.DEFAULT_SAVE.duplicate(true)
	save._initialize_progression(false)
	save.data.gold = 100000
	var main: Control = load("res://scenes/main.tscn").instantiate()
	tree.root.add_child(main)
	main._build_page("prepare")
	main._build_page("upgrades")
	await _settle(tree)
	var panel: Node = main.page_root.find_child("UpgradesPanel", true, false)
	assert(main.page_scroll == null)
	panel.set_filter("strength")
	assert(panel.matched_ids == ["might", "crit_mastery"])
	panel.select_upgrade("might")
	var cost := PermanentUpgrades.cost("might", save.data.upgrades)
	var gold: int = save.data.gold
	panel.find_child("SelectedUpgradeAction", true, false).pressed.emit()
	await _settle(tree)
	assert(save.upgrade_level("might") == 1 and save.data.gold == gold - cost)
	assert(panel == main.page_root.find_child("UpgradesPanel", true, false), "Purchase must refresh in place")
	assert(panel.filter_id == "strength" and panel.selected_id == "might" and panel.page_index == 0)
	assert(panel.find_child("UpgradeBonusPreview", true, false).text.contains("+0,1% → +0,2%"))
	save.load_game()
	assert(save.upgrade_level("might") == 1 and save.data.gold == gold - cost)
	for rank in range(1, 10): assert(panel.purchase("might"))
	gold = save.data.gold
	assert(not panel.purchase("might") and save.data.gold == gold, "Tier gate must block extra purchases")
	assert(panel.find_child("SelectedUpgradeAction", true, false).disabled)
	for id in PermanentUpgrades.IDS: save.data.upgrades[id] = 10
	save.data.upgrades.might = 9
	panel._refresh()
	assert(panel.mastery_bar.value == 79)
	assert(panel.purchase("might"))
	assert(panel.mastery_bar.value == 0 and panel.mastery_label.text.contains("PATAMAR 2"))
	assert(panel.mastery_label.text.contains("+0,5%") and panel._local_rank("might") == 0)
	assert(panel.find_child("UpgradeBonusPreview", true, false).text.contains("+1% → +1,5%"))
	save.data.gold = 0
	panel._refresh()
	assert(panel.find_child("SelectedUpgradeAction", true, false).disabled)
	assert(not panel.purchase("might") and save.data.gold == 0)
	save.data.gold = 100000
	for resolution in [Vector2i(1280, 720), Vector2i(960, 540), Vector2i(640, 360), Vector2i(390, 844), Vector2i(320, 640)]:
		for scale in [0.85, 1.2]:
			tree.root.size = resolution
			tree.root.content_scale_size = resolution
			save.data.settings.ui_scale = scale
			main._build_page("upgrades")
			await _settle(tree)
			panel = main.page_root.find_child("UpgradesPanel", true, false)
			assert(panel.filter_id == "strength" and panel.selected_id == "might")
			for entry in panel.FILTERS:
				panel.set_filter(str(entry[1]))
				panel._set_section(0)
				await _settle(tree)
				assert(not panel.matched_ids.is_empty())
				_check_geometry(main, panel, resolution)
			panel.set_filter("all")
			var ids: Dictionary = {}
			for page in ceili(8.0 / panel.page_size):
				for id in panel.visible_ids: ids[id] = true
				panel._change_page(1)
			assert(ids.size() == 8, "Every upgrade accessible without scrolling")
			for id in PermanentUpgrades.IDS:
				panel.select_upgrade(id, true)
				await _settle(tree)
				_check_geometry(main, panel, resolution)
			panel.set_filter("strength")
			panel.select_upgrade("might")
	main._go_back()
	assert(main.page_name == "prepare")
	main.queue_free()
	await tree.process_frame
	tree.root.size = old_size
	tree.root.content_scale_size = old_scale
	save.data = previous
	save.save_game()
	print("PASS: permanent upgrade cabinet, canonical purchases, stable navigation, six filters, all eight attributes, real bonus previews, tier transition, insufficient gold, persistence and no-scroll layout at five resolutions/two scales")

func _check_geometry(main: Node, panel: Node, resolution: Vector2i) -> void:
	var viewport: Control = main.page_root.find_child("OnlineViewport", true, false)
	assert(viewport.content.scale.x >= 0.94, "Upgrade text must fit without shrinking: %s factor %s minimum %s viewport %s selection %s" % [resolution, viewport.content.scale, viewport.content.get_combined_minimum_size(), viewport.size, panel.selected_id])
	assert(viewport.content.get_global_rect().end.y <= viewport.get_global_rect().end.y + 2)
	for label in panel.find_children("UpgradeCurrency*", "Label", true, false): assert(label.autowrap_mode == TextServer.AUTOWRAP_OFF)
	for button in panel.find_children("*", "Button", true, false):
		if not button.is_visible_in_tree(): continue
		var bounds: Rect2 = button.get_global_rect()
		assert(bounds.position.x >= viewport.get_global_rect().position.x - 2 and bounds.end.x <= viewport.get_global_rect().end.x + 2, "Upgrade button overflow: %s %s bounds %s viewport %s filter %s" % [resolution, button.name, bounds, viewport.get_global_rect(), panel.filter_id])
		assert(bounds.size.x >= 24 and bounds.size.y >= 24)
	for scroll in panel.find_children("*", "ScrollContainer", true, false): assert(not scroll.is_visible_in_tree())

func _settle(tree: SceneTree) -> void:
	for frame in 16: await tree.process_frame
