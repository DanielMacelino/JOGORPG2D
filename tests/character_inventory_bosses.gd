extends RefCounted
const ART := preload("res://scripts/data/pixel_enemy_sprites.gd")

func run(tree: SceneTree) -> void:
	var save: Node = tree.root.get_node("SaveManager")
	var previous: Dictionary = save.data.duplicate(true)
	_test_migration(save)
	_test_stock(tree, save)
	await _test_bosses(tree, save)
	save.data = previous
	save.save_game()
	print("PASS CHARACTER INVENTORIES: conserved legacy copies, idempotent migration, isolated stock/materials/favorites/forge/fusion, shared currencies, correct remote reward owners and five animated regional bosses")

func _fresh(save: Node) -> void:
	save.data = save.DEFAULT_SAVE.duplicate(true)
	save._initialize_progression(false)

func _test_migration(save: Node) -> void:
	var legacy: Dictionary = save.DEFAULT_SAVE.duplicate(true)
	legacy.erase("character_inventory_schema")
	legacy.selected_class = "mage"
	legacy.gold = 123
	legacy.crystals = 7
	legacy.equipment.append_array(["flame_sword", "void_staff", "ember_signet"])
	legacy.equipment_quantities = {"ember_signet": 3, "flame_sword": 2}
	legacy.favorite_equipment = ["ember_signet"]
	legacy.materials = {"iron": 11}
	legacy.class_loadouts.warrior.ring = "ember_signet"
	legacy.class_loadouts.mage.ring = "ember_signet"
	legacy.transmutation.attempts = {"common": 8}
	var file := FileAccess.open(save.SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy))
	file.close()
	var original := FileAccess.get_file_as_string(save.SAVE_PATH)
	var blocked := ProjectSettings.globalize_path(save.SAVE_PATH + ".inventory_tmp")
	assert(DirAccess.make_dir_absolute(blocked) == OK)
	save.load_game()
	assert(FileAccess.get_file_as_string(save.SAVE_PATH) == original, "A failed inventory migration must preserve the original file")
	assert(DirAccess.remove_absolute(blocked) == OK)
	save.load_game()
	assert(save.data.gold == 123 and save.data.crystals == 7)
	assert(save.equipment_quantity("flame_sword", "warrior") == 2 and save.equipment_quantity("flame_sword", "mage") == 0)
	assert(save.equipment_quantity("void_staff", "mage") == 1 and save.equipment_quantity("void_staff", "warrior") == 0)
	assert(save.equipment_quantity("ember_signet", "mage") == 2 and save.equipment_quantity("ember_signet", "warrior") == 1)
	assert(save.inventory_for("mage").materials.iron == 11 and save.inventory_for("warrior").materials.is_empty())
	assert(save.inventory_for("mage").transmutation.attempts.common == 8 and save.inventory_for("warrior").transmutation.attempts.is_empty())
	assert(save.inventory_for("warrior").favorite_equipment.has("ember_signet"))
	var migrated: Dictionary = save.data.duplicate(true)
	save.load_game()
	assert(save.data == migrated, "A reload cannot reassign copies or repeat migration")

