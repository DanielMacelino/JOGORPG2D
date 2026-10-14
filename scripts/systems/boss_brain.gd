extends Node
signal attack_requested(spec: Dictionary)
signal enraged
var actor: ChaserEnemy
var clock := 4.0
var attack_index := 0
var second_phase := false

func _process(delta: float) -> void:
	if actor == null or actor.dead or not is_instance_valid(actor.player) or actor.player.is_dead:
		return
	if not second_phase and actor.health <= actor.max_health * 0.5:
		second_phase = true
		clock = minf(clock, 0.8)
		enraged.emit()
	clock -= delta
	if clock > 0.0:
		return
	clock = 3.6 if second_phase else 5.2
	for spec in patterns():
		attack_requested.emit(spec)
	attack_index += 1

func patterns() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var origin := actor.global_position
	var target := actor.player.global_position
	var direction := (target - origin).normalized()
	if direction.is_zero_approx():
		direction = Vector2.RIGHT
	var alternate := attack_index % 2 == 1
	var amount := actor.damage * (1.15 if second_phase else 1.0)
	match str(actor.kind):
		"goblin_king":
			if alternate:
				for offset in [Vector2(-95, 0), Vector2(95, 0)]:
					result.append(_spec("circle", target + offset, 65, amount))
			else:
				var charge := _spec("line", origin, 25, amount * 1.2)
				charge["end"] = target + direction * 100.0
				result.append(charge)
		"death_lord":
			result.append(_fan(origin, direction, 7 if second_phase else 5, 0.95, amount, Color("#b6eadf")) if alternate else _ring(origin, 205, 90, amount))
		"lava_lord":
			if alternate:
				result.append(_ring(origin, 235, 105, amount * 1.1))
			else:
				for index in (4 if second_phase else 3):
					var eruption := _spec("circle", target + Vector2.from_angle(index * TAU / 3.0) * 105, 70, amount)
					eruption["lingering"] = true
					eruption["color"] = Color("#ffa064")
					result.append(eruption)
		"vampire_king":
			if alternate:
				result.append(_fan(origin, direction, 9 if second_phase else 5, 1.3, amount, Color("#ff9aab")))
			else:
				var slash := _spec("line", origin, 30, amount * 1.1)
				slash["end"] = target + direction * 210
				result.append(slash)
		"frost_guardian":
			if alternate:
				result.append(_fan(origin, direction, 11 if second_phase else 7, 1.8, amount, Color("#acefff")))
			else:
				for axis in [Vector2.RIGHT, Vector2.DOWN]:
					var cross := _spec("line", target - axis * 210, 24, amount)
					cross["end"] = target + axis * 210
					cross["color"] = Color("#acefff")
					result.append(cross)
		"mire_queen":
			if alternate:
				result.append(_ring(target, 160, 70, amount))
			else:
				for index in (5 if second_phase else 3):
					var spores := _spec("circle", target + Vector2.from_angle(index * TAU / (5.0 if second_phase else 3.0)) * 125, 68, amount)
					spores["lingering"] = true
					spores["color"] = Color("#cbed91")
					result.append(spores)
	return result

func _spec(shape: String, position: Vector2, radius: float, amount: float) -> Dictionary:
	return {"shape": shape, "position": position, "radius": radius, "damage": amount, "duration": 1.25, "target": actor.player, "color": Color("#ffc58b")}

func _ring(position: Vector2, outer: float, inner: float, amount: float) -> Dictionary:
	var spec := _spec("ring", position, outer, amount)
	spec["inner"] = inner
	return spec

func _fan(position: Vector2, direction: Vector2, count: int, spread: float, amount: float, color: Color) -> Dictionary:
	var spec := _spec("fan", position, 285, amount)
	spec.merge({"direction": direction, "count": count, "spread": spread, "color": color})
	return spec
