extends RefCounted
class_name EquipmentExchange
const GOLD_VALUES := [15, 40, 100]
const CRYSTAL_VALUES := [1, 3, 8, 20]

static func quote(item: EquipmentData) -> Dictionary:
	var tier := ItemTiers.index(str(item.rarity))
	return {"currency": "gold", "unit_value": GOLD_VALUES[tier]} if tier < 3 else {"currency": "crystals", "unit_value": CRYSTAL_VALUES[tier - 3]}

static func resolve(save: Dictionary, id: String, amount: int, owner: String) -> Dictionary:
	var item: EquipmentData = ContentCatalog.equipment.get(id)
	if item == null or amount <= 0 or amount > TransmutationRules.quantity(save, id):
		return {"ok": false, "reason": "Selecione um item e uma quantidade disponível."}
	if not save.unlocked_classes.has(owner) or (item.class_id != &"" and str(item.class_id) != owner):
		return {"ok": false, "reason": "O item não pertence à classe selecionada."}
	if TransmutationRules.protected_ids(save).has(id):
		return {"ok": false, "reason": "Favoritos, equipamentos em uso e armas iniciais estão protegidos."}
	if bool(save.transmutation.last_result.get("pending", false)):
		return {"ok": false, "reason": "Confira o resultado da fusão antes de trocar seus itens."}
	var price := quote(item)
	var total := amount * int(price.unit_value)
	var updated := save.duplicate(true)
	TransmutationRules.consume(updated, id, amount)
	updated[str(price.currency)] = int(updated.get(str(price.currency), 0)) + total
	var receipt := {"item_id": id, "amount": amount, "currency": str(price.currency), "unit_value": int(price.unit_value), "total": total}
	var ledger: Dictionary = updated.get("equipment_exchange", {"sold": 0, "gold": 0, "crystals": 0, "last_receipt": {}})
	ledger.sold = int(ledger.sold) + amount
	ledger[str(price.currency)] = int(ledger.get(str(price.currency), 0)) + total
	ledger.last_receipt = receipt
	updated.equipment_exchange = ledger
	return {"ok": true, "save": updated, "receipt": receipt}
