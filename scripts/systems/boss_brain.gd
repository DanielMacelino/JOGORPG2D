extends Node
signal attack_requested(spec: Dictionary)
signal enraged
var actor: ChaserEnemy
var clock := 4.0
var attack_index := 0
var second_phase := false
var sovereign := false
var final_phase := false

func _process(delta: float) -> void:
	if actor == null or actor.dead or not is_instance_valid(actor.player) or actor.player.is_dead:
		return
	if not second_phase and actor.health <= actor.max_health * 0.5:
		second_phase = true
		clock = minf(clock, 0.8)
		enraged.emit()
	if sovereign and not final_phase and actor.health <= actor.max_health * 0.25:
		final_phase = true
		clock = minf(clock, 1.0)
		enraged.emit()
	clock -= delta
	if clock > 0.0:
		return
	clock = (2.5 if final_phase else (3.2 if second_phase else 4.2)) if sovereign else (3.6 if second_phase else 5.2)
	actor.play_attack((actor.player.global_position - actor.global_position).normalized())
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
		"minotaur":
			if alternate:
				result.append(_ring(origin, 200 if second_phase else 165, 70, amount))
			else:
				var axe := _spec("line", origin, 36, amount * 1.25)
				axe["end"] = target + direction * 145
				result.append(axe)
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
	if sovereign:
		result.append_array(_sovereign_patterns(origin, target, direction, amount))
	return result

func _sovereign_patterns(origin: Vector2, target: Vector2, direction: Vector2, amount: float) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var axis := direction.orthogonal()
	match str(actor.kind):
		"minotaur":
			for side in [-1.0, 1.0]:
				var cleave := _spec("line", origin + axis * side * 75, 27, amount)
				cleave["end"] = target + direction * 180 + axis * side * 75
				result.append(cleave)
		"goblin_king":
			# A pincer charge leaves the space between the two lines safe.
			for side in [-1.0, 1.0]:
				var line := _spec("line", target + axis * side * 95.0 - direction * 220.0, 24, amount)
				line["end"] = target + axis * side * 95.0 + direction * 220.0
				result.append(line)
		"death_lord":
			result.append(_ring(target, 235, 115, amount))
			result.append(_fan(origin, direction.rotated(0.35 if attack_index % 2 == 0 else -0.35), 5, 0.7, amount, Color("#c4ffe9")))
		"lava_lord":
			for side in [-1.0, 1.0]:
				var fissure := _spec("line", target + axis * side * 130.0 - direction * 180.0, 28, amount * 0.75)
				fissure.merge({"end": target + axis * side * 130.0 + direction * 180.0, "lingering": true, "color": Color("#ff9c59")})
				result.append(fissure)
		"vampire_king":
			for angle in [-0.65, 0.65]:
				var diagonal := direction.rotated(angle)
				var cut := _spec("line", target - diagonal * 240.0, 23, amount)
				cut.merge({"end": target + diagonal * 240.0, "color": Color("#ff7f9c")})
				result.append(cut)
		"frost_guardian":
			result.append(_ring(origin, 310, 210, amount))
			for side in [-1.0, 1.0]:
				var ice := _spec("circle", target + axis * side * 130.0, 55, amount)
				ice["color"] = Color("#9cecff")
				result.append(ice)
		"mire_queen":
			for index in 4:
				var angle := float(index) * TAU / 4.0 + float(attack_index) * 0.35
				var spore := _spec("circle", target + Vector2.from_angle(angle) * 175.0, 52, amount * 0.7)
				spore.merge({"lingering": true, "color": Color("#d0ed85")})
				result.append(spore)
	if final_phase:
		result.append(_fan(origin, direction, 5, 1.5, amount * 0.85, Color("#ffdf92")))
	for spec in result:
		# Every additional attack is announced; rage never removes the dodge window.
		spec["duration"] = 1.35 if final_phase else 1.6
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
