extends Node2D
const PLAYER := preload("res://scripts/world/player.gd")
const ENEMY := preload("res://scripts/world/enemy.gd")
const PROJECTILE := preload("res://scripts/world/projectile.gd")
const PATTERN := preload("res://scripts/world/boss_pattern.gd")
const AREA := preload("res://scripts/world/telegraph.gd")
const MARKER := preload("res://scripts/world/phase_marker.gd")
const COMPANION := preload("res://scripts/world/forest_companion.gd")
const XP := preload("res://scripts/world/xp_orb.gd")
const GOLD_DROP := preload("res://scripts/world/gold_orb.gd")
const BURST := preload("res://scripts/world/burst_effect.gd")
const SKILL_EFFECT := preload("res://scripts/world/skill_effect.gd")
const LIGHTNING := preload("res://scripts/world/lightning_arc.gd")
const FIELDS := {
	"P": ["health", "max_health", "move_speed", "facing", "is_dead", "revive_progress", "revive_protection", "animation_time", "moving_blend", "attack_time", "attack_duration", "attack_serial", "attack_direction", "attack_critical", "attack_animation_style", "flash", "level", "attack_special", "death_elapsed"],
	"E": ["health", "max_health", "hit_flash", "animation_time", "moving_blend", "burn_remaining", "attack_time", "attack_direction", "spawn_time"],
	"Q": ["direction", "speed", "elapsed", "magic", "color", "player_team", "trail_points"],
	"D": ["spec", "elapsed", "fired", "shape", "radius"],
	"A": ["elapsed", "fired", "radius", "duration", "lingering"],
	"M": ["kind", "health", "max_health", "progress", "complete", "radius"],
	"C": ["kind", "remaining", "full_duration", "animation_time", "moving_blend", "attack_time", "facing", "rank", "attack_reach"],
	"X": ["phase"], "G": ["phase"], "B": ["radius", "color", "elapsed", "lifetime"],
	"F": ["kind", "radius", "color", "direction", "elapsed", "lifetime"],
	"L": ["shape_points", "color", "elapsed", "lifetime"]}
var world: Node
var visuals: Dictionary = {}
var targets: Dictionary = {}
var velocities: Dictionary = {}
var sample_times: Dictionary = {}
var reconciliation := Vector2.ZERO
var maximum_correction := 0.0
var hud_clock := 0.0
var entity_frames: Dictionary = {}
var removed_frames: Dictionary = {}

static func capture_world(game: Node, include_rows: bool = true) -> Dictionary:
	var rows: Array = []
	if include_rows:
		_walk(game, rows)
	var states := {}
	for id in game.actors:
		var actor: Node = game.actors[id]
		states[id] = {"xp": actor.experience.current_xp, "required": actor.experience.required_xp, "level": actor.experience.level, "gold": actor.run_gold, "abilities": actor.abilities.levels, "kills": actor.enemies_defeated}
	return {"rows": rows, "states": states, "wave": game.wave_director.wave, "time": game.wave_director.match_time, "objective": game.phase_director.status(), "boss_name": game.boss_name_label.text, "boss_music": game.boss_music_active}

static func capture_players(game: Node) -> Dictionary:
	var rows: Array = []
	for id in game.actors:
		var actor: Node = game.actors[id]
		var row := _row(actor.player, "P", "P%d" % id)
		row.class_id = actor.player_class
		row.weapon_id = actor.player.equipped_weapon_id
		row.peer = id
		row.ack = int(NetworkSession.acknowledged_inputs.get(id, 0))
		row.echo = int(NetworkSession.acknowledged_stamps.get(id, 0))
		row.velocity = actor.player.velocity
		rows.append(row)
	return {"rows": rows}

static func _walk(node: Node, rows: Array) -> void:
	for child in node.get_children():
		var type := ""
		var script: Script = child.get_script()
		if script == ENEMY:
			if not child.dead:
				type = "E"
		elif script == PROJECTILE: type = "Q"
		elif script == PATTERN: type = "D"
		elif script == AREA: type = "A"
		elif script == MARKER: type = "M"
		elif script == COMPANION: type = "C"
		elif script == XP: type = "X"
		elif script == GOLD_DROP: type = "G"
		elif script == BURST: type = "B"
		elif script == LIGHTNING: type = "L"
		elif script == SKILL_EFFECT: type = "F"
		if not type.is_empty():
			var row := _row(child, type, str(child.get_instance_id()))
			if type == "E":
				row.kind = str(child.kind)
				row.marked = child.has_meta("objective_elite")
			rows.append(row)
		if child is ExpeditionGame:
			_walk(child, rows)

