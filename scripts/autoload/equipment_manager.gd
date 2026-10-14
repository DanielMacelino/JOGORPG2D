extends Node

func equip(slot: String, item_id: String, class_id: String = "") -> bool:
	var item: EquipmentData = ContentCatalog.equipment.get(str(item_id))
	if item == null or not SaveManager.data.equipment.has(item_id) or str(item.slot) != slot:
		return false
	var target_class := class_id if not class_id.is_empty() else str(SaveManager.data.get("selected_class", "warrior"))
	if item.class_id != &"" and str(item.class_id) != target_class:
		return false
	SaveManager.equip_item(slot, item_id, target_class)
	return true

func equipped_bonuses(class_id: String = "") -> Dictionary:
	var result := {"damage": 0.0, "damage_pct": 0.0, "speed_pct": 0.0, "health": 0.0}
	var target_class := class_id if not class_id.is_empty() else str(SaveManager.data.get("selected_class", "warrior"))
	var equipped: Dictionary = SaveManager.loadout_for(target_class)
	for item_id in equipped.values():
		var item: EquipmentData = ContentCatalog.equipment.get(str(item_id))
		if item == null:
			continue
		if item.class_id != &"" and str(item.class_id) != target_class:
			continue
		if result.has(str(item.stat)):
			result[str(item.stat)] += item.stat_amount
		for stat in item.bonuses:
			result[stat] = float(result.get(stat, 0.0)) + float(item.bonuses[stat])
	return result

func unlock_next_class_item(class_id: String, region: String = "verdant_reach", difficulty: int = 0) -> String:
	for item_key in ContentCatalog.equipment:
		var item: EquipmentData = ContentCatalog.equipment[item_key]
		if item.region_id != &"" or str(item.class_id) != class_id or SaveManager.data.equipment.has(str(item.id)):
			continue
		SaveManager.unlock_equipment(str(item.id))
		return str(item.id)
	var owned := {}
	for id in SaveManager.data.equipment: owned[str(id)] = true
	var pool: Array[String] = []
	for item in ContentCatalog.equipment.values():
		if item.generated and str(item.class_id) == class_id and str(item.region_id) == region and item.required_difficulty <= difficulty and not owned.has(str(item.id)):
			pool.append(str(item.id))
	if not pool.is_empty():
		var chosen: String = pool.pick_random()
		SaveManager.unlock_equipment(chosen)
		return chosen
	return ""

func equipped_item(class_id: String, slot: String) -> EquipmentData:
	var loadout := SaveManager.loadout_for(class_id)
	return ContentCatalog.equipment.get(str(loadout.get(slot, ""))) as EquipmentData
