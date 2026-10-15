extends RefCounted
const TARGET := "gear_warrior_weapon_verdant_reach_0_1"

func run(tree: SceneTree) -> void:
	assert(str(ProjectSettings.get_setting("application/config/name")).begins_with("Ashenwild Regression"))
	var save: Node = tree.root.get_node("SaveManager")
	var previous: Dictionary = save.data.duplicate(true)
	_rules(save)
	_persistence(save)
	await _interface(tree, save)
	save.data = previous
	save.save_game()
	TalentManager.set_class(str(previous.selected_class))
	print("PASS: targeted equipment wagers, seven consolation tiers, exact loss/win consumption, protected gear, progress-gated prizes, failed-write rollback, isolated characters, persistent pending popups and responsive native callbacks")

func _fixture(save: Node, tier := 0) -> Array[String]:
	save.data = save.DEFAULT_SAVE.duplicate(true)
	save._initialize_progression(false)
	var inputs: Array[String] = []
	for item in ContentCatalog.equipment.values():
		if item.generated and item.class_id == &"warrior" and str(item.rarity) == ItemTiers.ORDER[tier]:
			TransmutationRules.add_copy(save.data, str(item.id))
			inputs.append(str(item.id))
			if inputs.size() == 4: break
	return inputs

func _rng(success: bool, probability: float) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	for value in 1000:
		rng.seed = value
		if (rng.randf() < probability) == success:
			rng.seed = value
			return rng
	assert(false)
	return rng

func _total(data: Dictionary) -> int:
	var count := 0
	for id in data.equipment: count += TransmutationRules.quantity(data, str(id))
	return count

func _rules(save: Node) -> void:
	var expected := [15, 40, 100, 1, 3, 8, 20]
	for tier in 7:
		for success in [false, true]:
			var inputs := _fixture(save, tier)
			var before: Dictionary = save.data.duplicate(true)
			var quote := EquipmentWager.quote(before, TARGET, inputs)
			var result := EquipmentWager.resolve(before, TARGET, inputs, "warrior", _rng(success, float(quote.chance)))
			assert(result.ok and save.data == before)
			assert(result.result.success == success and result.result.kind == "wager")
			assert(_total(result.save) == _total(before) - 4 + (1 if success else 0))
			assert(result.save.transmutation.attempts == before.transmutation.attempts, "A wager cannot advance fusion milestones")
			assert(result.save.transmutation.wagers.attempts == 1)
			assert(TransmutationRules.quantity(result.save, TARGET) == TransmutationRules.quantity(before, TARGET) - inputs.count(TARGET) + (1 if success else 0))
			if success:
				assert(result.save.gold == before.gold and result.save.crystals == before.crystals)
			else:
				var currency := "gold" if tier < 3 else "crystals"
				assert(int(result.save[currency]) - int(before[currency]) == expected[tier])
				assert(int(quote.consolation[currency]) < int(quote.sale_value[currency]), "Failure consolation must be below ordinary sale")
			assert(not EquipmentWager.resolve(result.save, TARGET, inputs, "warrior", _rng(success, float(quote.chance))).ok)
	var inputs := _fixture(save)
	assert(EquipmentWager.target_available(save.data, TARGET, "warrior"))
	assert(not EquipmentWager.target_available(save.data, "field_blade", "warrior"))
	assert(not EquipmentWager.target_available(save.data, "gear_mage_weapon_verdant_reach_0_1", "warrior"))
	assert(not EquipmentWager.target_available(save.data, "gear_warrior_weapon_hollow_cairn_0_1", "warrior"))
	save.data.campaign_progress["0"] = 10
	assert(EquipmentWager.target_available(save.data, "gear_warrior_weapon_hollow_cairn_0_1", "warrior"))
	assert(not EquipmentWager.resolve(save.data, TARGET, inputs.slice(0, 3), "warrior", _rng(true, 0.5)).ok)
	assert(not EquipmentWager.resolve(save.data, "missing", inputs, "warrior", _rng(true, 0.5)).ok)
	save.data.favorite_equipment = [inputs[0]]
	assert(not EquipmentWager.validate(save.data, TARGET, inputs, "warrior").is_empty())
	save.data.favorite_equipment = [TARGET]
	assert(not EquipmentWager.target_available(save.data, TARGET, "warrior"))
	save.data.favorite_equipment = []
	save.data.class_loadouts.warrior.weapon = inputs[0]
	assert(not EquipmentWager.validate(save.data, TARGET, inputs, "warrior").is_empty())
	inputs = _fixture(save)
	save.data.equipment_quantities[inputs[0]] = 12
	var repeated: Array[String] = []
	for index in 12: repeated.append(inputs[0])
	assert(EquipmentWager.validate(save.data, TARGET, repeated, "warrior").is_empty())
	var smaller := EquipmentWager.quote(save.data, TARGET, repeated.slice(0, 4))
	var larger := EquipmentWager.quote(save.data, TARGET, repeated)
	assert(float(larger.chance) > float(smaller.chance) and float(larger.chance) <= 0.9)
	repeated.append(inputs[0])
	assert(not EquipmentWager.validate(save.data, TARGET, repeated, "warrior").is_empty())
	inputs = _fixture(save)
	assert(not EquipmentWager.validate(save.data, TARGET, [inputs[0], inputs[0], inputs[0], inputs[0]], "warrior").is_empty())
	assert(not EquipmentWager.validate(save.data, TARGET, inputs, "mage").is_empty())