static func _row(node: Node2D, type: String, id: String) -> Dictionary:
	var values := {}
	for field in FIELDS[type]:
		if field == "spec":
			var spec: Dictionary = node.get(field).duplicate()
			spec.erase("target")
			values[field] = spec
		else:
			values[field] = node.get(field)
	var row := {"id": id, "type": type, "p": node.global_position, "v": values}
	if type == "E":
		row.velocity = node.velocity
	elif type == "Q":
		row.velocity = node.direction * node.speed
	elif type == "C":
		row.velocity = node.facing * (335.0 if node.kind == "wolf" else 255.0) * node.moving_blend
	return row

func apply(packet: Dictionary) -> void:
	for row in packet.rows:
		_apply_row(row)
	var local_id := multiplayer.get_unique_id()
	if packet.states.has(local_id):
		var state: Dictionary = packet.states[local_id]
		world.experience.current_xp = int(state.xp)
		world.experience.required_xp = int(state.required)
		world.experience.level = int(state.level)
		world.abilities.levels = state.abilities
		world.run_gold = int(state.gold)
		world.enemies_defeated = int(state.kills)
	world.wave_director.wave = int(packet.wave)
	world.wave_director.match_time = float(packet.time)
	world.objective_label.text = str(packet.objective)
	world.phase_director.text = str(packet.objective)
	world.boss_name_label.text = str(packet.boss_name)
	world.boss = null
	for node in visuals.values():
		if node is ChaserEnemy and node.data.boss:
			world.boss = node
			break
	world._set_boss_music(bool(packet.get("boss_music", false)))
	world._refresh_skill_list()
	var team: Array[Dictionary] = []
	for id in NetworkSession.players:
		var key := "P%d" % id
		if visuals.has(key):
			var unit: SurvivorPlayer = visuals[key]
			team.append({"name": NetworkSession.players[id].name, "class_id": str(unit.class_data.id), "health": unit.health, "maximum": unit.max_health, "dead": unit.is_dead, "revive": unit.revive_progress})
	world.team_label.update_members(team)

func apply_slice(packet: Dictionary, sequence: int) -> void:
	for row in packet.rows:
		var key := str(row.id)
		if sequence <= int(entity_frames.get(key, -1)) or sequence <= int(removed_frames.get(key, -1)):
			continue
		entity_frames[key] = sequence
		_apply_row(row)

func remove_entities(ids: Array, sequence: int) -> void:
	for id in ids:
		var key := str(id)
		removed_frames[key] = maxi(sequence, int(removed_frames.get(key, -1)))
		entity_frames.erase(key)
		if visuals.has(key):
			visuals[key].queue_free()
			visuals.erase(key)
			targets.erase(key)
			velocities.erase(key)
			sample_times.erase(key)
	# Keep late packets from resurrecting dead enemies without growing this ledger forever.
	for key in removed_frames.keys():
		if int(removed_frames[key]) < sequence - 100:
			removed_frames.erase(key)

func apply_players(packet: Dictionary) -> void:
	var present := {}
	for row in packet.rows:
		present[str(row.id)] = true
		_apply_row(row)
	for key in visuals.keys():
		if key.begins_with("P") and not present.has(key) and visuals[key] != world.player:
			visuals[key].queue_free()
			visuals.erase(key)
			targets.erase(key)
			velocities.erase(key)
			sample_times.erase(key)

func _apply_row(row: Dictionary) -> void:
	var key := str(row.id)
	var fresh := not visuals.has(key)
	if fresh:
		visuals[key] = _create(row)
	var node: Node2D = visuals[key]
	if row.type == "P": node.set("equipped_weapon_id", str(row.get("weapon_id", "")))
	for field in row.v:
		if node == world.player and field in ["animation_time", "moving_blend", "facing"] and not bool(row.v.get("is_dead", false)):
			continue
		node.set(field, row.v[field])
	if row.type == "E" and bool(row.get("marked", false)):
		node.set_meta("objective_elite", true)
	if fresh:
		node.global_position = row.p
	elif node == world.player:
		_reconcile(row)
	targets[key] = row.p
	velocities[key] = row.get("velocity", Vector2.ZERO)
	sample_times[key] = Time.get_ticks_msec()
	node.queue_redraw()
	if row.type == "P":
		var label: Label = node.find_child("PeerLabel", false, false)
		label.text = "%s · %s" % [NetworkSession.players.get(row.peer, {}).get("name", "Viajante"), node.downed_status() if node.is_dead else str(roundi(node.health))]

func _reconcile(row: Dictionary) -> void:
	var echo := int(row.get("echo", 0))
	if echo > 0:
		var sample := float(Time.get_ticks_msec() - echo)
		if sample >= 0.0 and sample < 3000.0:
			NetworkSession.rtt_ms = sample if NetworkSession.rtt_ms == 0.0 else lerpf(NetworkSession.rtt_ms, sample, 0.1)
	while not NetworkSession.pending_inputs.is_empty() and int(NetworkSession.pending_inputs[0].seq) <= int(row.ack):
		NetworkSession.pending_inputs.pop_front()
	var before: Vector2 = world.player.global_position
	world.player.global_position = row.p
	if not world.player.is_dead and not world.collective_paused:
		for command in NetworkSession.pending_inputs:
			world.player.simulate_network_step(command.direction, NetworkSession.INPUT_STEP)
	var desired: Vector2 = world.player.global_position
	var error := before.distance_to(desired)
	maximum_correction = maxf(maximum_correction, error)
	if error > 90.0 or world.player.is_dead or world.collective_paused:
		reconciliation = Vector2.ZERO
	else:
		world.player.global_position = before
		reconciliation = desired - before if error > 0.10 else Vector2.ZERO

