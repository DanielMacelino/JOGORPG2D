extends Resource
class_name AbilityData

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var rarity: StringName = &"common"
@export var damage_multiplier: float = 1.0
@export var cooldown_multiplier: float = 1.0
@export var radius: float = 0.0
@export var stat: StringName = &""
@export var stat_amount: float = 0.0
@export var unlock_only: bool = false
## A separate attack, aura, spell or summon; stat modifiers do not occupy a power slot.
@export var active_power := false
## Empty class list means this ability is shared by every class.
@export var class_ids: Array[StringName] = []
@export var bonuses: Dictionary = {}
@export var icon_id: StringName = &""
@export var required_run_level := 1
@export var required_difficulty := 0
@export var school_id := ""

func combat_label() -> String:
	if id in [&"wild_growth", &"nature_pack", &"living_grove", &"ancient_guardian"]: return "INVOCAÇÃO"
	if active_power:
		if id in [&"challenge_shout", &"frost_nova", &"time_warp", &"roots_snare", &"binding_shot"]: return "CONTROLE"
		if id in [&"volley", &"dagger_fan", &"shadow_burst"]: return "ATAQUE"
		return "ÁREA"
	if bonuses.has("summon_damage_pct") or bonuses.has("summon_count") or bonuses.has("summon_speed_pct") or bonuses.has("summon_duration"): return "INVOCAÇÃO"
	if bonuses.has("health_pct") or bonuses.has("defense") or bonuses.has("thorns") or bonuses.has("regen"): return "DEFESA"
	if bonuses.has("damage_pct") or bonuses.has("attack_speed_pct") or bonuses.has("crit_chance") or bonuses.has("projectile_pierce"): return "ATAQUE"
	if bonuses.has("speed_pct") or bonuses.has("range_pct"): return "MOVIMENTO"
	return "SUPORTE"

func visual_id() -> String:
	return str(icon_id) if icon_id != &"" else str(id)

func hud_total(rank: int) -> String:
	var fixed := ["defense", "regen", "cleave_targets", "splash_radius", "projectile_pierce", "pickup_radius", "summon_count", "summon_duration"]
	for key in bonuses:
		if key not in fixed:
			return "+" + ("%.1f" % (float(bonuses[key]) * rank * 100)).trim_suffix(".0").replace(".", ",") + "%"
	if not bonuses.is_empty():
		var key: String = str(bonuses.keys()[0])
		return "+" + ("%.1f" % (float(bonuses[key]) * rank)).trim_suffix(".0").replace(".", ",") + ("s" if key == "summon_duration" else ("/s" if key == "regen" else ""))
	var percent := 0
	match str(id):
		"nature_pack": percent = 145 + rank * 12
		"living_grove": percent = 125 + rank * 20
		"arcane_bloom": percent = 100 + rank * 30
		"thorn_aura": percent = 30 + rank * 13
		"berserker": return "até +%d%%" % (rank * 25)
		"ember_orb": percent = 115 + rank * 28
		"frost_nova": percent = 70
		"echo_strike": percent = rank * 20
		"storm_arc": percent = 90 + rank * 30
		"blade_storm": percent = 80 + rank * 20
		"time_warp": percent = rank * 10
		"starfall": percent = 180 + rank * 45
		"phoenix_flame": percent = 40 + (rank - 1) * 12
		"void_rift": percent = 200 + rank * 45
		"glacial_ring", "roots_snare", "sunfire": percent = 90 + rank * 28
		"volley": percent = 65 + rank * 12
		"dagger_fan": percent = 50 + rank * 14
		"binding_shot": percent = 90 + rank * 18
		"arrow_rain": percent = 70 + rank * 20
		"shadow_burst": percent = 100 + rank * 25
		"ancient_guardian": percent = 140 + rank * 22
		_:
			if stat == &"heal": percent = roundi(stat_amount * 100)
	return "%d%%" % percent if percent > 0 else "N%d" % rank

func available_to(class_id: String) -> bool:
	return class_ids.is_empty() or class_ids.has(StringName(class_id))

