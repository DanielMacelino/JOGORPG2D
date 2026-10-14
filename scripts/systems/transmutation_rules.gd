extends RefCounted
class_name TransmutationRules
## Inventory transactions are resolved on a copy and persisted before the reveal animation.
const INPUT_COUNT := 4
const CHANCES := [0.40, 0.32, 0.25, 0.18, 0.12, 0.08]

static func quantity(save: Dictionary, id: String) -> int:
	if not save.equipment.has(id): return 0
	return maxi(1, int(save.get("equipment_quantities", {}).get(id, 1)))

static func protected_ids(save: Dictionary) -> Dictionary:
	var protected := {}
	for id in ContentCatalog.classes:
		protected[str(ContentCatalog.classes[id].starter_weapon)] = true
	for loadout in save.get("class_loadouts", {}).values():
		for id in loadout.values(): protected[str(id)] = true
	for id in save.get("equipped", {}).values(): protected[str(id)] = true
	return protected

static func chance(save: Dictionary, rarity: String) -> float:
	var index: int = ItemTiers.ORDER.find(rarity)
	if index < 0 or index >= ItemTiers.ORDER.size() - 1: return 0.0
	var failures := int(save.get("transmutation", {}).get("failures", {}).get(rarity, 0))
	return minf(0.90, float(CHANCES[mini(index, CHANCES.size() - 1)]) + minf(0.15, failures * 0.02))

static func milestone_interval(rarity: String) -> int:
	return (ItemTiers.index(rarity) + 1) * 10

static func eligible_items(save: Dictionary, owner: String, rarity: String) -> Array[EquipmentData]:
	var result: Array[EquipmentData] = []
	var protected := protected_ids(save)
	for id in save.equipment:
		var item: EquipmentData = ContentCatalog.equipment.get(str(id))
		if item == null or protected.has(str(id)) or (rarity != "all" and str(item.rarity) != rarity): continue
		if item.class_id != &"" and str(item.class_id) != owner: continue
		result.append(item)
	result.sort_custom(func(a: EquipmentData, b: EquipmentData) -> bool:
		if not is_equal_approx(a.power_score(), b.power_score()): return a.power_score() < b.power_score()
		return str(a.id).naturalnocasecmp_to(str(b.id)) < 0)
	return result

static func validate(save: Dictionary, inputs: Array, owner: String) -> String:
	if not save.unlocked_classes.has(owner): return "Esta classe ainda está bloqueada."
	if inputs.size() != INPUT_COUNT: return "Selecione quatro itens da mesma raridade."
	if bool(save.get("transmutation", {}).get("last_result", {}).get("pending", false)):
		return "Veja o resultado anterior antes de iniciar outra fusão."
	var protected := protected_ids(save)
	var required := {}
	var rarity := ""
	for value in inputs:
		var id := str(value)
		var item: EquipmentData = ContentCatalog.equipment.get(id)
		if item == null or quantity(save, id) == 0: return "Um dos itens não está mais no inventário."
		if protected.has(id): return "Itens equipados ou iniciais estão protegidos."
		if item.class_id != &"" and str(item.class_id) != owner: return "Use itens da classe selecionada ou compartilhados."
		if rarity.is_empty(): rarity = str(item.rarity)
		if str(item.rarity) != rarity: return "Os quatro itens precisam ter a mesma raridade."
		required[id] = int(required.get(id, 0)) + 1
		if int(required[id]) > quantity(save, id): return "Você não possui essa quantidade do item."
	var index: int = ItemTiers.ORDER.find(rarity)
	if index < 0 or index >= ItemTiers.ORDER.size() - 1: return "Deus é a raridade máxima e não participa da fusão."
	return ""

static func consume(save: Dictionary, id: String, amount: int) -> void:
	var remaining := quantity(save, id) - amount
	if remaining <= 0:
		save.equipment.erase(id)
		save.equipment_quantities.erase(id)
	else:
		save.equipment_quantities[id] = remaining

static func add_copy(save: Dictionary, id: String) -> void:
	var count := quantity(save, id)
	if count == 0: save.equipment.append(id)
	if not save.has("equipment_quantities"): save.equipment_quantities = {}
	save.equipment_quantities[id] = count + 1

static func _reward(save: Dictionary, owner: String, rarity: String, rng: RandomNumberGenerator) -> String:
	var pool: Array[String] = []
	var discoveries: Array[String] = []
	for item in ContentCatalog.equipment.values():
		if str(item.rarity) != rarity or str(item.class_id) != owner: continue
		pool.append(str(item.id))
		if quantity(save, str(item.id)) == 0: discoveries.append(str(item.id))
	var candidates := discoveries if not discoveries.is_empty() else pool
	return candidates[rng.randi_range(0, candidates.size() - 1)] if not candidates.is_empty() else ""

static func resolve(save: Dictionary, inputs: Array, owner: String, rng: RandomNumberGenerator) -> Dictionary:
	var reason := validate(save, inputs, owner)
	if not reason.is_empty(): return {"ok": false, "reason": reason}
	var item: EquipmentData = ContentCatalog.equipment[str(inputs[0])]
	var rarity := str(item.rarity)
	var higher: String = ItemTiers.ORDER[ItemTiers.index(rarity) + 1]
	var probability := chance(save, rarity)
	var success := rng.randf() < probability
	var updated := save.duplicate(true)
	if not updated.has("equipment_quantities"): updated.equipment_quantities = {}
	for id in inputs: consume(updated, str(id), 1)
	var state: Dictionary = updated.get("transmutation", {"attempts": {}, "failures": {}, "last_result": {}})
	state.attempts[rarity] = int(state.attempts.get(rarity, 0)) + 1
	state.failures[rarity] = 0 if success else int(state.failures.get(rarity, 0)) + 1
	var interval := milestone_interval(rarity)
	var attempt := int(state.attempts[rarity])
	var result_id := _reward(updated, owner, higher if success else rarity, rng)
	if result_id.is_empty(): return {"ok": false, "reason": "Não há um resultado disponível para esta classe."}
	add_copy(updated, result_id)
	var bonus_id := ""
	if attempt % interval == 0:
		bonus_id = _reward(updated, owner, higher, rng)
		if bonus_id.is_empty(): return {"ok": false, "reason": "Não há uma recompensa de marco disponível."}
		add_copy(updated, bonus_id)
	var result := {"pending": true, "success": success, "chance": probability, "owner": owner, "input_rarity": rarity, "result_id": result_id, "bonus_id": bonus_id, "attempts": attempt, "milestone_interval": interval, "consumed": inputs.duplicate()}
	state.last_result = result
	updated.transmutation = state
	return {"ok": true, "save": updated, "result": result}
