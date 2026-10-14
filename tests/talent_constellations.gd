extends RefCounted
func run(tree: SceneTree) -> void:
	var save: Node = tree.root.get_node("SaveManager")
	var talents: Node = tree.root.get_node("TalentManager")
	save.data = save.DEFAULT_SAVE.duplicate(true)
	save._initialize_progression(false)
	save.data.unlocked_classes = ContentCatalog.CLASS_ORDER.duplicate()
	var level_xp := 0
	for level in range(1, 12): level_xp += talents.level_cost(level)
	save.data.class_progression.warrior.xp = level_xp
	var original := tree.root.size
	var original_scale := tree.root.content_scale_size
	var main: Node = load("res://scenes/main.tscn").instantiate()
	tree.root.add_child(main)
	var purchased := false
	for text_scale in [1.0, 1.2]:
		save.data.settings.ui_scale = text_scale
		for resolution in [Vector2i(1280,720), Vector2i(800,600), Vector2i(640,480), Vector2i(390,844), Vector2i(320,640)]:
			tree.root.size = resolution
			main._build_page("talents")
			for frame in 8: await tree.process_frame
			var screen: Control = main.page_root.find_child("TalentScreen", true, false)
			assert(screen != null and main.page_scroll == null)
			var viewport: Control = main.page_root.find_child("OnlineViewport", true, false)
			assert(viewport.content.get_global_rect().end.y <= viewport.get_global_rect().end.y + 1, "Constellations must fit without page scrolling")
			assert(viewport.content.get_global_rect().end.x <= viewport.get_global_rect().end.x + 1)
			for category in talents.TREE_ORDER:
				screen.branch_buttons[category].pressed.emit()
				for frame in 3: await tree.process_frame
				assert(talents.tree_id == category and talents.nodes.size() == 193)
				assert(screen.canvas.available_nodes.size() == 193 and screen.selected_id == talents.root_id())
				assert(screen.canvas_panel.visible and not screen.refund_pending)
				var key: String = talents.node_id(1, 0, category)
				screen.select_node(key)
				assert(screen.node_name.text == talents.nodes[key].name and screen.node_description.text == talents.nodes[key].description)
				if not purchased:
					var points_before: int = talents.points()
					screen.allocate_button.pressed.emit()
					assert(talents.is_allocated(key) and talents.points() == points_before - 1)
					assert(screen.allocate_button.disabled)
					purchased = true
				if screen.size.x < 760:
					assert(screen.detail_panel.visible and not screen.canvas_panel.visible)
					screen.detail_toggle.pressed.emit()
					assert(screen.canvas_panel.visible)
				for label in screen.find_children("*", "Label", true, false):
					assert(not label.text.contains("?"), "Accents must remain intact")
				# Return to this category's center before testing remembered camera state.
				screen.select_node(talents.root_id())
				screen.show_details = false
				screen._layout()
			for category in talents.TREE_ORDER:
				if talents.tree_allocated(category) > 0:
					screen.select_tree(category)
					screen.refund_button.pressed.emit()
					assert(screen.refund_pending)
					screen.refund_button.pressed.emit()
					assert(talents.tree_allocated(category) == 0 and not screen.refund_pending)
	for index in ContentCatalog.CLASS_ORDER.size():
		main._select_talent_class(index)
		for frame in 5: await tree.process_frame
		var screen: Control = main.page_root.find_child("TalentScreen", true, false)
		assert(screen.portrait.class_id == ContentCatalog.CLASS_ORDER[index] and screen.branch_buttons.size() == 6)
	main.queue_free()
	await tree.process_frame
	tree.root.size = original
	tree.root.content_scale_size = original_scale
	print("PASS: six category selectors, one visible 193-node graph, real learning/refunds, six class portraits, five resolutions and two text scales without scrolling")
