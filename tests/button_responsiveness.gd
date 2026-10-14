extends RefCounted
func run(tree: SceneTree) -> void:
	var save: Node = tree.root.get_node("SaveManager")
	save.data = save.DEFAULT_SAVE.duplicate(true)
	save._initialize_progression(false)
	save.data.gold = 100000
	save.data.crystals = 10000
	save.data.equipment = ContentCatalog.equipment.keys()
	var old_size := tree.root.size
	var old_scale := tree.root.content_scale_size
	var main: Node = load("res://scenes/main.tscn").instantiate()
	tree.root.add_child(main)
	for ui_scale in [1.0, 1.2]:
		save.data.settings.ui_scale = ui_scale
		for resolution in [Vector2i(1280,720), Vector2i(800,600), Vector2i(640,480), Vector2i(390,844), Vector2i(320,640)]:
			tree.root.size = resolution
			for page in ["talents", "upgrades", "forge", "inventory", "online", "settings", "characters", "maps", "home", "records"]:
				main._build_page(page)
				for frame in 10: await tree.process_frame
				for button in main.page_root.find_children("*", "Button", true, false):
					if not button.is_visible_in_tree() or button.text.is_empty(): continue
					var style: StyleBox = button.get_theme_stylebox("normal")
					var usable: Vector2 = button.size - style.get_minimum_size()
					var font: Font = button.get_theme_font("font")
					var needed := font.get_multiline_string_size(button.text, HORIZONTAL_ALIGNMENT_LEFT, maxf(1, usable.x), button.get_theme_font_size("font_size"))
					assert(needed.y <= usable.y + 2, "Button text must fit: %s %s %s" % [resolution, page, button.text])
					var rect: Rect2 = button.get_global_rect()
					assert(rect.size.x >= 24 and rect.size.y >= 24, "Button must keep a usable hit area: %s %s %s %s" % [resolution, page, button.text, rect])
					assert(rect.position.x >= -1 and rect.end.x <= tree.root.get_visible_rect().size.x + 1, "Buttons must fit horizontally: %s %s %s %s" % [resolution, page, button.text, rect])
	# Hover feedback must keep the actual click rectangle stable.
	main._build_page("upgrades")
	for frame in 10: await tree.process_frame
	var hover_button: Button
	for button in main.page_root.find_children("*", "Button", true, false):
		if button.text == "Forca" or button.text == "Todos": hover_button = button
	assert(hover_button != null)
	var before := hover_button.get_global_rect()
	hover_button.mouse_entered.emit()
	for frame in 10: await tree.process_frame
	assert(hover_button.get_global_rect().is_equal_approx(before), "Hover must not displace the click target")
	hover_button.mouse_exited.emit()
	# Exercise real connected button callbacks, not direct purchase methods.
	var upgrade: Button
	for button in main.page_root.find_children("*", "Button", true, false):
		if button.text.begins_with("APRIMORAR"):
			upgrade = button
			break
	var ranks_before: Dictionary = save.data.upgrades.duplicate()
	upgrade.pressed.emit()
	for frame in 10: await tree.process_frame
	assert(save.data.upgrades != ranks_before)
	main._build_page("forge")
	for frame in 10: await tree.process_frame
	var forge: Button
	for button in main.page_root.find_children("*", "Button", true, false):
		if button.text == "Forjar" and not button.disabled:
			forge = button
			break
	assert(forge != null)
	var forged_before: Dictionary = save.data.forge_upgrades.duplicate()
	forge.pressed.emit()
	for frame in 10: await tree.process_frame
	assert(save.data.forge_upgrades != forged_before)
	main.queue_free()
	await tree.process_frame
	tree.root.size = old_size
	tree.root.content_scale_size = old_scale
	print("PASS: button text, horizontal bounds, usable hit areas at five resolutions/two scales across ten menus, stable hover and real upgrade/forge callbacks")
