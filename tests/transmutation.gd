extends RefCounted

func run(tree: SceneTree) -> void:
	assert(str(ProjectSettings.get_setting("application/config/name")).begins_with("Ashenwild Regression"))
	var save: Node = tree.root.get_node("SaveManager")
	var game_manager: Node = tree.root.get_node("GameManager")
	var previous: Dictionary = save.data.duplicate(true)
	var was_running: bool = game_manager.run_active
	game_manager.run_active = false
	_test_rules(save)
	_test_persistence(save, game_manager)
	_test_exchange(save, game_manager)
	await _test_ui(tree, save)
	save.data = previous
	save.save_game()
	game_manager.run_active = was_running

func _fixture(save: Node, tier: int = 0) -> Array[String]:
	save.data = save.DEFAULT_SAVE.duplicate(true)
	save._initialize_progression(false)
	var inputs: Array[String] = []
	for item in ContentCatalog.equipment.values():
		if str(item.class_id) == "warrior" and item.generated and str(item.rarity) == ItemTiers.ORDER[tier]:
			save.data.equipment.append(str(item.id))
			inputs.append(str(item.id))
			if inputs.size() == 4: break
	return inputs

func _rng(success: bool, probability: float) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	for seed_value in 1000:
		rng.seed = seed_value
		if (rng.randf() < probability) == success:
			rng.seed = seed_value
			return rng
	assert(false, "Could not find deterministic test seed")
	return rng

func _test_rules(save: Node) -> void:
	for tier in 6:
		for success in [false, true]:
			var inputs := _fixture(save, tier)
			var rarity: String = ItemTiers.ORDER[tier]
			var interval := (tier + 1) * 10
			save.data.transmutation.attempts[rarity] = interval - 1
			var before: Dictionary = save.data.duplicate(true)
			var result := TransmutationRules.resolve(save.data, inputs, "warrior", _rng(success, TransmutationRules.chance(save.data, rarity)))
			assert(result.ok and save.data == before, "Planning a transaction cannot modify the live save")
			assert(bool(result.result.success) == success)
			assert(int(result.result.attempts) == interval and not str(result.result.bonus_id).is_empty())
			var item: EquipmentData = ContentCatalog.equipment[str(result.result.result_id)]
			var bonus: EquipmentData = ContentCatalog.equipment[str(result.result.bonus_id)]
			assert(str(item.rarity) == ItemTiers.ORDER[tier + 1 if success else tier])
			assert(str(bonus.rarity) == ItemTiers.ORDER[tier + 1])
			assert(item.class_id == &"warrior" and bonus.class_id == &"warrior")
			var total_before := _total(before)
			assert(_total(result.save) == total_before - 2, "Four ingredients yield one result plus one milestone item")
			assert(int(result.save.gold) == int(before.gold) and int(result.save.crystals) == int(before.crystals))
	var repeat_inputs := _fixture(save)
	save.data.transmutation.attempts.common = 19
	var repeated_bonus := TransmutationRules.resolve(save.data, repeat_inputs, "warrior", _rng(true, 0.4))
	assert(repeated_bonus.ok and repeated_bonus.result.attempts == 20 and not str(repeated_bonus.result.bonus_id).is_empty())
	var inputs := _fixture(save)
	var before: Dictionary = save.data.duplicate(true)
	assert(not TransmutationRules.validate(save.data, inputs.slice(0, 3), "warrior").is_empty())
	assert(not TransmutationRules.validate(save.data, [inputs[0], inputs[0], inputs[0], inputs[0]], "warrior").is_empty())
	assert(not TransmutationRules.validate(save.data, inputs, "assassin").is_empty())
	save.data.class_loadouts.mage = {"ring": inputs[0]}
	assert(not TransmutationRules.validate(save.data, inputs, "warrior").is_empty(), "Other classes' equipped items are protected")
	save.data = before.duplicate(true)
	assert(not TransmutationRules.validate(save.data, ["field_blade", inputs[1], inputs[2], inputs[3]], "warrior").is_empty())
	assert(not TransmutationRules.validate(save.data, ["missing", inputs[1], inputs[2], inputs[3]], "warrior").is_empty())
	var rare := "gear_warrior_weapon_verdant_reach_0_2"
	save.data.equipment.append(rare)
	assert(not TransmutationRules.validate(save.data, [rare, inputs[1], inputs[2], inputs[3]], "warrior").is_empty())
	save.data = before.duplicate(true)
	save.data.equipment_quantities[inputs[0]] = 4
	var repeated := [inputs[0], inputs[0], inputs[0], inputs[0]]
	assert(TransmutationRules.validate(save.data, repeated, "warrior").is_empty())
	var result := TransmutationRules.resolve(save.data, repeated, "warrior", _rng(false, 0.4))
	assert(result.ok and _total(result.save) == _total(save.data) - 3)
	assert(result.save.transmutation.failures.common == 1)
	assert(is_equal_approx(TransmutationRules.chance(result.save, "common"), 0.42))
	result.save.transmutation.failures.common = 1000
	assert(is_equal_approx(TransmutationRules.chance(result.save, "common"), 0.55))
	assert(not TransmutationRules.resolve(result.save, inputs, "warrior", _rng(true, 0.4)).ok, "Pending reveals cannot be replayed")
	# A milestone still adds an actual copy when every next-tier ID is already owned.
	inputs = _fixture(save)
	for item in ContentCatalog.equipment.values():
		if item.class_id == &"warrior" and item.rarity == &"uncommon": save.data.equipment.append(str(item.id))
	save.data.transmutation.attempts.common = 9
	result = TransmutationRules.resolve(save.data, inputs, "warrior", _rng(false, 0.4))
	assert(TransmutationRules.quantity(result.save, str(result.result.bonus_id)) == 2)
	inputs = _fixture(save, 6)
	assert(not TransmutationRules.validate(save.data, inputs, "warrior").is_empty())
	# Legacy inventory lists imply one copy, without requiring a quantity entry.
	save.data.erase("equipment_quantities")
	assert(TransmutationRules.quantity(save.data, inputs[0]) == 1)
	print("PASS: six fusion tiers, success/fallback, repeatable milestones, real duplicate copies, protection, exact consumption and increasing failure odds")

