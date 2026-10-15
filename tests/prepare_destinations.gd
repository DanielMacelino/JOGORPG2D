extends RefCounted

func run(tree: SceneTree) -> void:
	var save: Node = tree.root.get_node("SaveManager")
	var previous: Dictionary = save.data.duplicate(true)
	var old_size := tree.root.size
	var old_scale := tree.root.content_scale_size
	save.data = save.DEFAULT_SAVE.duplicate(true)
	save._initialize_progression(false)
	var expected := {}
	for slot in ["weapon", "helmet", "armor", "boots", "ring", "amulet"]:
		var id := "gear_warrior_%s_verdant_reach_0_0" % slot
		TransmutationRules.add_copy(save.data, id)
		assert(EquipmentManager.equip(slot, id, "warrior"))
		expected[slot] = id
	var main: Node = load("res://scenes/main.tscn").instantiate()
	tree.root.add_child(main)
	for scale in [1.0, 1.2]:
		save.data.settings.ui_scale = scale
		for resolution in [Vector2i(1280,720), Vector2i(1024,578), Vector2i(800,600), Vector2i(640,480), Vector2i(390,844), Vector2i(320,640)]:
			tree.root.size = resolution
			main._build_page("prepare")
			await _settle(tree)
			var preparation: Node = main.page_root.find_child("PrepareScreen", true, false)
			assert(preparation.cards.get_child_count() == 6)
			var seen := {}
			for card in preparation.cards.get_children():
				assert(card.illustration is AtlasTexture)
				assert(not seen.has(str(card.illustration.region)), "Each destination must have its own illustration")
				seen[str(card.illustration.region)] = true
				assert(card.copy_label.position.y + card.copy_label.get_minimum_size().y <= card.size.y - 2)
				assert(card.size.x <= preparation.size.x and card.size.x >= 160)
				if card.page == "characters":
					assert(card.character_preview.class_id == "warrior" and not card.character_preview.is_processing())
			var strip: Control = preparation.find_child("PrepareEquippedItems", true, false)
			assert(strip.get_child_count() == 6)
			var panel: Control = preparation.find_child("PrepareEquipmentSummary", true, false)
			for square in strip.get_children():
				var id := str(square.get_meta("item_id"))
				var item: EquipmentData = ContentCatalog.equipment[id]
				assert(id == str(expected[str(item.slot)]))
				assert(square.get_child(0).item == item and square.tooltip_text.contains(item.display_name))
				assert(square.get_global_rect().end.x <= panel.get_global_rect().end.x + 1, "Equipped thumbnails must stay inside their summary panel")
			assert(preparation.portrait.texture_for("warrior") == preload("res://scripts/data/character_sheet.gd").atlas("warrior"))
			assert(preparation.portrait.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST and not preparation.portrait.is_processing())
	# Changing character must replace every worn thumbnail, including shared-slot items.
	main._select_class("mage")
	main._build_page("prepare")
	await _settle(tree)
	var preparation: Node = main.page_root.find_child("PrepareScreen", true, false)
	var strip: Control = preparation.find_child("PrepareEquippedItems", true, false)
	assert(strip.get_child_count() == 1 and strip.get_child(0).get_meta("item_id") == "moon_staff")
	assert(preparation.portrait.class_id == "mage")
	for index in 6:
		main._build_page("prepare")
		await _settle(tree)
		preparation = main.page_root.find_child("PrepareScreen", true, false)
		var button: Button = preparation.cards.get_child(index)
		var destination: String = button.page
		button.pressed.emit()
		assert(main.page_name == destination)
		main._go_back()
		assert(main.page_name == "prepare")
	main.queue_free()
	await tree.process_frame
	tree.root.size = old_size
	tree.root.content_scale_size = old_scale
	save.data = previous
	save.save_game()
	TalentManager.set_class(str(previous.selected_class))
	print("PASS: six distinct preparation illustrations, native class portraits, six equipped thumbnails, character-specific inventory, intact routes and labels at six resolutions/two scales")

func _settle(tree: SceneTree) -> void:
	for frame in 20: await tree.process_frame
