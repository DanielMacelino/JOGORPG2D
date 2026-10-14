extends Node
class_name LootManager

var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()

func roll_boss_reward(region: String = "verdant_reach", class_id: String = "warrior", phase: int = 1, owned: Variant = null, difficulty: int = 0) -> Dictionary:
	var inventory: Array = SaveManager.data.equipment if owned == null else owned
	var owned_ids := {}
	for id in inventory: owned_ids[str(id)] = true
	var pool: Array[EquipmentData] = []
	var unseen: Array[EquipmentData] = []
	for item in ContentCatalog.equipment.values():
		if item.required_difficulty <= difficulty and str(item.region_id) == region and (item.class_id == &"" or str(item.class_id) == class_id):
			pool.append(item)
			if not owned_ids.has(str(item.id)):
				unseen.append(item)
	# Prefer new discoveries, but still allow repeat drops for currency when a set is complete.
	var candidates := unseen if not unseen.is_empty() else pool
	var selected: EquipmentData
	var total := 0.0
	for item in candidates:
		total += _weight(item, phase)
	var roll := rng.randf() * total
	for item in candidates:
		roll -= _weight(item, phase)
		if roll <= 0:
			selected = item
			break
	if selected == null and not candidates.is_empty():
		selected = candidates.back()
	return {"gold": 140 + rng.randi_range(0, 55), "equipment": str(selected.id) if selected != null else "oak_charm", "crystals": 2 if phase == 10 else 1}

func _weight(item: EquipmentData, phase: int) -> float:
	if item.generated:
		return float(ItemTiers.WEIGHTS[item.tier_index]) * (1.0 + (phase / 10.0 if item.tier_index >= 3 else 0.0))
	if item.rarity == &"epic":
		return 2.0 if phase == 10 else 0.45 + phase * 0.06
	return 1.0