func _test_persistence(save: Node, game_manager: Node) -> void:
	var inputs := _fixture(save)
	save.save_game()
	var before: Dictionary = save.data.duplicate(true)
	var old_file := FileAccess.get_file_as_string(save.SAVE_PATH)
	var blocked := ProjectSettings.globalize_path(save.SAVE_PATH + ".inventory_tmp")
	assert(DirAccess.make_dir_absolute(blocked) == OK)
	assert(not save.transmute_equipment(inputs, "warrior").ok)
	assert(save.data == before and FileAccess.get_file_as_string(save.SAVE_PATH) == old_file)
	assert(DirAccess.remove_absolute(blocked) == OK)
	game_manager.run_active = true
	assert(not save.transmute_equipment(inputs, "warrior").ok and save.data == before)
	game_manager.run_active = false
	var total := _total(save.data)
	var result: Dictionary = save.transmute_equipment(inputs, "warrior")
	assert(result.ok and _total(save.data) == total - 3)
	var saved: Dictionary = JSON.parse_string(JSON.stringify(save.data))
	save.load_game()
	assert(JSON.parse_string(JSON.stringify(save.data)) == saved)
	assert(save.data.transmutation.last_result.pending)
	var count := _total(save.data)
	assert(save.acknowledge_transmutation() == OK)
	assert(save.acknowledge_transmutation() == OK and _total(save.data) == count)
	save.load_game()
	assert(not save.data.transmutation.last_result.pending)
	# Crafting consumes one stacked ingredient and retains the remaining copies/loadout.
	_fixture(save)
	var ingredient := "gear_warrior_weapon_verdant_reach_0_0"
	save.data.equipment_quantities[ingredient] = 2
	save.data.class_loadouts.warrior.weapon = ingredient
	save.data.gold = 10000
	save.data.crystals = 10
	assert(save.forge_item("forge_gear_warrior_weapon_verdant_reach_0_1"))
	assert(save.equipment_quantity(ingredient) == 1 and save.data.equipment.has(ingredient))
	assert(save.loadout_for("warrior").weapon == ingredient)
	print("PASS: failed-write rollback, active-run guard, atomic persisted result, pending reveal, idempotent acknowledgement and stacked ingredient consumption")

