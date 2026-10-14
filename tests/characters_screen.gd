extends RefCounted

func run(tree: SceneTree) -> void:
	assert(str(ProjectSettings.get_setting("application/config/name")).begins_with("Ashenwild Regression"))
	var save: Node = tree.root.get_node("SaveManager")
	var previous: Dictionary = save.data.duplicate(true)
	var old_size: Vector2i = tree.root.size
	var old_scale: Vector2i = tree.root.content_scale_size
	save.data = save.DEFAULT_SAVE.duplicate(true)
	save._initialize_progression(false)
	save.data.gold = 2000
	save.data.crystals = 30
	save.data.class_progression.mage.xp = 160
	save.data.statistics.class_runs.mage = 7
	tree.root.size = Vector2i(1280, 720)
	tree.root.content_scale_size = Vector2i(1280, 720)
	var main: Node = load("res://scenes/main.tscn").instantiate()
	tree.root.add_child(main)
	main._build_page("prepare")
	main._build_page("characters")
	await _settle(tree)
	var panel: Node = main.page_root.find_child("CharactersPanel", true, false)
	assert(main.page_scroll == null and panel.visible_ids == ["warrior", "mage", "ranger"])
	assert(panel.find_child("ClassLevel_mage", true, false).text.begins_with("NÍVEL 2"))
	assert(panel.find_child("ClassRuns_mage", true, false).text.begins_with("7 expedições"))
	assert(panel.find_child("BaseStat_warrior_VIDA", true, false).text == "420")
	panel.find_child("SelectClass_mage", true, false).pressed.emit()
	await _settle(tree)
	assert(main.selected_class == "mage" and save.data.selected_class == "mage" and TalentManager.class_id == "mage")
	assert(panel == main.page_root.find_child("CharactersPanel", true, false), "Selection updates in place")
	assert(panel.find_child("SelectClass_mage", true, false).disabled)
	panel.change_page(1)
	await _settle(tree)
	assert(panel.visible_ids == ["assassin", "druid", "paladin"])
	panel.find_child("Recruit_assassin_gold", true, false).pressed.emit()
	await _settle(tree)
	assert(save.is_class_unlocked("assassin") and save.data.gold == 1550 and save.data.crystals == 30)
	assert(str(save.loadout_for("assassin").weapon) == str(ContentCatalog.classes.assassin.starter_weapon))
	assert(main.selected_class == "assassin" and panel.page_index == 1)
	assert(panel.notice.text.contains("Arma inicial equipada"))
	panel.find_child("Recruit_druid_crystals", true, false).pressed.emit()
	await _settle(tree)
	assert(save.is_class_unlocked("druid") and save.data.gold == 1550 and save.data.crystals == 21)
	assert(main.selected_class == "druid")
	save.load_game()
	assert(save.data.selected_class == "druid" and save.is_class_unlocked("assassin") and save.is_class_unlocked("druid"))
	assert(save.data.class_progression.mage.xp == 160)
	save.data.gold = 0
	save.data.crystals = 0
	panel.refresh()
	assert(panel.find_child("Recruit_paladin_gold", true, false).disabled)
	assert(panel.find_child("Recruit_paladin_crystals", true, false).disabled)
	for resolution in [Vector2i(1280, 720), Vector2i(800, 600), Vector2i(640, 360), Vector2i(390, 844), Vector2i(320, 640)]:
		for scale in [0.85, 1.2]:
			tree.root.size = resolution
			tree.root.content_scale_size = resolution
			save.data.settings.ui_scale = scale
			main._build_page("characters")
			await _settle(tree)
			panel = main.page_root.find_child("CharactersPanel", true, false)
			assert(panel.selected_class == "druid")
			panel.page_index = 0
			var ids: Dictionary = {}
			for page in ceili(6.0 / panel.page_size):
				panel.refresh()
				await _settle(tree)
				for id in panel.visible_ids: ids[id] = true
				var viewport: Control = main.page_root.find_child("OnlineViewport", true, false)
				assert(main.page_scroll == null and viewport.content.scale.x >= 0.94, "Class gallery must fit without shrinking: %s factor %s minimum %s available %s" % [resolution, viewport.content.scale, viewport.content.get_combined_minimum_size(), viewport.size])
				assert(viewport.content.get_global_rect().end.y <= viewport.get_global_rect().end.y + 2)
				for label in panel.find_children("CharacterCurrency*", "Label", true, false): assert(label.autowrap_mode == TextServer.AUTOWRAP_OFF)
				for button in panel.find_children("*", "Button", true, false):
					if not button.is_visible_in_tree(): continue
					var bounds: Rect2 = button.get_global_rect()
					assert(bounds.position.x >= viewport.get_global_rect().position.x - 2 and bounds.end.x <= viewport.get_global_rect().end.x + 2, "Class button overflow: %s %s" % [resolution, button.name])
					assert(bounds.size.x >= 24 and bounds.size.y >= 24)
				panel.change_page(1)
			assert(ids.size() == 6)
	main._go_back()
	assert(main.page_name == "prepare")
	main.queue_free()
	await tree.process_frame
	tree.root.size = old_size
	tree.root.content_scale_size = old_scale
	save.data = previous
	save.save_game()
	TalentManager.set_class(str(previous.selected_class))
	print("PASS: six animated class cards, real stats/XP/runs, in-place selection, gold/crystal recruitment, starter equipment, persistence, locked prices, back navigation and full gallery at five resolutions/two scales")

func _settle(tree: SceneTree) -> void:
	for frame in 16: await tree.process_frame
