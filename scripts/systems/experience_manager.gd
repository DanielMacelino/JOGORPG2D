extends Node
class_name ExperienceManager

signal changed(level: int, current_xp: int, required_xp: int)
signal level_up(level: int)

var level := 1
var current_xp := 0
var required_xp := 45

func requirement_for_level(current_level: int) -> int:
	if current_level == 1:
		return 45
	return roundi(45.0 + current_level * 28.0 + pow(current_level, 1.5) * 8.0)

func reset() -> void:
	level = 1
	current_xp = 0
	required_xp = requirement_for_level(1)
	changed.emit(level, current_xp, required_xp)

func add_experience(amount: int) -> void:
	current_xp += maxi(0, amount)
	var levels_gained := 0
	while current_xp >= required_xp:
		current_xp -= required_xp
		level += 1
		levels_gained += 1
		required_xp = requirement_for_level(level)
	changed.emit(level, current_xp, required_xp)
	for _index in levels_gained:
		level_up.emit(level)