func _test_exchange(save: Node, game_manager: Node) -> void:
	for tier in 7:
		var inputs := _fixture(save, tier)
		var id := inputs[0]
		save.data.equipment_quantities[id] = 3
		var quote := EquipmentExchange.quote(ContentCatalog.equipment[id])
		assert(quote.currency == ("gold" if tier < 3 else "crystals"))
		var balance := int(save.data[str(quote.currency)])
		var count := _total(save.data)
		var transaction: Dictionary = save.exchange_equipment(id, 2, "warrior")
		assert(transaction.ok and save.equipment_quantity(id) == 1)
		assert(_total(save.data) == count - 2 and int(save.data[str(quote.currency)]) == balance + int(quote.unit_value) * 2)
		assert(save.data.equipment_exchange.sold == 2)
		save.load_game()
		assert(save.equipment_quantity(id) == 1 and int(save.data[str(quote.currency)]) == balance + int(quote.unit_value) * 2)
	var inputs := _fixture(save)
	var before: Dictionary = save.data.duplicate(true)
	for amount in [0, -1, 2]: assert(not save.exchange_equipment(inputs[0], amount, "warrior").ok)
	assert(not save.exchange_equipment("field_blade", 1, "warrior").ok)
	assert(not save.exchange_equipment(inputs[0], 1, "mage").ok)
	assert(save.data == before)
	save.data.class_loadouts.warrior.weapon = inputs[0]
	assert(not save.exchange_equipment(inputs[0], 1, "warrior").ok)
	save.data = before.duplicate(true)
	game_manager.run_active = true
	assert(not save.exchange_equipment(inputs[0], 1, "warrior").ok)
	game_manager.run_active = false
	save.save_game()
	var saved := FileAccess.get_file_as_string(save.SAVE_PATH)
	var blocked := ProjectSettings.globalize_path(save.SAVE_PATH + ".inventory_tmp")
	assert(DirAccess.make_dir_absolute(blocked) == OK)
	assert(not save.exchange_equipment(inputs[0], 1, "warrior").ok)
	assert(save.data == before and FileAccess.get_file_as_string(save.SAVE_PATH) == saved)
	assert(DirAccess.remove_absolute(blocked) == OK)
	print("PASS: seven exchange tiers, exact gold/crystal prices, quantities, persisted balances, equipment protection and failed-write rollback")

func _total(data: Dictionary) -> int:
	var result := 0
	for id in data.equipment: result += TransmutationRules.quantity(data, str(id))
	return result

func _settle(tree: SceneTree) -> void:
	for frame in 12: await tree.process_frame

