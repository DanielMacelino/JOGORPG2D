extends RefCounted
func run(tree: SceneTree) -> void:
	assert(str(ProjectSettings.get_setting("application/config/name")).begins_with("Ashenwild Regression"), "Reset tests must never touch a real player save")
	var save: Node = tree.root.get_node("SaveManager")
	var talents: Node = tree.root.get_node("TalentManager")
	var game_manager: Node = tree.root.get_node("GameManager")
	save.data = save.DEFAULT_SAVE.duplicate(true)
	save._initialize_progression(false)
	save.data.gold = 98765
	save.data.crystals = 789
	save.data.account_xp = 45000
	save.data.unlocked_classes = ["warrior", "mage", "ranger", "assassin", "druid", "paladin"]
	save.data.unlocked_maps = ["verdant_reach", "hollow_cairn", "ember_crater", "black_keep", "frostwood", "sunken_mire"]
	save.data.completed_maps = save.data.unlocked_maps.duplicate()
	save.data.highest_difficulty = 6
	save.data.campaign_progress = {"0": 60, "6": 60}
	save.data.selected_class = "paladin"
	save.data.selected_map = "frostwood"
	save.data.selected_phase = 8
	save.data.selected_difficulty = 6
	save.data.equipment.append("oath_hammer")
	save.data.equipment_quantities = {"oath_hammer": 12}
	save.data.equipment_exchange = {"sold": 42, "gold": 300, "crystals": 10, "last_receipt": {"total": 10}}
	save.data.transmutation = {"attempts": {"common": 123}, "failures": {"common": 4}, "last_result": {"pending": true}}
	save.data.class_loadouts.paladin = {"weapon": "oath_hammer"}
	save.data.equipped = save.data.class_loadouts.paladin.duplicate()
	save.data.settings.ui_scale = 1.15
	save.data.settings.music = 0.10
	save.data.statistics.total_runs = 100
	save.data.bestiary_kills = {"goblin": 300}
	save.data.achievements = {"first_blood": true}
	save.character_meta().relics = ["old_relic"]
	save.character_meta().equipped_relics = ["old_relic"]
	save.data.favorite_equipment = ["field_blade"]
	save.data.forge_upgrades = {"old_recipe": true}
	save.data.active_bounties = ["old_bounty"]
	save.data.completed_bounties = ["old_bounty"]
	save.data.bounty_progress = {"old_bounty": 30}
	save.data.pending_achievement_rewards = ["old_reward"]
	save.data.best_wave = 12
	save.data.legacy_extra = 999
	for owner in save.data.class_progression:
		save.data.class_progression[owner] = {"xp": 20000, "talents": talents.ROOTS + [talents.node_id(1, 0)], "last_xp": 1500}
	for upgrade in save.upgrades_for():
		save.upgrades_for()[upgrade] = 25
	save.save_game()
	var dirty: Dictionary = save.data.duplicate(true)
	var previous_file := FileAccess.get_file_as_string(save.SAVE_PATH)
	# A failed write must leave both the in-memory data and the old file untouched.
	var blocked_path: String = ProjectSettings.globalize_path(save.SAVE_PATH + ".reset_tmp")
	assert(DirAccess.make_dir_absolute(blocked_path) == OK)
	assert(save.reset_progress() != OK)
	assert(save.data == dirty and FileAccess.get_file_as_string(save.SAVE_PATH) == previous_file)
	assert(DirAccess.remove_absolute(blocked_path) == OK)
	game_manager.run_active = true
	assert(save.reset_progress() == ERR_BUSY and save.data == dirty)
	game_manager.run_active = false
	var main: Control = load("res://scenes/main.tscn").instantiate()
	tree.root.add_child(main)
	main.transmutation_draft = {"selected": ["oath_hammer"], "tab": 1}
	main.online_draft = {"nickname": "Old", "phase": 8}
	main.forge_draft = {"class": "paladin", "page": 5}
	tree.root.get_node("NetworkSession").config = {"map": "frostwood", "tier": 6}
	tree.root.get_node("NetworkSession").local_profile = {"class": "paladin"}
	main._build_page("settings")
	for frame in 6:
		await tree.process_frame
	var reset: Button = main.find_child("ResetPlayerProgress", true, false)
	assert(reset != null and reset.custom_minimum_size.y >= 48)
	reset.pressed.emit()
	var dialog: ConfirmationDialog = main.get_node("ResetProgressConfirmation")
	assert(dialog.get_cancel_button().has_focus(), "Cancel receives default focus for irreversible reset")
	assert(save.data == dirty, "Opening confirmation does not erase anything")
	dialog.canceled.emit()
	for frame in 3:
		await tree.process_frame
	assert(save.data == dirty and FileAccess.get_file_as_string(save.SAVE_PATH) == previous_file)
	reset.pressed.emit()
	dialog = main.get_node("ResetProgressConfirmation")
	dialog.confirmed.emit()
	for frame in 6:
		await tree.process_frame
	assert(main.page_name == "home" and main.selected_class == "warrior" and main.selected_map == "verdant_reach" and main.selected_phase == 1 and main.selected_difficulty == 0)
	assert(main.page_history.is_empty() and main.online_draft.is_empty() and main.forge_draft.is_empty())
	assert(talents.class_id == "warrior" and talents.tree_id == "general")
	assert(tree.root.get_node("NetworkSession").config.is_empty() and tree.root.get_node("NetworkSession").local_profile.is_empty())
	assert(save.data.gold == 0 and save.data.crystals == 0 and save.data.account_xp == 0 and save.data.best_wave == 0)
	assert(save.data.settings == save.DEFAULT_SAVE.settings)
	assert(save.data.unlocked_classes == save.DEFAULT_SAVE.unlocked_classes and save.data.equipment == ["field_blade"])
	assert(save.owned_equipment("mage") == ["moon_staff"] and save.owned_equipment("ranger") == ["thorn_bow"])
	assert(save.data.unlocked_maps == ["verdant_reach"] and save.data.highest_difficulty == 0 and save.data.campaign_progress == {"0": 0})
	assert(not save.data.has("legacy_extra"))
	for owner in save.data.class_progression:
		assert(save.data.class_progression[owner].xp == 0 and save.data.class_progression[owner].last_xp == 0)
		assert(save.data.class_progression[owner].talents == talents.ROOTS and talents.character_level(owner) == 1 and talents.spent_points(owner) == 0)
	for key in ["bestiary_kills", "achievements", "relics", "equipped_relics", "forge_upgrades", "active_bounties", "completed_bounties", "bounty_progress", "pending_achievement_rewards"]:
		assert(save.data[key].is_empty(), "Reset clears " + key)
	for amount in save.upgrades_for().values():
		assert(amount == 0)
	assert(save.data.statistics.total_runs == 0 and game_manager.active_class == "warrior" and not game_manager.run_active)
	var fresh: Dictionary = save.data.duplicate(true)
	save.load_game()
	assert(JSON.parse_string(JSON.stringify(save.data)) == JSON.parse_string(JSON.stringify(fresh)), "Reset survives restarting and never restores old progression")
	assert(not FileAccess.file_exists(save.SAVE_PATH + ".reset_tmp"))
	main.queue_free()
	await tree.process_frame
	tree.root.get_node("AudioManager").stop_all()
	print("PASS: full player reset, every class/record/currency, defaults, persisted fresh save, UI confirmation/cancel and failed-write/active-run protection")
