extends Resource
class_name EquipmentData

@export var id: StringName
@export var display_name: String
@export var slot: StringName = &"relic"
@export var class_id: StringName = &""
@export var rarity: StringName = &"common"
@export_multiline var description: String
@export var stat: StringName = &"damage"
@export var stat_amount: float = 0.0
@export var region_id: StringName = &""
@export var bonuses: Dictionary = {}

@export var family_id: StringName = &""
@export var tier_index := 0
@export var required_difficulty := 0
@export var generated := false
@export var visual_column := -1
@export var visual_row := -1
@export var shield_visual_column := -1
@export var shield_visual_row := -1
@export var weapon_kind: StringName = &""
@export var accessory_visual := -1

## Comparable item budget, including base attributes and special effects.
## This is an ordering aid, not a DPS estimate for every build.
const POWER_WEIGHTS := {"health": 0.25, "damage": 3.0, "defense": 4.0, "damage_pct": 240.0, "health_pct": 160.0, "speed_pct": 160.0, "attack_speed_pct": 220.0, "crit_chance": 280.0, "crit_multiplier": 60.0, "lifesteal": 600.0, "regen": 20.0, "thorns": 80.0, "pickup_radius": 0.15, "splash_radius": 0.6, "projectile_bounces": 25.0, "projectile_pierce": 20.0, "cleave_targets": 18.0, "summon_duration": 6.0, "summon_damage_pct": 140.0, "burn_on_hit": 100.0, "chill_on_hit": 90.0}

func power_score() -> float:
	var score := maxf(0.0, stat_amount) * float(POWER_WEIGHTS.get(str(stat), 1.0))
	for key in bonuses:
		score += maxf(0.0, float(bonuses[key])) * float(POWER_WEIGHTS.get(str(key), 1.0))
	return score
