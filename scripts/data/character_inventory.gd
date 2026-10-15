extends RefCounted
## The root inventory is a projection for existing screens, never a shared stash.
const FIELDS := {"equipment": [], "equipment_quantities": {}, "favorite_equipment": [], "forge_upgrades": {}, "materials": {}, "transmutation": {"attempts": {}, "failures": {}, "last_result": {}}, "equipment_exchange": {"sold": 0, "gold": 0, "crystals": 0, "last_receipt": {}}}
const META := preload("res://scripts/data/character_meta.gd")

static func profile(save: Dictionary, owner: String) -> Dictionary:
	var entry := META.profile(save, owner)
	for field in FIELDS:
		if not entry.has(field): entry[field] = FIELDS[field].duplicate(true)
	return entry

static func capture(save: Dictionary) -> void:
	if int(save.get("character_inventory_schema", 0)) < 1: return
	var entry := profile(save, str(save.get("selected_class", "warrior")))
	for field in FIELDS: entry[field] = save.get(field, FIELDS[field])

static func activate(save: Dictionary, owner: String) -> void:
	var entry := profile(save, owner)
	for field in FIELDS: save[field] = entry[field]

static func view(save: Dictionary, owner: String) -> Dictionary:
	return save if owner == str(save.get("selected_class", "warrior")) else profile(save, owner)

static func initialize(save: Dictionary) -> void:
	var selected := str(save.selected_class)
	for owner in ContentCatalog.CLASS_ORDER: profile(save, owner)
	if int(save.get("character_inventory_schema", 0)) < 1:
		# Assign every old copy exactly once. Class-bound items keep their class;
		# shared copies prefer existing wearers, with the selected wearer first.
		var order: Array = [selected]
		for owner in ContentCatalog.CLASS_ORDER:
			if owner != selected: order.append(owner)
		for id in save.get("equipment", []):
			var item: EquipmentData = ContentCatalog.equipment.get(str(id))
			if item == null: continue
			var count := TransmutationRules.quantity(save, str(id))
			var owners: Array = []
			if item.class_id != &"": owners.append(str(item.class_id))
			else:
				for owner in order:
					if save.get("class_loadouts", {}).get(owner, {}).values().has(id): owners.append(owner)
			if owners.is_empty(): owners.append(selected)
			for owner in owners:
				if count <= 0: break
				var assigned := count if item.class_id != &"" else 1
				_add(profile(save, str(owner)), str(id), assigned)
				count -= assigned
			if count > 0: _add(profile(save, selected), str(id), count)
			for owner in ContentCatalog.CLASS_ORDER:
				var entry := profile(save, owner)
				if entry.equipment.has(id) and save.get("favorite_equipment", []).has(id): entry.favorite_equipment.append(id)
		for field in ["materials", "transmutation", "equipment_exchange"]:
			profile(save, selected)[field] = save.get(field, FIELDS[field]).duplicate(true)
		for recipe_id in save.get("forge_upgrades", {}):
			var recipe: Dictionary = ContentCatalog.get_forge_recipe(str(recipe_id))
			var result: EquipmentData = ContentCatalog.equipment.get(str(recipe.get("result", "")))
			var owner := str(result.class_id) if result != null and result.class_id != &"" else selected
			profile(save, owner).forge_upgrades[recipe_id] = save.forge_upgrades[recipe_id]
		save.character_inventory_schema = 1
	for owner in ContentCatalog.CLASS_ORDER:
		var entry := profile(save, owner)
		var loadout: Dictionary = save.class_loadouts.get(owner, {})
		for slot in loadout.keys():
			if not entry.equipment.has(str(loadout[slot])): loadout.erase(slot)
		if save.unlocked_classes.has(owner):
			var starter := str(ContentCatalog.classes[owner].starter_weapon)
			if not starter.is_empty() and not entry.equipment.has(starter): _add(entry, starter, 1)
			if loadout.is_empty() and not starter.is_empty(): loadout.weapon = starter
		save.class_loadouts[owner] = loadout
	activate(save, selected)

static func _add(entry: Dictionary, id: String, count: int) -> void:
	var previous := TransmutationRules.quantity(entry, id)
	if not entry.equipment.has(id): entry.equipment.append(id)
	entry.equipment_quantities[id] = previous + count
