extends RefCounted
class ReviveFixture extends "res://scripts/network/coop_game.gd":
	func _spawn_skill(_at: Vector2, _kind: String, _radius: float, _color: Color, _direction: Vector2 = Vector2.RIGHT) -> void: pass
	func _show_notice(_message: String) -> void: pass

func run(tree: SceneTree) -> void:
	assert(str(ProjectSettings.get_setting("application/config/name")).begins_with("Ashenwild Regression"))
	assert(is_zero_approx(float(ProjectSettings.get_setting("gui/timers/tooltip_delay_sec"))))
	_test_revive()
	assert(ContentCatalog.abilities.rapid_hands.hud_total(3) == "+48%")
	assert(ContentCatalog.abilities.iron_skin.hud_total(3) == "+9")
	var save: Node = tree.root.get_node("SaveManager")
	var old: Dictionary = save.data.duplicate(true)
	save.data = save.DEFAULT_SAVE.duplicate(true)
	save._initialize_progression(false)
	save.data.gold = 100000
	save.data.crystals = 10000
	var inputs: Array[String] = []
	for item in ContentCatalog.equipment.values():
		if item.generated and item.class_id == &"warrior" and item.tier_index == 0:
			inputs.append(str(item.id))
			save.data.equipment.append(str(item.id))
			if inputs.size() == 4: break
	var source := inputs[0]
	var target := source.trim_suffix("_0") + "_1"
	assert(save.set_equipment_favorite(source, true))
	assert(TransmutationRules.protected_ids(save.data).has(source))
	assert(not TransmutationRules.validate(save.data, inputs, "warrior").is_empty())
	assert(not EquipmentExchange.resolve(save.data, source, 1, "warrior").ok)
	assert(not save.can_forge("forge_" + target))
	assert(not save.forge_item("forge_" + target))
	save.load_game()
	assert(save.is_equipment_favorite(source))
	var main: Node = load("res://scenes/main.tscn").instantiate()
	tree.root.add_child(main)
	await _settle(tree)
	await tree.create_timer(0.4).timeout
	assert(is_equal_approx(main.page_root.modulate.a, 1.0), "Home opacity: %s" % main.page_root.modulate.a)
	main._build_page("inventory")
	await _settle(tree)
	await tree.create_timer(0.4).timeout
	assert(is_equal_approx(main.page_root.modulate.a, 0.9), "Page opacity: %s" % main.page_root.modulate.a)
	var inventory: Node = main.page_root.find_child("InventoryPanel", true, false)
	var star: Button = inventory.find_child("Favorite_" + source, true, false)
	assert(star != null)
	star.pressed.emit()
	assert(not save.is_equipment_favorite(source))
	assert(save.set_equipment_favorite(source, true))
	main._build_page("forge")
	await _settle(tree)
	var forge: Node = main.page_root.find_child("ForgePanel", true, false)
	for recipe in forge.matched_recipes:
		assert(str(recipe.id) != "forge_" + target and str(recipe.result) != source)
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.physical_keycode = KEY_ESCAPE
	escape.pressed = true
	main._unhandled_key_input(escape)
	assert(main.page_name == "inventory")
	main._build_page("transmutation")
	await _settle(tree)
	var fusion: Node = main.page_root.find_child("TransmutationPanel", true, false)
	for item in fusion.eligible: assert(str(item.id) != source)
	var old_size: Vector2i = tree.root.size
	var old_scale: Vector2i = tree.root.content_scale_size
	for resolution in [Vector2i(1280, 720), Vector2i(960, 720), Vector2i(800, 600), Vector2i(640, 360), Vector2i(390, 844)]:
		tree.root.size = resolution
		tree.root.content_scale_size = resolution
		main._build_page("transmutation")
		await _settle(tree)
		fusion = main.page_root.find_child("TransmutationPanel", true, false)
		for pane in 3:
			fusion.draft.pane = pane
			fusion._layout()
			await _settle(tree)
			var viewport: Control = main.page_root.find_child("OnlineViewport", true, false)
			assert(viewport.content.scale.x >= 0.9, "Fusion readability: %s %s %s" % [resolution, pane, viewport.content.scale])
			var available: float = fusion._available_width()
			if available >= 720 and available < 900 and pane != 2:
				assert(fusion.inputs_frame.visible and fusion.ritual_frame.visible and not fusion.preview_frame.visible)
			elif available < 720:
				assert([fusion.inputs_frame, fusion.ritual_frame, fusion.preview_frame].filter(func(frame: Control) -> bool: return frame.visible).size() == 1)
	tree.root.size = old_size
	tree.root.content_scale_size = old_scale
	main._build_page("inventory")
	await _settle(tree)
	main._start_game(false)
	await _settle(tree)
	var game: Node = main.active_game
	game.wave_director.stop()
	game._toggle_pause()
	assert(tree.paused)
	game.pause_layer.find_child("OpenPauseSettings", true, false).pressed.emit()
	assert(is_instance_valid(game.pause_settings_layer))
	var settings: Node = game.pause_settings_layer.find_child("PauseSettings", true, false)
	assert(settings != null)
	settings.find_child("PauseSetting_music", true, false).value = 0.32
	assert(is_equal_approx(float(save.data.settings.music), 0.32))
	settings.find_child("PauseSetting_ui_scale", true, false).value = 1.1
	assert(is_instance_valid(game.pause_settings_layer))
	Input.parse_input_event(escape)
	await _settle(tree)
	assert(tree.paused and game.pause_layer.visible and game.pause_settings_layer == null)
	var release := escape.duplicate() as InputEventKey
	release.pressed = false
	Input.parse_input_event(release)
	Input.parse_input_event(escape)
	await _settle(tree)
	assert(not tree.paused and game.pause_layer == null)
	Input.parse_input_event(release)
	main._return_to_menu()
	await _settle(tree)
	main.queue_free()
	await tree.process_frame
	save.data = old
	save.save_game()
	TalentManager.set_class(str(old.selected_class))
	print("PASS: instant tooltips, Esc matches Back, favorite persistence/UI/server-side craft/fusion/exchange protection, accumulated skill bonuses, damage/distance preserve resurrection and live settings inside pause")

func _test_revive() -> void:
	var game := ReviveFixture.new()
	var fallen := SurvivorPlayer.new()
	var helper := SurvivorPlayer.new()
	fallen.configure("warrior", {})
	helper.configure("mage", {})
	fallen.is_dead = true
	helper.position = Vector2(20, 0)
	game.actors = {1: {"player": fallen}, 2: {"player": helper}}
	game._update_revives(1.0)
	assert(fallen.revive_progress >= 0.25)
	var progress := fallen.revive_progress
	helper.damage_serial += 1
	game._update_revives(0.1)
	assert(fallen.revive_progress == progress)
	game._update_revives(0.5)
	assert(fallen.revive_progress == progress)
	helper.position = Vector2(500, 0)
	game._update_revives(2.0)
	assert(fallen.revive_progress == progress)
	helper.position = Vector2(20, 0)
	game.collective_paused = true
	game._update_revives(10.0)
	assert(fallen.revive_progress == progress)
	game.collective_paused = false
	game._update_revives(4.0)
	assert(not fallen.is_dead and is_equal_approx(fallen.health, fallen.max_health * 0.35))
	game.free()
	fallen.free()
	helper.free()

func _settle(tree: SceneTree) -> void:
	for frame in 16: await tree.process_frame