func _create(row: Dictionary) -> Node2D:
	var node: Node2D
	match str(row.type):
		"P":
			if int(row.peer) == multiplayer.get_unique_id():
				node = world.player
			else:
				node = PLAYER.new()
				node.configure(str(row.class_id), {})
			node.z_index = 5
		"E":
			node = preload("res://scenes/enemies/pixel_enemy.tscn").instantiate() if preload("res://scripts/data/pixel_enemy_sprites.gd").has_kind(StringName(row.kind)) else ENEMY.new()
			node.configure(ContentCatalog.enemies[str(row.kind)], world.player, 1)
			node.z_index = 4 if node.data.boss else 2
		"Q": node = PROJECTILE.new()
		"D": node = PATTERN.new()
		"A": node = AREA.new()
		"M": node = MARKER.new()
		"C": node = COMPANION.new()
		"X": node = XP.new()
		"G": node = GOLD_DROP.new()
		"B": node = BURST.new()
		"L": node = LIGHTNING.new()
		"F": node = SKILL_EFFECT.new()
	for field in row.v:
		node.set(field, row.v[field])
	if node == world.player:
		node.set_process(false)
		node.set_physics_process(false)
	else:
		node.process_mode = Node.PROCESS_MODE_DISABLED
		add_child(node)
	if row.type == "P":
		var label := Label.new()
		label.name = "PeerLabel"
		label.position = Vector2(-75, -70)
		label.size = Vector2(150, 20)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 11)
		label.add_theme_color_override("font_color", Color("#baffdd"))
		label.add_theme_color_override("font_shadow_color", Color.BLACK)
		label.add_theme_constant_override("shadow_offset_x", 1)
		label.add_theme_constant_override("shadow_offset_y", 1)
		node.add_child(label)
	return node

func _process(delta: float) -> void:
	hud_clock -= delta
	if hud_clock <= 0.0:
		hud_clock = 0.1
		world._update_hud()
		world._update_boss_hud()
	for key in visuals:
		var node: Node2D = visuals[key]
		if not world.collective_paused and not world.run_finished:
			if node is SurvivorPlayer:
				node.attack_time = maxf(0.0, node.attack_time - delta)
				node.flash = maxf(0.0, node.flash - delta)
				if node.is_dead: node.death_elapsed += delta
				if node != world.player:
					node.animation_time += delta
			elif node is ChaserEnemy:
				node.animation_time += delta
				node.attack_time = maxf(0.0, node.attack_time - delta)
				node.spawn_time += delta
			elif node.get_script() in [SKILL_EFFECT, BURST, LIGHTNING]:
				node.elapsed = minf(node.lifetime, node.elapsed + delta)
			elif node.get_script() == COMPANION:
				node.animation_time += delta
				node.attack_time = maxf(0.0, node.attack_time - delta)
			node.queue_redraw()
		if node == world.player: continue
		var age := clampf(float(Time.get_ticks_msec() - int(sample_times.get(key, 0))) / 1000.0, 0.0, 0.10)
		var velocity: Vector2 = velocities.get(key, Vector2.ZERO)
		var target: Vector2 = targets[key] + velocity * age
		if world.collective_paused or world.run_finished:
			target = targets[key]
		if node.global_position.distance_to(target) > 180.0:
			node.global_position = target
		else:
			node.global_position = node.global_position.lerp(target, 1.0 - exp(-30.0 * delta))
	if world.player.is_dead:
		for node in visuals.values():
			if node is SurvivorPlayer and not node.is_dead:
				world.camera.global_position = node.global_position
				break

	else:
		world.camera.position = Vector2.ZERO

func _physics_process(delta: float) -> void:
	if not world.started or world.run_finished or world.collective_paused: return
	var direction := NetworkSession.local_direction()
	NetworkSession.send_input(direction, delta)
	if world.player.is_dead: return
	var adjustment := reconciliation * (1.0 - exp(-18.0 * delta))
	world.player.global_position += adjustment
	reconciliation -= adjustment
	world.player.simulate_network_step(direction, NetworkSession.INPUT_STEP)
	world.player.animation_time += delta
	world.player.moving_blend = move_toward(world.player.moving_blend, 1 if not direction.is_zero_approx() else 0, delta * 7)
	if not direction.is_zero_approx(): world.player.facing = direction
	world.player.queue_redraw()
