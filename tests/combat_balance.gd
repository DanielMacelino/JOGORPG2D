extends SceneTree
## Checks that standing still or merely circling cannot guarantee a clear after a few choices.
## Uses actual offered skills and no invulnerability, in isolated storage.
var results: Array[Dictionary] = []

func _initialize() -> void:
	call_deferred("_run")

func _cards(node: Node, result: Array[Node]) -> void:
	if node.get_script() == load("res://scripts/ui/level_choice_card.gd"):
		result.append(node)
	for child in node.get_children():
		_cards(child, result)

func _choose(game: Node) -> void:
	var cards: Array[Node] = []
	_cards(game.level_layer, cards)
	var best := -INF
	var chosen: StringName = &""
	var weights := {"ember_orb": 10.0, "thorn_aura": 9.0, "storm_arc": 8.0, "keen_edge": 8.0, "rapid_hands": 7.0, "starfall": 8.0, "lifesteal": 5.0, "vital_bloom": 4.0, "iron_skin": 3.0, "second_wind": 2.0}
	weights.merge({"wolf_pack": 9.0, "living_bark": 8.0, "ancient_guardian": 10.0, "roots_snare": 8.0, "glacial_ring": 9.0, "arcane_expansion": 8.0, "arcane_haste": 8.0, "volley": 10.0, "wind_string": 8.0, "fletching": 7.0, "steady_aim": 8.0, "razor_dance": 9.0, "deadly_rhythm": 8.0, "night_hunger": 8.0, "shadow_burst": 10.0, "oath_edge": 9.0, "sunfire": 10.0, "solar_armor": 6.0, "restoring_light": 5.0})
	if game.player.health / game.player.max_health < 0.40:
		weights.merge({"second_wind": 20.0, "vital_bloom": 14.0, "iron_skin": 9.0}, true)
	for card in cards:
		var id: StringName = card.ability.id
		var score: float = float(weights.get(str(id), 1.0)) - game.abilities.level_of(id) * 0.6
		if score > best:
			best = score
			chosen = id
	game._choose_ability(chosen)

