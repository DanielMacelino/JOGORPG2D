extends Node
class_name AbilityManager

signal loadout_changed

var levels: Dictionary = {}
var max_level := 5
var class_id := "warrior"
var expedition_level := 1
var difficulty_tier := 0
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()

func reset(starting_ability: StringName = &"", owner: String = "warrior", tier: int = 0) -> void:
	class_id = owner
	expedition_level = 1
	difficulty_tier = tier
	levels.clear()
	var starting: AbilityData = ContentCatalog.abilities.get(str(starting_ability))
	if starting != null and starting.available_to(class_id):
		levels[starting_ability] = 1
	loadout_changed.emit()

func has_ability(id: StringName) -> bool:
	return level_of(id) > 0

func level_of(id: StringName) -> int:
	return maxi(int(levels.get(id, 0)), int(levels.get(str(id), 0)))

func chooseable() -> Array[StringName]:
	var candidates: Array[StringName] = []
	for id in ContentCatalog.abilities:
		var ability: AbilityData = ContentCatalog.abilities[str(id)]
		if ability.unlock_only or not ability.available_to(class_id) or ability.required_run_level > expedition_level or ability.required_difficulty > difficulty_tier:
			continue
		if level_of(ability.id) < max_level:
			candidates.append(ability.id)
	return candidates

func grant(id: StringName) -> bool:
	var ability: AbilityData = ContentCatalog.abilities.get(str(id))
	if ability == null or ability.unlock_only or not ability.available_to(class_id) or level_of(id) >= max_level or ability.required_run_level > expedition_level or ability.required_difficulty > difficulty_tier:
		return false
	var next_rank := level_of(id) + 1
	for key in levels.keys():
		if str(key) == str(id): levels.erase(key)
	levels[id] = next_rank
	loadout_changed.emit()
	return true

func accumulated_bonuses() -> Dictionary:
	var result := {}
	for id in levels:
		var ability: AbilityData = ContentCatalog.abilities.get(str(id))
		if ability == null:
			continue
		for stat in ability.bonuses:
			result[stat] = float(result.get(stat, 0.0)) + float(ability.bonuses[stat]) * level_of(id)
	return result

func _get_weight(id: StringName) -> float:
	var ability: AbilityData = ContentCatalog.abilities[str(id)]
	var base := 1.0
	match ability.rarity:
		&"common": base = 1.0
		&"uncommon": base = 0.65
		&"rare": base = 0.34
		&"epic": base = 0.14
		&"legendary": base = 0.055
		&"demigod": base = 0.025
		&"divine": base = 0.010
	return base * (1.25 if level_of(id) > 0 else 1.0)

func roll_choices(count: int = 3) -> Array[AbilityData]:
	var pool := chooseable()
	var result: Array[AbilityData] = []	
	while not pool.is_empty() and result.size() < count:
		var total := 0.0
		for id in pool:
			total += _get_weight(id)
		var roll := rng.randf() * total
		var selected: StringName = pool[0]
		for id in pool:
			roll -= _get_weight(id)
			if roll <= 0.0:
				selected = id
				break
		result.append(ContentCatalog.abilities[str(selected)])
		pool.erase(selected)
	return result
