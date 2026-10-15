extends RefCounted
class_name EquipmentWager
## Equipment-only wagers. Resolution is atomic and uses the existing pending reveal.
const MIN_INPUTS := 4
const MAX_INPUTS := 12
const MAX_CHANCE := 0.90
const CONSOLATION_RATE := 0.25

static func target_available(save: Dictionary, id: String, owner: String) -> bool:
	var item: EquipmentData = ContentCatalog.equipment.get(id)
	if item == null or not save.unlocked_classes.has(owner): return false
	if item.class_id != &"" and str(item.class_id) != owner: return false
	if save.get("favorite_equipment", []).has(id): return false
	var recipe: Dictionary = ContentCatalog.get_forge_recipe("forge_" + id)
	if recipe.is_empty(): return false
	if bool(recipe.get("generated", false)):
		if int(save.highest_difficulty) < item.required_difficulty: return false
		var cleared := int(save.get("campaign_progress", {}).get(str(item.required_difficulty), 0))
		var ordinal := CampaignRules.ordinal(str(item.region_id), 1)
		if ordinal < 0 or ordinal > cleared: return false
	return true

static func targets(save: Dictionary, owner: String) -> Array[EquipmentData]:
	var result: Array[EquipmentData] = []
	for recipe in ContentCatalog.forge_recipes:
		var id := str(recipe.result)
		if target_available(save, id, owner): result.append(ContentCatalog.equipment[id])
	result.sort_custom(func(a: EquipmentData, b: EquipmentData) -> bool:
		if not is_equal_approx(a.power_score(), b.power_score()): return a.power_score() < b.power_score()
		return str(a.id).naturalnocasecmp_to(str(b.id)) < 0)
	return result

static func value(item: EquipmentData) -> float:
	return pow(3.0, ItemTiers.index(str(item.rarity))) * (1.0 + sqrt(maxf(0, item.power_score())) / 35.0)

static func quote(_save: Dictionary, target: String, inputs: Array) -> Dictionary:
	var item: EquipmentData = ContentCatalog.equipment.get(target)
	var offered := 0.0
	var sale := {"gold": 0, "crystals": 0}
	for id in inputs:
		var ingredient: EquipmentData = ContentCatalog.equipment.get(str(id))
		if ingredient == null: continue
		offered += value(ingredient)
		var price := EquipmentExchange.quote(ingredient)
		sale[str(price.currency)] += int(price.unit_value)
	var consolation := {"gold": 0, "crystals": 0}
	for currency in sale:
		if int(sale[currency]) > 0: consolation[currency] = maxi(1, floori(int(sale[currency]) * CONSOLATION_RATE))
	var chance := 0.0 if item == null or inputs.is_empty() else clampf(offered / value(item) * 0.20, 0.01, MAX_CHANCE)
	return {"chance": chance, "consolation": consolation, "sale_value": sale, "offered_value": offered}

static func validate(save: Dictionary, target: String, inputs: Array, owner: String) -> String:
	if owner != str(save.selected_class): return "Use o inventário do personagem selecionado."
	if not target_available(save, target, owner): return "Escolha um prêmio da sua classe já liberado na Forja."
	if inputs.size() < MIN_INPUTS or inputs.size() > MAX_INPUTS: return "Ofereça de 4 a 12 equipamentos para apostar."
	if bool(save.get("transmutation", {}).get("last_result", {}).get("pending", false)): return "Confira o resultado anterior antes de apostar."
	var protected := TransmutationRules.protected_ids(save)
	var required := {}
	for value_id in inputs:
		var id := str(value_id)
		var item: EquipmentData = ContentCatalog.equipment.get(id)
		if item == null or TransmutationRules.quantity(save, id) == 0: return "Um dos itens oferecidos não está no inventário."
		if protected.has(id): return "Favoritos, itens equipados e armas iniciais estão protegidos."
		if item.class_id != &"" and str(item.class_id) != owner: return "Use somente equipamentos deste personagem."
		required[id] = int(required.get(id, 0)) + 1
		if int(required[id]) > TransmutationRules.quantity(save, id): return "Você não possui todas as cópias oferecidas."
	return ""

static func resolve(save: Dictionary, target: String, inputs: Array, owner: String, rng: RandomNumberGenerator) -> Dictionary:
	var reason := validate(save, target, inputs, owner)
	if not reason.is_empty(): return {"ok": false, "reason": reason}
	var offer := quote(save, target, inputs)
	var success := rng.randf() < float(offer.chance)
	var updated := save.duplicate(true)
	if not updated.has("equipment_quantities"): updated.equipment_quantities = {}
	for id in inputs: TransmutationRules.consume(updated, str(id), 1)
	if success: TransmutationRules.add_copy(updated, target)
	else:
		updated.gold = int(updated.gold) + int(offer.consolation.gold)
		updated.crystals = int(updated.crystals) + int(offer.consolation.crystals)
	var state: Dictionary = updated.get("transmutation", {"attempts": {}, "failures": {}, "last_result": {}})
	var ledger: Dictionary = state.get("wagers", {"attempts": 0, "wins": 0})
	ledger.attempts = int(ledger.attempts) + 1
	if success: ledger.wins = int(ledger.wins) + 1
	state.wagers = ledger
	var result := {"kind": "wager", "pending": true, "success": success, "chance": offer.chance, "owner": owner, "target_id": target, "result_id": target if success else "", "bonus_id": "", "consolation": offer.consolation if not success else {"gold": 0, "crystals": 0}, "consumed": inputs.duplicate()}
	state.last_result = result
	updated.transmutation = state
	return {"ok": true, "save": updated, "result": result}
