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

func visual_id() -> String:
	return str(icon_id) if icon_id != &"" else str(id)

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
			var name: String = {"cleave_targets": "alvos", "projectile_pierce": "perfurações", "summon_count": "lobos", "pickup_radius": "coleta"}[key]
			totals.append("+%d %s" % [roundi(float(bonuses[key]) * rank), name])
		elif key == "summon_duration":
			totals.append("+%s s de invocação" % ("%.1f" % (float(bonuses[key]) * rank)).trim_suffix(".0"))
	if not totals.is_empty():
		return description + "\nTotal no nível %d: %s." % [rank, ", ".join(totals)]
	var effect := ""
	match str(id):
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
		"shadow_burst": effect = "%d alvos; %d%% do dano por alvo." % [2 + rank, 100 + rank * 25]
		"ancient_guardian": effect = "%d guardiões por %d s; %d%% do dano por golpe." % [1 + floori(float(rank - 1) / 2.0), 12 + rank * 2, 65 + rank * 10]
	return description + ("\nNível %d: %s" % [rank, effect] if not effect.is_empty() else "")