func _test_ui(tree: SceneTree, save: Node) -> void:
	var inputs := _fixture(save)
	for id in inputs: save.data.equipment_quantities[id] = 4
	save.save_game()
	var main: Control = load("res://scenes/main.tscn").instantiate()
	tree.root.add_child(main)
	main._build_page("inventory")
	await _settle(tree)
	main.page_root.find_child("OpenTransmutation", true, false).pressed.emit()
	await _settle(tree)
	assert(main.page_name == "transmutation" and main.page_scroll == null)
	var panel: Node = main.page_root.find_child("TransmutationPanel", true, false)
	panel._auto_select()
	assert(panel.selected.size() == 4 and not panel.fuse.disabled)
	panel._begin_fusion()
	assert(panel.busy and save.data.transmutation.last_result.pending)
	var items := _total(save.data)
	panel._begin_fusion()
	assert(_total(save.data) == items, "Double clicking cannot consume twice")
	# Rebuilding the page mid-animation reveals the already-saved result without rolling again.
	main._build_page("transmutation")
	await _settle(tree)
	panel = main.page_root.find_child("TransmutationPanel", true, false)
	assert(panel.find_child("FusionResult", true, false) != null and _total(save.data) == items)
	panel.find_child("FusionContinue", true, false).pressed.emit()
	await _settle(tree)
	assert(not save.data.transmutation.last_result.pending)
	panel._auto_select()
	panel._begin_fusion()
	assert(panel.busy and panel.circle.animating)
	var original_panes: Control = panel.panes
	panel._process(1.7)
	assert(panel.panes == original_panes and main.page_name == "transmutation", "A fusion result must overlay the same screen")
	assert(panel.result_popup is CanvasLayer)
	assert(not panel.busy and panel.find_child("FusionResult", true, false) != null)
	panel.find_child("FusionContinue", true, false).pressed.emit()
	panel.back_requested.emit()
	await _settle(tree)
	assert(main.page_name == "inventory", "Back returns to Arsenal")
	main._build_page("forge")
	await _settle(tree)
	var forge_title: Label = main.page_root.find_child("ForgeTitle", true, false)
	assert(forge_title.autowrap_mode == TextServer.AUTOWRAP_OFF and forge_title.get_line_count() == 1)
	var legendary := "gear_warrior_weapon_verdant_reach_0_4"
	save.unlock_equipment(legendary)
	save.data.equipment_quantities[legendary] = 3
	main.transmutation_draft.tab = 2
	main._build_page("transmutation")
	await _settle(tree)
	panel = main.page_root.find_child("TransmutationPanel", true, false)
	var exchange: Node = panel.find_child("EquipmentExchangePanel", true, false)
	exchange._select(legendary)
	exchange.quantity.value = 2
	var crystals := int(save.data.crystals)
	exchange._sell()
	exchange._sell()
	assert(int(save.data.crystals) == crystals + 6 and save.equipment_quantity(legendary) == 1)
	panel._tab(0)
	await _settle(tree)
	var picker: OptionButton = panel.find_child("FusionRarity", true, false)
	picker.select(4)
	picker.item_selected.emit(4)
	await _settle(tree)
	assert(panel.draft.rarity == "legendary" and panel.eligible.size() == 1)
	assert(panel.rarity_transition.text == "Lendário → Semideus" and panel.rarity_transition.get_line_count() == 1)
	assert(panel.rarity_transition.autowrap_mode == TextServer.AUTOWRAP_OFF)
	TransmutationRules.consume(save.data, legendary, 1)
	panel._render()
	await _settle(tree)
	assert(panel.empty_label.visible and panel.empty_label.get_parent() != panel.item_grid)
	var old_size: Vector2i = tree.root.size
	var old_scale: Vector2i = tree.root.content_scale_size
	for resolution in [Vector2i(1280, 720), Vector2i(960, 540), Vector2i(640, 360), Vector2i(390, 844), Vector2i(360, 640)]:
		for scale in [0.85, 1.2]:
			tree.root.size = resolution
			tree.root.content_scale_size = resolution
			save.data.settings.ui_scale = scale
			for tab in 4:
				main.transmutation_draft.tab = tab
				main._build_page("transmutation")
				await _settle(tree)
				panel = main.page_root.find_child("TransmutationPanel", true, false)
				assert(main.page_scroll == null)
				for scroll in panel.find_children("*", "ScrollContainer", true, false):
					assert(not scroll.is_visible_in_tree(), "Only hidden dropdown internals may use a ScrollContainer")
				var viewport: Control = main.page_root.find_child("OnlineViewport", true, false)
				assert(viewport.content.get_global_rect().end.y <= viewport.get_global_rect().end.y + 2)
				if tab == 1:
					var rewards := panel.find_children("GuaranteedReward*", "PanelContainer", true, false)
					assert(rewards.size() == 6, "All six guaranteed milestones must be shown together")
					var bottom := 0.0
					for reward in rewards:
						assert(reward.get_global_rect().position.y >= bottom)
						bottom = reward.get_global_rect().end.y
						var title: Label = reward.find_child("MilestoneTitle", true, false)
						assert(title.get_theme_font_size("font_size") == roundi(16 * scale))
					assert(is_equal_approx(viewport.content.scale.x, 1.0), "Milestones must preserve fonts: resolution=%s scale=%s factor=%s extent=%s available=%s" % [resolution, scale, viewport.content.scale, viewport.content.get_combined_minimum_size(), viewport.size])
				for button in panel.find_children("*", "Button", true, false):
					if not button.is_visible_in_tree(): continue
					assert(button.get_global_rect().position.x >= viewport.get_global_rect().position.x - 2)
					assert(button.get_global_rect().end.x <= viewport.get_global_rect().end.x + 2)
			# A two-item result is a viewport overlay and must fit independently of the page layout.
			var item_count := _total(save.data)
			save.data.transmutation.last_result.pending = true
			save.data.transmutation.last_result.bonus_id = "gear_warrior_weapon_verdant_reach_0_1"
			main.transmutation_draft.tab = 0
			main._build_page("transmutation")
			await _settle(tree)
			panel = main.page_root.find_child("TransmutationPanel", true, false)
			assert(panel.result_popup is CanvasLayer and panel.back.disabled)
			var popup_bounds: Rect2 = panel.result_popup.fit.content.get_global_rect()
			var screen_bounds: Rect2 = tree.root.get_visible_rect()
			assert(popup_bounds.position.x >= -1 and popup_bounds.position.y >= -1)
			assert(popup_bounds.end.x <= screen_bounds.end.x + 1 and popup_bounds.end.y <= screen_bounds.end.y + 1)
			panel._dismiss_result()
			assert(_total(save.data) == item_count)
	main.queue_free()
	await tree.process_frame
	tree.root.size = old_size
	tree.root.content_scale_size = old_scale
	print("PASS: Arsenal entry/back, real fusion, duplicate-click guard, reveal animation/reopen, result popup without changing screens, Legendary text, seven-tier exchange, all six stacked milestones and four tabs at five resolutions/two text scales")
