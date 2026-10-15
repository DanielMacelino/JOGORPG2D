extends RefCounted
## Compare actual equipment contributions, including stats removed by the replacement.
const NAMES := {"damage": "Dano", "health": "Vida", "defense": "Defesa", "damage_pct": "Dano", "health_pct": "Vida", "speed_pct": "Movimento", "attack_speed_pct": "Vel. de ataque", "crit_chance": "Crítico", "crit_multiplier": "Dano crítico", "lifesteal": "Roubo de vida", "regen": "Vida/s", "thorns": "Retaliação", "pickup_radius": "Coleta", "splash_radius": "Área", "projectile_bounces": "Ricochetes", "projectile_pierce": "Perfuração", "cleave_targets": "Alvos extras", "summon_duration": "Invocação (s)", "summon_damage_pct": "Dano invocado", "burn_on_hit": "Queimadura", "chill_on_hit": "Lentidão"}
const PERCENTAGES := ["damage_pct", "health_pct", "speed_pct", "attack_speed_pct", "crit_chance", "crit_multiplier", "lifesteal", "thorns", "summon_damage_pct", "burn_on_hit", "chill_on_hit"]

static func values(item: EquipmentData) -> Dictionary:
	if item == null: return {}
	var result := item.bonuses.duplicate()
	result[str(item.stat)] = float(result.get(str(item.stat), 0)) + item.stat_amount
	return result

static func rows(candidate: EquipmentData, equipped: EquipmentData) -> Array[Dictionary]:
	var before := values(equipped)
	var after := values(candidate)
	var keys: Array = NAMES.keys()
	for key in before.keys() + after.keys():
		if not keys.has(str(key)): keys.append(str(key))
	var result: Array[Dictionary] = []
	for key in keys:
		var old_value := float(before.get(key, 0))
		var new_value := float(after.get(key, 0))
		if is_zero_approx(old_value) and is_zero_approx(new_value): continue
		result.append({"key": key, "name": str(NAMES.get(key, str(key).capitalize())), "before": old_value, "after": new_value, "delta": new_value - old_value})
	return result

static func number(key: String, value: float, signed: bool = false) -> String:
	var scaled := value * (100 if key in PERCENTAGES else 1)
	var formatted := ("%.2f" % absf(scaled)).trim_suffix("00").trim_suffix("0").trim_suffix(".").replace(".", ",")
	var prefix := "−" if value < -0.000001 else ("+" if signed and value > 0.000001 else "")
	return prefix + formatted + ((" p.p." if signed else "%") if key in PERCENTAGES else "")
