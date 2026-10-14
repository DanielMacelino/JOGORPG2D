extends RefCounted
## Four regional accessories and one signature weapon for each class in every region.
const REGIONS := ["verdant_reach", "hollow_cairn", "ember_crater", "black_keep", "frostwood", "sunken_mire"]
const NAMES := ["do Espinheiro", "do Ossuário", "da Caldeira", "do Crepúsculo", "da Geada", "dos Esporos"]
const WEAPON_NAMES := {"warrior": "Escudo-Lâmina", "mage": "Cetro", "ranger": "Arco", "assassin": "Adagas", "druid": "Cajado", "paladin": "Martelo"}

static func populate(items: Dictionary) -> void:
	for index in REGIONS.size():
		var region: String = REGIONS[index]
		var suffix: String = NAMES[index]
		var effect: Dictionary = [{"thorns": 0.18}, {"projectile_bounces": 1.0}, {"burn_on_hit": 0.18}, {"crit_chance": 0.06}, {"chill_on_hit": 0.22}, {"summon_duration": 4.0, "summon_damage_pct": 0.10}][index]
		var effect_copy: String = ["Retaliação: devolve 18% do dano recebido aos inimigos próximos.", "Flechas ricocheteiam para mais um alvo com 80% do dano.", "Ataques queimam o alvo por 3 s: 18% do dano por segundo.", "Chance de crítico +6 pontos percentuais.", "Ataques retardam o alvo em 22% por 2 s.", "Invocações duram +4 s e causam +10% de dano."][index]
		_add(items, region + "_signet", "Sinete " + suffix, "ring", "rare", "damage_pct", 0.08 + index * 0.01, region, "", effect, "+%d%% de dano. %s" % [8 + index, effect_copy])
		_add(items, region + "_mantle", "Couraça " + suffix, "armor", "rare", "health", 28 + index * 8, region, "", {"defense": 2.0}, "+%d de vida e +2 de defesa." % (28 + index * 8))
		_add(items, region + "_treads", "Passos " + suffix, "boots", "uncommon", "speed_pct", 0.08 + index * 0.01, region, "", {"pickup_radius": 25.0}, "+%d%% de movimento e +25 de alcance de coleta." % (8 + index))
		_add(items, region + "_charm", "Talismã " + suffix, "amulet", "epic", "health", 24 + index * 6, region, "", effect, "+%d de vida. %s" % [24 + index * 6, effect_copy])
		for owner in WEAPON_NAMES:
			var bonuses: Dictionary = {"warrior": {"health": 45.0, "defense": 2.0}, "mage": {"splash_radius": 22.0}, "ranger": {"projectile_bounces": 1.0}, "assassin": {"cleave_targets": 1.0, "crit_chance": 0.04}, "druid": {"summon_duration": 3.0, "summon_damage_pct": 0.15}, "paladin": {"attack_speed_pct": 0.10, "defense": 1.0}}[owner]
			var description: String = {"warrior": "+45 de vida e +2 de defesa.", "mage": "+22 de raio das explosões básicas.", "ranger": "Flechas ricocheteiam para mais um alvo com 80% do dano.", "assassin": "+1 alvo por golpe e +4 pontos percentuais de crítico.", "druid": "Invocações duram +3 s e causam +15% de dano.", "paladin": "+10% de velocidade de ataque e +1 de defesa."}[owner]
			_add(items, region + "_" + owner, WEAPON_NAMES[owner] + " " + suffix, "weapon", "epic" if index >= 3 else "rare", "damage", 6 + index * 2, region, str(owner), bonuses, "+%d de dano. %s" % [6 + index * 2, description])

static func _add(items: Dictionary, id: String, title: String, slot: String, rarity: String, stat: String, amount: float, region: String, owner: String, bonuses: Dictionary, description: String) -> void:
	var item := EquipmentData.new()
	item.id = StringName(id)
	item.display_name = title
	item.slot = StringName(slot)
	item.rarity = StringName(rarity)
	item.stat = StringName(stat)
	item.stat_amount = amount
	item.region_id = StringName(region)
	item.class_id = StringName(owner)
	item.bonuses = bonuses.duplicate()
	item.description = description
	items[id] = item