func _run() -> void:
	assert(str(ProjectSettings.get_setting("application/config/name")).begins_with("Ashenwild Regression"))
	var save: Node = root.get_node("SaveManager")
	var talents: Node = root.get_node("TalentManager")
	var class_ids := PackedStringArray(["warrior", "mage", "ranger", "assassin", "druid", "paladin"])
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--classes="):
			class_ids = argument.trim_prefix("--classes=").split(",", false)
	assert(not class_ids.is_empty())
	for class_id in class_ids:
		assert(root.get_node("ContentCatalog").classes.has(class_id))
		for moving in [false, true]:
			seed(73421)
			save.data = save.DEFAULT_SAVE.duplicate(true)
			save._initialize_progression(false)
			if not save.is_class_unlocked(class_id):
				save.data.gold = 10000
				assert(save.unlock_class(class_id))
			talents.set_class(class_id)
			var game = load("res://scenes/game.tscn").instantiate()
			game.player_class = class_id
			root.add_child(game)
			game.wave_director.rng.seed = 431
			game.enemy_manager.rng.seed = 827
			game.abilities.rng.seed = 971
			var pressure := {"late_damage": 0.0}
			game.player.damaged.connect(func(amount: float) -> void:
				if game.experience.level >= 4: pressure.late_damage += amount)
			while not game.run_finished and game.wave_director.match_time < game.map_data.duration + 450.0:
				if paused and game.level_layer != null:
					_choose(game)
				if moving:
					var t: float = game.wave_director.match_time
					var destination := Vector2(cos(t * 0.43) * 420.0, sin(t * 0.43) * 300.0)
					var direction: Vector2 = (destination - game.player.position).normalized()
					if is_instance_valid(game.boss) and not game.boss.dead:
						var toward: Vector2 = game.boss.position - game.player.position
						var distance := toward.length()
						var desired: float = maxf(85.0, game.player.attack_range * 0.65)
						direction = toward.normalized() if distance > desired + 20.0 else (toward.normalized().orthogonal() + toward.normalized() * (distance - desired) / 25.0).normalized()
					var escape := Vector2.ZERO
					# Ranged classes keep space; the bot also dodges visible projectiles.
					var clearance := 120.0 if game.player.class_data.attack_style != &"melee" else 48.0
					for enemy in game.enemy_manager.nearby(game.player.position, clearance):
						var away: Vector2 = game.player.position - enemy.position
						if away.length() < clearance:
							escape += away.normalized() * (clearance - away.length())
					for shot in get_nodes_in_group("hostile_projectile"):
						var forward: float = (game.player.position - shot.position).dot(shot.direction)
						if forward < 0.0 or forward > shot.speed * 0.4:
							continue
						var closest: Vector2 = shot.position + shot.direction * forward
						var away: Vector2 = game.player.position - closest
						if away.length() < 42.0:
							escape += (away.normalized() if away.length() > 2.0 else shot.direction.orthogonal()) * (42.0 - away.length()) * 2.0
					for area in get_nodes_in_group("danger_area"):
						var away: Vector2 = game.player.position - area.position
						if area.has_method("contains_point"):
							if area.shape == "fan":
								var axis: Vector2 = area.spec.get("direction", Vector2.RIGHT)
								var spread: float = float(area.spec.get("spread", 1.0))
								if not area.fired and absf(axis.angle_to(away)) < spread * 0.5 + 0.12:
									escape += axis.orthogonal() * (1.0 if axis.cross(away) >= 0 else -1.0) * 160.0
								continue
							if area.shape == "line":
								var end: Vector2 = area.spec.get("end", area.position)
								var line: Vector2 = end - area.position
								var fraction := clampf((game.player.position - area.position).dot(line) / maxf(line.length_squared(), 0.001), 0, 1)
								away = game.player.position - (area.position + line * fraction)
							elif area.shape == "ring":
								var inner := float(area.spec.get("inner", 0.0))
								if away.length() < inner - 22 or away.length() > area.radius + 22:
									continue
								if away.length() < (inner + area.radius) * 0.5:
									escape -= away.normalized() * 80
									continue
						if away.length() < area.radius + 22.0:
							escape += (away.normalized() if away.length() > 2.0 else direction) * (area.radius + 22.0 - away.length())
					if not escape.is_zero_approx():
						direction = (direction * 0.25 + escape.normalized()).normalized()
					# Dodging a monster must still avoid walking into a tree.
					if game.player.get_slide_collision_count() > 0:
						var normal: Vector2 = game.player.get_slide_collision(0).get_normal()
						var glide := direction.slide(normal)
						if glide.length_squared() < 0.04:
							glide = normal.orthogonal() * (1.0 if normal.orthogonal().dot(destination - game.player.position) >= 0 else -1.0)
						direction = (glide + normal * 0.35).normalized()
					game.player.set_virtual_direction(direction)
				else:
					game.player.set_virtual_direction(Vector2.ZERO)
				await process_frame
			var sample := {"class": class_id, "moving": moving, "time": snappedf(game.wave_director.match_time, 0.1), "victory": game.run_finished and not game.player.is_dead, "dead": game.player.is_dead, "health_pct": roundi(game.player.health / game.player.max_health * 100.0), "kills": game.enemies_defeated, "run_level": game.experience.level, "late_damage": roundi(float(pressure.late_damage))}
			results.append(sample)
			print(JSON.stringify(sample))
			paused = false
			game.queue_free()
			await process_frame
			await process_frame
	root.get_node("AudioManager").stop_all()
	# Fixed FPS accelerates simulation; the audio thread still uses wall-clock time.
	var audio_drain_until := Time.get_ticks_msec() + 250
	while Time.get_ticks_msec() < audio_drain_until:
		await process_frame
	var idle_defeats := 0
	var moving_victories := 0
	for sample in results:
		idle_defeats += int(not bool(sample.moving) and bool(sample.dead))
		moving_victories += int(bool(sample.moving) and bool(sample.victory))
	assert(idle_defeats == class_ids.size(), "Standing still must remain dangerous after the first skill choices")
	for index in class_ids.size():
		var idle: Dictionary = results[index * 2]
		var moving: Dictionary = results[index * 2 + 1]
		assert(bool(moving.victory) or float(moving.time) > float(idle.time) * 1.4, "Movement must materially improve survival")
		assert(bool(moving.dead) or int(moving.late_damage) > 0, "Circling must not make a character immune after three level-ups")
	print("PRESSURE: ", idle_defeats, " idle defeats; ", moving_victories, " clears from simple circling (a clear is no longer guaranteed)")
	print("BALANCE COMPLETE: ", results.size(), " real combat samples")
	quit()
