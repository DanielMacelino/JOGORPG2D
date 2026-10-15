extends RefCounted

func run(tree: SceneTree) -> void:
	var save: Node = tree.root.get_node("SaveManager")
	var previous: Dictionary = save.data.duplicate(true)
	var previous_size := tree.root.size
	var previous_scale := tree.root.content_scale_size
	save.data = save.DEFAULT_SAVE.duplicate(true)
	save._initialize_progression(false)
	var main: Node = load("res://scenes/main.tscn").instantiate()
	tree.root.add_child(main)
	for ui_scale in [1.0, 1.2]:
		save.data.settings.ui_scale = ui_scale
		for resolution in [Vector2i(1280, 720), Vector2i(1024, 578), Vector2i(960, 540), Vector2i(800, 600), Vector2i(640, 480), Vector2i(640, 360), Vector2i(390, 844), Vector2i(320, 640)]:
			tree.root.size = resolution
			main._build_page("home")
			await _settle(tree)
			var home: Node = main.page_root.find_child("HomeScreen", true, false)
			var fit: Node = main.page_root.find_child("OnlineViewport", true, false)
			assert(main.page_scroll == null and fit != null, "Home must not require scrolling")
			assert(fit.content.scale.x >= 0.85, "Home readability %s scale %s: %s" % [resolution, ui_scale, fit.content.scale])
			assert(home.navigation.get_child_count() == 5)
			var play: Button = home.find_child("HomePlay", true, false)
			var online: Button = home.find_child("HomeOnline", true, false)
			var settings: Button = home.find_child("HomeSettings", true, false)
			assert(play.surface.gold and not online.surface.gold and not settings.surface.gold)
			assert(play.surface.show_behind_parent and online.surface.mouse_filter == Control.MOUSE_FILTER_IGNORE)
			assert(online.get_parent() == settings.get_parent() and is_equal_approx(online.size.y, settings.size.y))
			if resolution.x >= 900:
				var first: Control = home.navigation.get_child(0)
				for tile in home.navigation.get_children(): assert(absf(tile.position.y - first.position.y) <= 1, "All five plaques must share a row at reference width")
			for button in home.find_children("*", "Button", true, false):
				var rect: Rect2 = button.get_global_rect()
				assert(rect.size.x >= 24 and rect.size.y >= 24, "Home hit area %s %s: %s" % [resolution, button.name, rect])
				assert(rect.position.x >= -1 and rect.end.x <= tree.root.get_visible_rect().size.x + 1)
				assert(rect.position.y >= -1 and rect.end.y <= tree.root.get_visible_rect().size.y + 1, "Home vertical bounds %s: %s" % [resolution, rect])
			var before := play.get_global_rect()
			play.mouse_entered.emit()
			await _settle(tree)
			assert(play.get_global_rect().is_equal_approx(before))
	# Exercise every native callback; the decorative textures cannot intercept clicks.
	tree.root.size = Vector2i(1024, 578)
	for index in 5:
		main._build_page("home")
		await _settle(tree)
		var home: Node = main.page_root.find_child("HomeScreen", true, false)
		var tile: Button = home.navigation.get_child(index)
		var page: String = tile.page
		tile.pressed.emit()
		await _settle(tree)
		assert(main.page_name == page)
		main._go_back()
		assert(main.page_name == "home")
	for route in [["HomeSettings", "settings"], ["HomeOnline", "online"]]:
		main._build_page("home")
		await _settle(tree)
		main.page_root.find_child(route[0], true, false).pressed.emit()
		assert(main.page_name == route[1])
	main._build_page("maps")
	await tree.create_timer(0.25).timeout
	assert(is_equal_approx(main.page_root.modulate.a, 1.0), "Worlds page must be completely opaque after its entrance")
	var worlds: Node = main.page_root.find_child("WorldsPanel", true, false)
	assert(is_equal_approx(worlds.details_frame.get_theme_stylebox("panel").bg_color.a, 1.0))
	for chip in worlds.find_child("WorldRewards", true, false).get_children():
		assert(is_equal_approx(chip.get_theme_stylebox("panel").bg_color.a, 1.0))
	main.queue_free()
	await tree.process_frame
	tree.root.size = previous_size
	tree.root.content_scale_size = previous_scale
	save.data = previous
	save.save_game()
	TalentManager.set_class(str(previous.selected_class))
	print("PASS: home relief plaques, native callbacks, one reference navigation row, eight resolutions/two scales without scrolling, stable hover and fully opaque world panels")

func _settle(tree: SceneTree) -> void:
	for frame in 20: await tree.process_frame