func _test_stock(tree: SceneTree, save: Node) -> void:
	_fresh(save)
	assert(save.owned_equipment() == ["field_blade"] and save.owned_equipment("mage") == ["moon_staff"])
	save.data.gold = 100000
	save.data.crystals = 1000
	save.unlock_equipment("ember_signet", "warrior")
	save.inventory_for("warrior").materials.iron = 12
	save.data.transmutation.attempts.common = 9
	assert(save.set_equipment_favorite("ember_signet", true))
	assert(tree.root.get_node("EquipmentManager").equip("ring", "ember_signet", "warrior"))
	assert(not tree.root.get_node("EquipmentManager").equip("ring", "ember_signet", "mage"))
	var before: Dictionary = save.inventory_for("warrior").duplicate(true)
	save.set_selected_class("mage")
	assert(not save.data.equipment.has("ember_signet") and save.data.transmutation.attempts.is_empty() and save.data.materials.is_empty())
	assert(save.grant_equipment_drop("ember_signet", "mage-copy", "mage") == OK)
	assert(not save.is_equipment_favorite("ember_signet"))
	assert(save.set_equipment_favorite("ember_signet", true))
	save.data.materials.iron = 2
	assert(save.set_equipment_favorite("ember_signet", false))
	assert(tree.root.get_node("EquipmentManager").equip("ring", "ember_signet", "mage"))
	assert(save.grant_equipment_drop("flame_sword", "warrior-online", "warrior") == OK)
	assert(save.equipment_quantity("flame_sword", "warrior") == 1 and save.equipment_quantity("flame_sword", "mage") == 0)
	assert(save.grant_equipment_drop("flame_sword", "wrong-owner", "mage") == ERR_INVALID_PARAMETER)
	assert(not save.transmute_equipment([], "warrior").ok)
	assert(not save.exchange_equipment("ember_signet", 1, "warrior").ok)
	assert(save.data.gold == 100000 and save.data.crystals == 1000)
	save.load_game()
	assert(save.inventory_for("warrior").materials.iron == 12 and save.inventory_for("mage").materials.iron == 2)
	assert(int(save.inventory_for("warrior").transmutation.attempts.common) == int(before.transmutation.attempts.common) and save.inventory_for("warrior").transmutation.attempts.size() == 1)
	assert(save.inventory_for("warrior").favorite_equipment.has("ember_signet") and not save.inventory_for("mage").favorite_equipment.has("ember_signet"))
	assert(save.equipment_quantity("ember_signet", "warrior") == 1 and save.equipment_quantity("ember_signet", "mage") == 1)
	save.set_selected_class("warrior")
	assert(save.is_equipment_favorite("ember_signet") and save.data.materials.iron == 12)
	var profile: Dictionary = tree.root.get_node("NetworkSession").profile("Mago", "mage")
	assert(profile.owned.has("moon_staff") and profile.owned.has("ember_signet") and not profile.owned.has("flame_sword"))
	assert(save.grant_equipment_drop("ember_signet", "invalid-class", "missing") == ERR_INVALID_PARAMETER)
	assert(save.forge_item("flame_sword") == false, "Only real recipe IDs are accepted")
	# Forge an actual class recipe while the other character has an independent copy equipped.
	for recipe in ContentCatalog.forge_recipes:
		if str(recipe.result) != "flame_sword": continue
		assert(save.can_forge(str(recipe.id)) and save.forge_item(str(recipe.id)))
		assert(save.equipment_quantity("flame_sword", "warrior") == 2)
		assert(save.loadout_for("mage").ring == "ember_signet")
		assert(save.inventory_for("mage").forge_upgrades.is_empty())
		break

func _test_bosses(tree: SceneTree, save: Node) -> void:
	_fresh(save)
	var expected := {"hollow_cairn": "death_lord", "ember_crater": "lava_lord", "black_keep": "vampire_king", "frostwood": "frost_guardian", "sunken_mire": "mire_queen"}
	var game: ExpeditionGame = load("res://scenes/game.tscn").instantiate()
	tree.root.add_child(game)
	game.wave_director.stop()
	game.phase_director.set_process(false)
	game.process_mode = Node.PROCESS_MODE_DISABLED
	game.enemy_manager.clear()
	var companion: Node = load("res://scripts/world/forest_companion.gd").new()
	companion.process_mode = Node.PROCESS_MODE_DISABLED
	game.add_child(companion)
	assert(not companion.has_node("RootlingSprite"))
	companion.kind = "rootling"
	assert(companion.has_node("RootlingSprite") and companion.rootling_sprite.visible, "A late network kind must initialize its native sprite")
	companion.kind = "grove_tree"
	assert(not companion.rootling_sprite.visible)
	for region in expected:
		var kind := str(expected[region])
		game.enemy_manager.map_data = CampaignRules.expedition(region, 10, 0)
		var boss := game.enemy_manager.spawn_boss(StringName(kind), 5)
		assert(boss.has_node("PixelSprite") and boss.has_node("BossBrain"))
		assert(boss.get_node("BossBrain").sovereign and boss.data.boss)
		var sprite: Sprite2D = boss.get_node("PixelSprite")
		var image := ART.texture_for(kind).get_image()
		for action in ["idle", "walk", "attack"]:
			for index in int(ART.LAYOUTS[kind][action].y):
				var rect := Rect2i(ART.frame_rect(kind, action, index))
				var frame := image.get_region(rect)
				var used := frame.get_used_rect()
				assert(used.has_area() and used.size.x > 20 and used.size.y > 30)
				if kind in ["vampire_king", "frost_guardian", "mire_queen"]:
					assert(frame.get_pixel(0, 0).a == 0, "Checkerboard must be removed from every crop")
				var foot := ART.foot_for(kind, action, index)
				assert(foot.x > 0 and foot.x < rect.size.x and foot.y > 0 and foot.y <= rect.size.y)
		sprite.pose(StringName(kind), 0.2, 1, 0, Vector2.LEFT, 0, 1)
		assert(sprite.texture == ART.texture_for(kind) and sprite.flip_h)
		assert(ART.portrait_for(kind) is AtlasTexture)
		boss.queue_free()
	await tree.process_frame
	game.queue_free()
	await tree.process_frame
