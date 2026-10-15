extends RefCounted
## Twenty extra seven-tier families use the supplementary models and existing slots.
const REGIONS := ["verdant_reach", "hollow_cairn", "ember_crater", "black_keep", "frostwood", "sunken_mire"]
const EXTRA_WEAPONS := [
	["paladin", "Tridente da Aurora", "spear"], ["paladin", "Martelo da Forja", "hammer"],
	["ranger", "Besta do Vigia", "bow"], ["warrior", "Lâmina da Vigília", "sword"],
	["assassin", "Adaga do Crepúsculo", "daggers"], ["assassin", "Chicote da Penumbra", "whip"],
	["paladin", "Machado da Alvorada", "axe"], ["assassin", "Lâmina do Abismo", "daggers"],
	["druid", "Espinho da Seiva", "roots"], ["mage", "Cetro Rubro", "staff"],
	["assassin", "Presa do Eclipse", "daggers"], ["assassin", "Foice do Véu", "scythe"],
	["assassin", "Punhal do Juramento", "daggers"]]
const SHIELD_ROWS := [1, 2, 3, 4, 5, 6, 8, 12]
const ARMOR := [[7, 2, "helmet", "Elmo de Aço"], [8, 2, "armor", "Couraça do Vigia"], [9, 2, "armor", "Perneiras da Guarda"], [10, 2, "boots", "Botas de Ferro"], [7, 13, "amulet", "Amuleto do Eclipse"]]

static func populate(items: Dictionary, classes: Dictionary) -> void:
	for item in items.values():
		# Visual replacement keeps every existing ID, stat, recipe and owned copy valid.
		if item.class_id == &"paladin" and item.slot == &"weapon":
			item.display_name = item.display_name.replace("Martelo", "Espada")
	for row in EXTRA_WEAPONS.size():
		var entry: Array = EXTRA_WEAPONS[row]
		for tier in 7:
			var item := _item("weapon_%02d" % row, str(entry[0]), "weapon", str(entry[1]), row % 6, tier, classes)
			item.visual_column = 6
			item.visual_row = row
			item.weapon_kind = StringName(entry[2])
			items[str(item.id)] = item
	for variant in 2:
		for tier in 7:
			var item := _item("shield_%d" % variant, "warrior", "weapon", "Espada e Estandarte" if variant == 0 else "Espada e Égide", variant, tier, classes)
			item.shield_visual_column = 5
			item.shield_visual_row = SHIELD_ROWS[mini(7, tier + variant)]
			item.bonuses = {"defense": 0.8 * ItemTiers.EQUIPMENT_SCALE[tier], "health": 14.0 * ItemTiers.EQUIPMENT_SCALE[tier]}
			item.description = EquipmentExpansion.describe({str(item.stat): item.stat_amount}) + ". " + EquipmentExpansion.describe(item.bonuses) + ". Espada e escudo ocupam o mesmo espaço de arma."
			items[str(item.id)] = item
	for index in ARMOR.size():
		var entry: Array = ARMOR[index]
		for tier in 7:
			var item := _item("armor_%d" % index, "warrior" if index < 4 else "mage", str(entry[2]), str(entry[3]), index % 6, tier, classes)
			item.visual_column = int(entry[0])
			item.visual_row = int(entry[1])
			items[str(item.id)] = item

const EquipmentExpansion := preload("res://scripts/data/equipment_expansion.gd")
static func _item(code: String, owner: String, slot: String, title: String, region: int, tier: int, classes: Dictionary) -> EquipmentData:
	var item := EquipmentData.new()
	item.family_id = StringName("sheet_" + code)
	item.id = StringName("gear_%s_%d" % [item.family_id, tier])
	item.class_id = StringName(owner)
	item.slot = StringName(slot)
	item.tier_index = tier
	item.rarity = StringName(ItemTiers.ORDER[tier])
	item.required_difficulty = ItemTiers.REQUIRED_DIFFICULTIES[tier]
	item.region_id = StringName(REGIONS[region])
	item.generated = true
	item.display_name = title + " · " + ItemTiers.label(str(item.rarity))
	var data: ClassData = classes[owner]
	var scale: float = ItemTiers.EQUIPMENT_SCALE[tier] * (1 + region * 0.035)
	item.stat = &"damage" if slot == "weapon" else (&"speed_pct" if slot == "boots" else &"health")
	item.stat_amount = (data.damage * 0.18 if slot == "weapon" else (0.025 if slot == "boots" else data.max_health * 0.045)) * scale
	item.bonuses = EquipmentExpansion._family_bonus(owner, 1 if slot == "weapon" else 0, scale)
	if tier >= 3: item.bonuses.merge(EquipmentExpansion._regional_bonus(owner, region, tier), true)
	item.description = EquipmentExpansion.describe({str(item.stat): item.stat_amount}) + ". " + EquipmentExpansion.describe(item.bonuses) + "."
	return item
