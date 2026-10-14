extends RefCounted
## Deterministic class/slot/region/family/tier catalog: 6,048 distinct equipment IDs.
const SLOTS := ["weapon", "helmet", "armor", "boots", "ring", "amulet"]
const SLOT_NAMES := {"weapon": "Arma", "helmet": "Elmo", "armor": "Armadura", "boots": "Botas", "ring": "Anel", "amulet": "Amuleto"}
const CLASS_NAMES := {"warrior": "Bastião", "mage": "Oráculo", "ranger": "Vigília", "assassin": "Sombra", "druid": "Seiva", "paladin": "Aurora"}
const WEAPONS := {"warrior": "Escudo-Lâmina", "mage": "Cetro", "ranger": "Arco", "assassin": "Adagas", "druid": "Cajado", "paladin": "Martelo"}
const REGIONS := ["verdant_reach", "hollow_cairn", "ember_crater", "black_keep", "frostwood", "sunken_mire"]
const REGION_NAMES := ["Espinheiro", "Ossuário", "Caldeira", "Crepúsculo", "Geada", "Esporos"]
const FAMILIES := ["Fortaleza", "Assalto", "Horizonte", "Ritual"]
static func populate(items: Dictionary, classes: Dictionary) -> void:
	for owner in CLASS_NAMES:
		var data: ClassData = classes[owner]
		for slot in SLOTS:
			for region_index in REGIONS.size():
				for family_index in FAMILIES.size():
					var family := "%s_%s_%s_%d" % [owner, slot, REGIONS[region_index], family_index]
					for tier in ItemTiers.ORDER.size():
						var item := EquipmentData.new()
						item.id = StringName("gear_" + family + "_" + str(tier))
						item.family_id = StringName(family)
						item.tier_index = tier
						item.generated = true
						item.required_difficulty = ItemTiers.REQUIRED_DIFFICULTIES[tier]
						item.class_id = StringName(owner)
						item.slot = StringName(slot)
						item.region_id = StringName(REGIONS[region_index])
						item.rarity = StringName(ItemTiers.ORDER[tier])
						var noun: String = WEAPONS[owner] if slot == "weapon" else SLOT_NAMES[slot]
						item.display_name = "%s %s %s - %s - %s (%s)" % [noun, "do" if owner in ["warrior", "mage"] else "da", CLASS_NAMES[owner], FAMILIES[family_index], REGION_NAMES[region_index], ItemTiers.label(str(item.rarity))]
						var scale: float = ItemTiers.EQUIPMENT_SCALE[tier] * (1 + region_index * 0.035)
						match slot:
							"weapon":
								item.stat = &"damage"
								item.stat_amount = data.damage * 0.18 * scale
							"helmet", "armor", "amulet":
								item.stat = &"health"
								item.stat_amount = data.max_health * (0.07 if slot == "armor" else 0.045) * scale
							"boots":
								item.stat = &"speed_pct"
								item.stat_amount = 0.025 * scale
							"ring":
								item.stat = &"damage_pct"
								item.stat_amount = 0.025 * scale
						item.bonuses = _family_bonus(owner, family_index, scale)
						if tier >= 3: item.bonuses.merge(_regional_bonus(owner, region_index, tier), true)
						item.description = describe({str(item.stat): item.stat_amount}) + ". " + describe(item.bonuses) + "."
						items[str(item.id)] = item
static func _family_bonus(owner: String, family: int, scale: float) -> Dictionary:
	match family:
		0: return {"defense": 0.6 * scale, "health": (12.0 if owner == "warrior" else 4.0) * scale}
		1: return {"damage_pct": 0.018 * scale, "attack_speed_pct": 0.02 * scale}
		2: return {"speed_pct": 0.014 * scale, "pickup_radius": 8.0 * scale}
	match owner:
		"warrior": return {"thorns": 0.035 * scale, "defense": 0.45 * scale}
		"mage": return {"splash_radius": 6.0 * scale, "crit_chance": 0.006 * scale}
		"ranger": return {"attack_speed_pct": 0.035 * scale, "crit_chance": 0.006 * scale}
		"assassin": return {"crit_chance": 0.012 * scale, "lifesteal": 0.0005 * scale}
		"druid": return {"summon_duration": 0.6 * scale, "summon_damage_pct": 0.025 * scale}
	return {"defense": 0.4 * scale, "regen": 0.06 * scale}
static func _regional_bonus(owner: String, region: int, tier: int) -> Dictionary:
	var strength := 1.0 + (tier - 3) * 0.3
	match region:
		0: return {"thorns": 0.05 * strength}
		1: return {"projectile_bounces": 1.0} if owner == "ranger" else {"crit_chance": 0.018 * strength}
		2: return {"burn_on_hit": 0.05 * strength}
		3: return {"crit_chance": 0.02 * strength}
		4: return {"chill_on_hit": 0.08 * strength}
	return {"summon_duration": 1.0 * strength} if owner == "druid" else {"regen": 0.12 * strength}
static func describe(values: Dictionary) -> String:
	var names := {"damage": "dano", "health": "vida", "damage_pct": "dano", "speed_pct": "movimento", "attack_speed_pct": "ataque", "defense": "defesa", "pickup_radius": "coleta", "thorns": "retaliação", "splash_radius": "área", "crit_chance": "crítico", "lifesteal": "roubo de vida", "summon_duration": "s de invocação", "summon_damage_pct": "dano invocado", "regen": "vida/s", "projectile_bounces": "ricochete", "burn_on_hit": "queimadura", "chill_on_hit": "lentidão"}
	var percentages := ["damage_pct", "speed_pct", "attack_speed_pct", "thorns", "crit_chance", "lifesteal", "summon_damage_pct", "burn_on_hit", "chill_on_hit"]
	var parts := PackedStringArray()
	for key in values:
		var value := float(values[key]) * (100 if percentages.has(key) else 1)
		var number := ("%.1f" % value).trim_suffix(".0")
		parts.append("+%s%s %s" % [number, "%" if percentages.has(key) else "", names.get(key, key)])
	return ", ".join(parts)
static func populate_recipes(recipes: Array[Dictionary], items: Dictionary) -> void:
	for item in items.values():
		if not item.generated or item.tier_index == 0: continue
		var source_id := "gear_%s_%d" % [item.family_id, item.tier_index - 1]
		var source: EquipmentData = items[source_id]
		recipes.append({"id": "forge_" + str(item.id), "result": str(item.id), "result_name": item.display_name, "ingredients": [{"id": source_id, "name": source.display_name, "qty": 1}], "gold_cost": roundi(140 * pow(2.0, item.tier_index - 1)), "crystal_cost": [0, 1, 2, 4, 8, 16, 32][item.tier_index], "desc": item.description, "rarity_result": str(item.rarity), "required_difficulty": item.required_difficulty, "generated": true})