func _persistence(save: Node) -> void:
	var inputs := _fixture(save)
	save.save_game()
	var before: Dictionary = save.data.duplicate(true)
	var disk := FileAccess.get_file_as_string(save.SAVE_PATH)
	var blocked := ProjectSettings.globalize_path(save.SAVE_PATH + ".inventory_tmp")
	assert(DirAccess.make_dir_absolute(blocked) == OK)
	assert(not save.wager_equipment(TARGET, inputs, "warrior").ok)
	assert(save.data == before and FileAccess.get_file_as_string(save.SAVE_PATH) == disk)
	assert(DirAccess.remove_absolute(blocked) == OK)
	GameManager.run_active = true
	assert(not save.wager_equipment(TARGET, inputs, "warrior").ok)
	GameManager.run_active = false
	var result: Dictionary = save.wager_equipment(TARGET, inputs, "warrior")
	assert(result.ok and save.data.transmutation.last_result.pending)
	var persisted: Dictionary = JSON.parse_string(JSON.stringify(save.data))
	assert(not save.wager_equipment(TARGET, inputs, "warrior").ok)
	save.load_game()
	assert(JSON.parse_string(JSON.stringify(save.data)) == persisted)
	assert(save.acknowledge_transmutation() == OK and save.acknowledge_transmutation() == OK)
	var gold := int(save.data.gold)
	var crystals := int(save.data.crystals)
	save.set_selected_class("mage")
	assert(not save.data.transmutation.has("wagers"))
	assert(int(save.data.gold) == gold and int(save.data.crystals) == crystals)
	save.set_selected_class("warrior")
	assert(int(save.data.transmutation.wagers.attempts) == 1)
	assert(not save.data.transmutation.last_result.pending)

func _interface(tree: SceneTree, save: Node) -> void:
	var inputs := _fixture(save)
	for id in inputs: save.data.equipment_quantities[id] = 8
	save.save_game()
	var old_size := tree.root.size
	var old_scale := tree.root.content_scale_size
	var main: Node = load("res://scenes/main.tscn").instantiate()
	tree.root.add_child(main)
	tree.root.size = Vector2i(1024, 578)
	main.transmutation_draft.tab = 1
	main._build_page("transmutation")
	await _settle(tree)
	var panel: Node = main.page_root.find_child("TransmutationPanel", true, false)
	var wager: Node = panel.wager_panel
	wager.choose_target(TARGET)
	for id in inputs: wager.add_sacrifice(id)
	assert(not wager.perform.disabled and wager.selected.size() == 4)
	var quote := EquipmentWager.quote(save.data, TARGET, inputs)
	assert(wager.odds.text == "%.1f%% DE CHANCE" % (float(quote.chance) * 100))
	wager.perform.pressed.emit()
	assert(panel.busy and save.data.transmutation.last_result.pending)
	var after: Dictionary = save.data.duplicate(true)
	panel.begin_wager(TARGET, wager.selected)
	assert(save.data == after)
	# Reopen during animation: reveal the persisted wager instead of rolling again.
	main._build_page("transmutation")
	await _settle(tree)
	panel = main.page_root.find_child("TransmutationPanel", true, false)
	assert(panel.result_popup is CanvasLayer and panel.back.disabled)
	assert(save.data == after)
	panel.find_child("FusionContinue", true, false).pressed.emit()
	await _settle(tree)
	assert(not save.data.transmutation.last_result.pending and not panel.back.disabled)
	wager = panel.wager_panel
	wager.choose_target(TARGET)
	for id in inputs: wager.add_sacrifice(id)
	wager.perform.pressed.emit()
	assert(panel.busy and wager.circle.animating and not wager.query.editable)
	var settled: Dictionary = save.data.duplicate(true)
	panel._process(1.7)
	assert(not panel.busy and panel.result_popup is CanvasLayer and wager.selected.is_empty())
	assert(save.data == settled, "The reveal cannot change or repeat the already-committed transaction")
	panel._dismiss_result()
	await _settle(tree)
	assert(not save.data.transmutation.last_result.pending and wager.query.editable)
	# Exercise the loss popup separately; no empty item ID can be dereferenced.
	var popup: Node = load("res://scripts/ui/transmutation_result_popup.gd").new()
	popup.result = {"kind": "wager", "success": false, "result_id": "", "bonus_id": "", "target_id": TARGET, "consolation": {"gold": 15, "crystals": 1}}
	tree.root.add_child(popup)
	await _settle(tree)
	assert(popup.find_child("FusionContinue", true, false) != null)
	popup.queue_free()
	main.queue_free()
	await tree.process_frame
	tree.root.size = old_size
	tree.root.content_scale_size = old_scale

func _settle(tree: SceneTree) -> void:
	for frame in 20: await tree.process_frame
