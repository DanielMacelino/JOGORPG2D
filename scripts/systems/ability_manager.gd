extends Node
class_name AbilityManager

signal loadout_changed

const MAX_ACTIVE_POWERS := 3
var innate_ability := &""
var levels: Dictionary = {}
var max_level := 5
var class_id := "warrior"
var expedition_level := 1
var difficulty_tier := 0
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()

func reset(starting_ability: StringName = &"", owner: String = "warrior", tier: int = 0) -> void:
	innate_ability = starting_ability
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

func active_power_count() -> int:
	var count := 0
	for id in levels:
		var ability: AbilityData = ContentCatalog.abilities.get(str(id))
		if ability != null and ability.active_power and ability.id != innate_ability and level_of(ability.id) > 0:
			count += 1
	return count

func can_learn(ability: AbilityData) -> bool:
	if not ability.school_id.is_empty():
		for id in levels:
			var learned: AbilityData = ContentCatalog.abilities.get(str(id))
			if learned != null and learned.school_id == ability.school_id and learned.id != ability.id: return false
	return not ability.active_power or ability.id == innate_ability or level_of(ability.id) > 0 or active_power_count() < MAX_ACTIVE_POWERS

func chooseable() -> Array[StringName]:
	var candidates: Array[StringName] = []
	for id in ContentCatalog.abilities:
		var ability: AbilityData = ContentCatalog.abilities[str(id)]
		if (ability.unlock_only and ability.id != innate_ability) or not ability.available_to(class_id) or ability.required_run_level > expedition_level or ability.required_difficulty > difficulty_tier:
			continue
		if level_of(ability.id) < max_level and can_learn(ability):
			candidates.append(ability.id)
	return candidates

func grant(id: StringName) -> bool:
	var ability: AbilityData = ContentCatalog.abilities.get(str(id))
	if ability == null or (ability.unlock_only and ability.id != innate_ability) or not ability.available_to(class_id) or level_of(id) >= max_level or ability.required_run_level > expedition_level or ability.required_difficulty > difficulty_tier:
		return false
	if not can_learn(ability):
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
	# The expanded catalog must not drown out the character's original identity.
	return base * (1.6 if level_of(id) > 0 else 1.0) * (1.0 if ability.school_id.is_empty() else 0.45)

func roll_choices(count: int = 3) -> Array[AbilityData]:
	var pool := chooseable()
	var result: Array[AbilityData] = []	
	while not pool.is_empty() and result.size() < count:
		# Keep a power card available while building or upgrading the chosen trio.
		var selection: Array[StringName] = []
		if result.is_empty():
			for id in pool:
				if ContentCatalog.abilities[str(id)].active_power:
					selection.append(id)
		elif result.size() == 1:
			for id in pool:
				var ability: AbilityData = ContentCatalog.abilities[str(id)]
				if not ability.active_power and not ability.class_ids.is_empty(): selection.append(id)
		else:
			for id in pool:
				var ability: AbilityData = ContentCatalog.abilities[str(id)]
				if ability.class_ids.is_empty() or level_of(id) > 0: selection.append(id)
		if selection.is_empty():
			selection.assign(pool)
		var total := 0.0
		for id in selection:
			total += _get_weight(id)
		var roll := rng.randf() * total
		var selected: StringName = selection[0]
		for id in selection:
			roll -= _get_weight(id)
			if roll <= 0.0:
				selected = id
				break
		result.append(ContentCatalog.abilities[str(selected)])
		pool.erase(selected)
		var school: String = ContentCatalog.abilities[str(selected)].school_id
		if not school.is_empty():
			for id in pool.duplicate():
				if ContentCatalog.abilities[str(id)].school_id == school: pool.erase(id)
	return result