func rank_description(rank: int) -> String:
	var totals: PackedStringArray = []
	var names := {"health_pct": "vida", "damage_pct": "dano", "attack_speed_pct": "velocidade de ataque", "speed_pct": "movimento", "range_pct": "alcance", "crit_chance": "chance de crítico", "bonus_gold_xp": "ouro e XP", "lifesteal": "roubo de vida", "summon_damage_pct": "dano das invocações", "summon_speed_pct": "ataque das invocações"}
	for key in bonuses:
		if names.has(key):
			totals.append("+%s%% %s" % [("%.1f" % (float(bonuses[key]) * rank * 100.0)).trim_suffix(".0"), names[key]])
		elif key == "defense":
			totals.append("+%s defesa" % ("%.1f" % (float(bonuses[key]) * rank)).trim_suffix(".0"))
		elif key == "regen":
			totals.append("+%.1f vida/s" % (float(bonuses[key]) * rank))
		elif key == "splash_radius":
			totals.append("+%d área" % roundi(float(bonuses[key]) * rank))
		elif key == "thorns":
			totals.append("%d%% retaliação" % roundi(float(bonuses[key]) * rank * 100.0))
		elif key in ["cleave_targets", "projectile_pierce", "summon_count", "pickup_radius"]:
			var name: String = {"cleave_targets": "alvos", "projectile_pierce": "perfurações", "summon_count": "brotos", "pickup_radius": "coleta"}[key]
			totals.append("+%d %s" % [roundi(float(bonuses[key]) * rank), name])
		elif key == "summon_duration":
			totals.append("+%s s de invocação" % ("%.1f" % (float(bonuses[key]) * rank)).trim_suffix(".0"))
	if not totals.is_empty():
		return description + "\nTotal no nível %d: %s." % [rank, ", ".join(totals)]
	var effect := ""
	match str(id):
		"nature_pack": effect = "%d lobos por %d s; %d%% do dano por mordida." % [1 + floori(float(rank) / 2.0), 12 + rank * 2, 145 + rank * 12]
		"living_grove": effect = "%d árvores por %d s; %d%% do dano e raízes por ataque." % [1 + floori(float(rank - 1) / 2.0), 11 + rank * 2, 125 + rank * 20]
		"arcane_bloom": effect = "%d%% de dano · raio %d · recarga %.1f s." % [100 + rank * 30, 130 + rank * 16, 8.0 - rank * 0.5]
		"thorn_aura": effect = "%d%% do dano por pulso; raio %d." % [30 + rank * 13, 102 + rank * 7]
		"berserker": effect = "Até +%d%% de dano com pouca vida." % (rank * 25)
		"ember_orb": effect = "%d%% do dano; explosão de raio %d." % [115 + rank * 28, 65 + rank * 8]
		"frost_nova": effect = "Lentidão de 70%% por %.2f s; raio %d." % [1.4 + rank * 0.15, 145 + rank * 9]
		"echo_strike": effect = "%d%% de chance de dano dobrado." % (rank * 20)
		"storm_arc": effect = "%d alvos; %d%% do dano por alvo." % [2 + rank, 90 + rank * 30]
		"blade_storm": effect = "%d%% do dano; raio %d." % [80 + rank * 20, 150 + rank * 8]
		"time_warp": effect = "%d%% de lentidão a cada %d s." % [rank * 10, 12 - rank]
		"starfall": effect = "%d%% do dano; raio %d." % [180 + rank * 45, 125 + rank * 12]
		"phoenix_flame": effect = "Revive com %d%% da vida, uma vez." % [40 + (rank - 1) * 12]
		"void_rift": effect = "%d%% do dano; raio %d." % [200 + rank * 45, 210 + rank * 14]
		"challenge_shout": effect = "Provocação por %.1f s; raio %d." % [2.5 + rank * 0.5, 300 + rank * 35]
		"glacial_ring", "roots_snare", "sunfire": effect = "%d%% do dano; raio %d." % [90 + rank * 28, 115 + rank * 15]
		"volley": effect = "%d flechas; %d%% do dano por flecha." % [3 + rank, 65 + rank * 12]
		"dagger_fan": effect = "%d adagas; %d%% do dano por adaga; recarga %.1f s." % [3 + rank, 50 + rank * 14, 7.0 - rank * 0.4]
		"binding_shot": effect = "%d%% do dano; lentidão %d%% por 2 s; recarga %.1f s." % [90 + rank * 18, 35 + rank * 4, 7.5 - rank * 0.4]
		"arrow_rain": effect = "%d%% do dano; raio %d; recarga %.1f s." % [70 + rank * 20, 110 + rank * 12, 9.0 - rank * 0.4]
		"shadow_burst": effect = "%d alvos; %d%% do dano por alvo." % [2 + rank, 100 + rank * 25]
		"ancient_guardian": effect = "%d guardiões por %d s; %d%% do dano por golpe." % [1 + floori(float(rank - 1) / 2.0), 12 + rank * 2, 140 + rank * 22]
	return description + ("\nNível %d: %s" % [rank, effect] if not effect.is_empty() else "")
