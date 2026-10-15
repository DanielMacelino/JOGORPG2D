extends SceneTree
var session: Node
var main: Node
var role := "host"
var port := 24568
var observed: Dictionary = {}
var choices_taken := 0
var original_gold := 0
var finished := false
var expected_players := 2
var local_class := "druid"
var choice_seen_at := -1
var saw_waiting_names := false
var saw_revival_progress := false
var saw_revived_host := false
var saw_any_dead_host := false
var delay_ms := 0
var jitter_ms := 0
var loss := 0.0
var stress := false
var maximum_prediction_step_ms := 0.0
var early_motion_correction := 0.0
var saw_boss_music := false
var saw_match_music := false
var saw_attack_animation := false
var max_revival_progress := 0.0
var saw_demon := false
var saw_bloom := false
var saw_rootling := false
var saw_grove := false
var new_species: Dictionary = {}
var saw_sheet_special := false
var saw_sheet_death := false

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--role="): role = arg.trim_prefix("--role=")
		if arg.begins_with("--port="): port = int(arg.trim_prefix("--port="))
		if arg.begins_with("--players="): expected_players = int(arg.trim_prefix("--players="))
		if arg.begins_with("--delay="): delay_ms = int(arg.trim_prefix("--delay="))
		if arg.begins_with("--jitter="): jitter_ms = int(arg.trim_prefix("--jitter="))
		if arg.begins_with("--loss="): loss = float(arg.trim_prefix("--loss="))
		if arg.begins_with("--stress="): stress = bool(int(arg.trim_prefix("--stress=")))
	local_class = "ranger" if role == "client2" else ("mage" if role == "client3" else "druid")
	session = root.get_node("NetworkSession")
	session.configure_test_network(delay_ms, jitter_ms, loss)
	var save := root.get_node("SaveManager")
	save.data = save.DEFAULT_SAVE.duplicate(true)
	save._initialize_progression(false)
	save.data.gold = 10000
	assert(save.unlock_class("druid"))
	save.data.gold = 0
	for phase in range(1, 5):
		assert(save.complete_phase("verdant_reach", phase, 0))
	var equipped_class := "warrior" if role == "host" else local_class
	var equipped_id := "gear_sheet_shield_1_0" if role == "host" else ("gear_sheet_weapon_02_0" if local_class == "ranger" else ("gear_mage_weapon_verdant_reach_1_0" if local_class == "mage" else "gear_druid_weapon_verdant_reach_1_1"))
	save.unlock_equipment(equipped_id)
	assert(root.get_node("EquipmentManager").equip("weapon", equipped_id, equipped_class))
	original_gold = int(save.data.gold)
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	process_frame.connect(_monitor)
	if role == "host":
		assert(session.host(session.profile("Host", "warrior"), {"map": "verdant_reach", "phase": 5, "tier": 0}, port) == OK)
		await _until(func() -> bool: return session.players.size() == expected_players)
		assert(session.set_destination("verdant_reach", 4, 0))
		assert(session.set_destination("verdant_reach", 5, 0))
		assert(not session.set_destination("verdant_reach", 6, 0) and int(session.config.phase) == 5, "Lobby destination must respect every friend's progression")
		assert(session.start())
		await _until(func() -> bool: return main.active_game != null and main.active_game.started)
		var game: Node = main.active_game
		game._toggle_pause()
		game._open_pause_settings()
		assert(not paused and is_instance_valid(game.pause_settings_layer), "Online settings must not pause the party")
		game._toggle_pause()
		assert(game.pause_layer.visible and game.pause_settings_layer == null)
		game._toggle_pause()
		assert(game.pause_layer == null)
		game.wave_director.set_process(false)
		game.phase_director.set_process(false)
		_disable_fixture_obstacles(game)
		if stress:
			_add_stress_world(game)
		var remote_id: int = session.players.keys().filter(func(id: int) -> bool: return id != 1)[0]
		var remote: Node = game.actors[remote_id]
		assert(remote.player.equipped_weapon_id == session.players[remote_id].weapon, "Host renders each guest's actual equipped model")
		var start_position: Vector2 = remote.player.global_position
		await _until(func() -> bool: return remote.player.global_position.x > start_position.x + 40)
		assert(remote.player.global_position.x > start_position.x + 40, "Client input must move the authoritative player: peer=%s start=%s end=%s ack=%s received=%s moving_commands=%s dead=%s speed=%s" % [session.players[remote_id].name, start_position, remote.player.global_position, session.acknowledged_inputs.get(remote_id, 0), session.received_input_sequences.get(remote_id, 0), session.simulated_motion_commands.get(remote_id, 0), remote.player.is_dead, remote.player.move_speed])
		game._on_orb_collected(ceili(game.experience.required_xp * (1.0 + 0.25 * (expected_players - 1))))
		await _until(func() -> bool: return game.collective_paused and paused)
		var frozen_position: Vector2 = remote.player.position
		await create_timer(0.12).timeout
		assert(remote.player.position.is_equal_approx(frozen_position), "Collective level-up freezes the world")
		for actor in game.actors.values():
			assert(actor.experience == game.experience and actor.player.level == game.player.level, "Party XP and levels must share one source")
		await _until(func() -> bool: return not game.collective_paused and game.actors.values().all(func(actor: Node) -> bool: return actor.pending_levelups == 0))
		assert(not paused and not game.collective_paused)
		assert(saw_waiting_names, "Selected players must see who is still choosing")
		var total_ranks := 0
		for rank in remote.abilities.levels.values(): total_ranks += int(rank)
		assert(total_ranks >= 2)
		assert(not game.accept_choice(1, "rapid_hands", game.choice_round - 1), "Old choice rounds cannot grant another rank")
		for kind in [&"red_orb", &"barrel_beast", &"demon_a", &"blood_monster", &"canarinho", &"spore_zombie", &"azure_slime", &"death_lord", &"lava_lord", &"vampire_king", &"frost_guardian", &"mire_queen"]:
			var added: Node = game.enemy_manager.spawn(kind, 4, Vector2(350, 150))
			added.health = 20000
			added.max_health = 20000
			added.damage = 0
			added.speed = 0
			if added.has_node("BossBrain"): added.get_node("BossBrain").set_process(false)
		remote._cast_special("arcane_bloom", 2)
		remote._summon_companions("rootling", 2, 20)
		remote._cast_special("living_grove", 2)
		var chest: Node = game.enemy_manager.spawn(&"loot_mimic", 4, Vector2(250, 200))
		chest.set_physics_process(false)
		await create_timer(0.6).timeout
		chest.take_hit(chest.health + chest.defense + 1)
		assert(game.mimic_loot_awarded and game.run_items.size() == 1)
		var original_skills: Dictionary = remote.abilities.levels.duplicate()
		remote.set_process(false)
		for id in remote.abilities.chooseable(): remote.abilities.levels[id] = 5
		game._on_orb_collected(ceili(game.experience.required_xp * (1.0 + 0.25 * (expected_players - 1))))
		await _until(func() -> bool: return game.collective_paused)
		await _until(func() -> bool: return not game.collective_paused and game.pending_levelups == 0)
		assert(remote.abilities.chooseable().is_empty(), "A player with maxed skills must continue without blocking the group")
		remote.abilities.levels = original_skills
		remote.player.rebuild_run_stats(remote.abilities.accumulated_bonuses())
		remote.set_process(true)
		var enemy: Node2D = game.enemy_manager.spawn(&"slime", 1, remote.player.position + Vector2(100, 0))
		# Keep the rendering fixture alive long enough for every guest to receive it.
		enemy.max_health = 20000
		enemy.health = 20000
		enemy.damage = 0
		var initial_health: float = enemy.health
		game.enemy_manager._process(1)
		remote._try_basic_attack()
		await create_timer(0.5).timeout
		assert(enemy.dead or enemy.health < initial_health, "Remote class must deal real damage")
		assert(remote.player.total_damage_dealt > 0, "Remote damage and life recovery must be credited to its owner")
		game._on_enemy_shot(remote.player.position + Vector2(0, 100), Vector2.RIGHT, 8, Color.RED, remote.player)
		game._on_boss_pattern({"shape": "ring", "position": Vector2(400, 400), "radius": 90.0, "inner": 40.0, "damage": 8.0, "color": Color.RED, "duration": 3.0, "target": remote.player})
		await create_timer(1.0).timeout
		for rift in game.phase_director.rifts:
			remote.player.position = rift.position
			rift._process(1.7)
		assert(game.phase_director.objective_complete(), "Any teammate must be able to seal rifts")
		game.player.take_damage(100000)
		assert(game.player.is_dead and not game.run_finished, "The group survives one player's death")
		for actor in game.actors.values():
			if actor != game and actor != remote:
				actor.player.position = Vector2(600, 600)
		remote.player.position = game.player.position + Vector2(30, 0)
		game._update_revives(0.01)
		game._update_revives(1.0)
		assert(game.player.revive_progress > 0.2)
		var saved_revival: float = game.player.revive_progress
		remote.player.take_damage(10, true)
		game._update_revives(0.1)
		assert(game.player.revive_progress == saved_revival, "Taking damage pauses revival without erasing progress")
		remote.player.position = Vector2(600, 600)
		game._update_revives(1.0)
		assert(game.player.is_dead and game.player.revive_progress == saved_revival)
		# Keep the preserved partial state observable through delayed world packets.
		await create_timer(0.6).timeout
		remote.player.position = game.player.position + Vector2(30, 0)
		game._update_revives(0.01)
		game.collective_paused = true
		game._update_revives(5.0)
		assert(game.player.is_dead, "Collective choices freeze revival")
		game.collective_paused = false
		game._update_revives(3.0)
		await create_timer(1.5).timeout
		game._update_revives(1.1)
		assert(not game.player.is_dead and game.player.health >= game.player.max_health * 0.35)
		var revived_health: float = game.player.health
		game.player.take_damage(100000)
		assert(game.player.health == revived_health, "Revival grants genuine brief damage protection")
		await create_timer(1.5).timeout

		game._on_boss_summoned(&"goblin_king")
		assert(game.boss_music_active and root.get_node("AudioManager").music_player.playing)
		await create_timer(0.7).timeout
		game.boss.take_hit(100000)
		assert(game.run_finished and game.result_layer != null)
		assert(int(save.data.gold) > original_gold and save.phase_completed("verdant_reach", 5, 0))
		assert(save.has_relic("blood_pact", "warrior") and not save.has_relic("blood_pact", "druid"))
		var banked_gold: int = save.data.gold
		session._results(session.run_id, {})
		assert(int(save.data.gold) == banked_gold, "Repeated result packets must never duplicate rewards")
		assert(not paused, "Online result screens must not pause networking")
		_assert_loot(game, save)
		assert(not game.boss_music_active)
		assert(session.maximum_player_packet_bytes < 950, "Priority player updates must fit in one datagram")
		print("NETWORK HOST METRICS: largest_priority_packet_bytes=%d max_capture_metadata_ms=%.3f max_batch_flush_ms=%.3f" % [session.maximum_player_packet_bytes, float(session.maximum_snapshot_usec) / 1000.0, float(session.maximum_batch_flush_usec) / 1000.0])
		await create_timer(1.0).timeout
		session.return_lobby()
		await _until(func() -> bool: return not session.running and main.active_game == null)
		assert(main.page_name == "online")
		await create_timer(0.5).timeout
		assert(session.advance() and int(session.config.phase) == 6, "The party must advance together without closing the lobby")
		assert(session.start())
		await _until(func() -> bool: return main.active_game != null and main.active_game.started)
		game = main.active_game
		assert(session.choice_epoch == 0, "A new expedition resets movement epochs for returning and newly joined friends")
		game.wave_director.stop()
		for actor in game.actors.values():
			actor.player.take_damage(100000)
		assert(game.run_finished and save.data.statistics.total_runs == 2)
		await create_timer(0.5).timeout
		session.return_lobby()
		await _until(func() -> bool: return main.active_game == null)
		print("PASS ONLINE HOST: lobby, real ENet input, remote combat, owner damage, shared XP, independent choices, cooperative rifts, teammate death, boss victory, saved rewards and return to lobby")
		await create_timer(1.0).timeout
		session.close()
	else:
		assert(session.join("127.0.0.1", session.profile(role, local_class), port) == OK)
		await _until(func() -> bool: return main.active_game != null and main.active_game.started)
		_disable_fixture_obstacles(main.active_game)
		assert(main.active_game.replica.visuals.has("P%d" % session.multiplayer.get_unique_id()), "Starting positions arrive before controls are enabled")
		assert(main.active_game.replica.visuals.P1.equipped_weapon_id == session.players[1].weapon, "Clients render the host's actual sword/shield model")
		Input.action_press("move_right")
		print("INPUT PROBE %s: start_seq=%d direction=%s" % [role, session.input_sequence, session.local_direction()])
		var predicted_before: Vector2 = main.active_game.player.position
		var prediction_started := Time.get_ticks_usec()
		main.active_game.replica._physics_process(1.0 / 60.0)
		maximum_prediction_step_ms = float(Time.get_ticks_usec() - prediction_started) / 1000.0
		assert(main.active_game.player.position.x > predicted_before.x, "Client movement must respond before a server reply")
		await create_timer(0.75).timeout
		Input.action_release("move_right")
		print("INPUT PROBE %s: end_seq=%d" % [role, session.input_sequence])
		await _until(func() -> bool: return main.active_game.run_finished)
		assert(saw_revival_progress and saw_revived_host, "Clients synchronize revival: %s dead=%s max_progress=%s revived=%s seq=%d" % [role, saw_any_dead_host, max_revival_progress, saw_revived_host, session.last_snapshot_sequence])
		assert(choices_taken >= 1, "Client must receive and choose its own skills")
		assert(main.active_game.mimic_loot_awarded and main.active_game.run_items.size() == 1, "Each client receives and saves its own mimic item")
		for type in ["P", "E", "Q", "D", "M", "C", "F"]:
			assert(observed.has(type), "Client must see synchronized " + type)
		assert(int(save.data.gold) > original_gold and save.phase_completed("verdant_reach", 5, 0))
		assert(int(save.data.class_progression[local_class].xp) > 0)
		assert(saw_match_music and saw_boss_music and saw_attack_animation, "Clients switch from quiet wave music to the boss soundtrack and receive attack state")
		assert(saw_sheet_special and saw_sheet_death, "New character sheets synchronize special poses and downed animation")
		assert(saw_demon and saw_bloom, "Clients receive the new demon and expanding spell Sprite2D animation")
		assert(saw_rootling and saw_grove, "Guests must see native rootling sprites and summoned trees: rootling=%s grove=%s" % [saw_rootling, saw_grove])
		for kind in ["blood_monster", "canarinho", "spore_zombie", "azure_slime", "death_lord", "lava_lord", "vampire_king", "frost_guardian", "mire_queen"]: assert(new_species.has(kind), "Missing replicated pixel creature: " + kind)
		assert(save.has_relic("blood_pact", local_class) and not save.has_relic("blood_pact", "warrior"), "Online relic discoveries belong to the class actually played")
		_assert_loot(main.active_game, save)
		if delay_ms > 0:
			assert(session.rtt_ms > delay_ms, "The test must exercise genuinely delayed acknowledgements")
		print("NETWORK METRICS %s: predicted_step_ms=%.3f rtt_ms=%.1f ordinary_movement_correction_px=%.2f priority_frames=%d" % [role, maximum_prediction_step_ms, session.rtt_ms, early_motion_correction, session.player_snapshots_received])
		assert(not paused)
		await _until(func() -> bool: return main.active_game == null and not session.running)
		assert(main.page_name == "online")
		await _until(func() -> bool: return main.active_game != null and main.active_game.started)
		await _until(func() -> bool: return main.active_game.run_finished)
		assert(save.data.statistics.total_runs == 2)
		await _until(func() -> bool: return main.active_game == null)
		print("PASS ONLINE CLIENT: host and ally rendering, monsters, projectiles, danger geometry, objectives, summons, personal skill choices, own save and lobby return")
		await _until(func() -> bool: return not session.active)
	finished = true
	main.queue_free()
	await process_frame
	root.get_node("AudioManager").stop_all()
	await create_timer(0.6).timeout
	quit()

func _monitor() -> void:
	if finished or not is_instance_valid(main) or main.active_game == null:
		return
	var game: Node = main.active_game
	if game.level_layer != null and game.collective_paused:
		if not game.choosing_skill:
			var waiting_text := ""
			for label in game.level_layer.find_children("*", "Label", true, false): waiting_text += label.text
			if waiting_text.contains("ESPERANDO PLAYER(S)") and waiting_text.contains("client"): saw_waiting_names = true
	if game.level_layer != null and game.choosing_skill:
		var screen: Control = game.level_layer.find_child("AbilityChoiceScreen", true, false)
		if screen != null:
			if choice_seen_at < 0: choice_seen_at = Time.get_ticks_msec()
			if role != "client" or Time.get_ticks_msec() - choice_seen_at >= 350:
				screen.grid.get_child(0).pressed.emit()
				choices_taken += 1
				choice_seen_at = -1
	if role != "host" and game.replica != null:
		if game.experience.level == 1 and session.player_snapshots_received > 8:
			early_motion_correction = maxf(early_motion_correction, game.replica.reconciliation.length())
		saw_boss_music = saw_boss_music or (game.boss_music_active and root.get_node("AudioManager").music_player.stream == root.get_node("AudioManager").boss_stream)
		var audio: Node = root.get_node("AudioManager")
		saw_match_music = saw_match_music or (audio.music_player.playing and audio.music_player.stream == audio.match_stream and audio.music_player.volume_db <= -12.0)
		var host_player: Node = game.replica.visuals.get("P1")
		if host_player != null:
			saw_any_dead_host = saw_any_dead_host or bool(host_player.is_dead)
			max_revival_progress = maxf(max_revival_progress, host_player.revive_progress)
			if host_player.is_dead and host_player.revive_progress > 0.0:
				saw_revival_progress = true
			if saw_revival_progress and not host_player.is_dead:
				saw_revived_host = true
		for node in game.replica.visuals.values():
			if node.get_script() == game.replica.PLAYER and preload("res://scripts/data/character_sheet.gd").has_class(node.player_class):
				assert(node.has_node("CharacterSprite"))
				saw_sheet_special = saw_sheet_special or (node.attack_special and node.attack_time > 0)
				saw_sheet_death = saw_sheet_death or (node.is_dead and node.death_elapsed > 0.1)
			if node.get_script() == game.replica.ENEMY and node.kind in [&"blood_monster", &"canarinho", &"spore_zombie", &"azure_slime", &"death_lord", &"lava_lord", &"vampire_king", &"frost_guardian", &"mire_queen"]:
				assert(node.has_node("PixelSprite"))
				new_species[str(node.kind)] = true
			if node.get_script() == game.replica.COMPANION:
				if node.kind == "rootling": saw_rootling = node.has_node("RootlingSprite")
				if node.kind == "grove_tree": saw_grove = true
			if node.get_script() == game.replica.ENEMY and node.kind == &"demon_a":
				saw_demon = node.has_node("PixelSprite")
			if node.get_script() == game.replica.SKILL_EFFECT and node.kind == "arcane_bloom":
				saw_bloom = is_instance_valid(node.bloom_sprite) and node.bloom_sprite.region_enabled
			if node.get_script() == game.replica.PLAYER and node.attack_serial > 0:
				saw_attack_animation = true
			for type in game.replica.FIELDS:
				var scripts := {"P": game.replica.PLAYER, "E": game.replica.ENEMY, "Q": game.replica.PROJECTILE, "D": game.replica.PATTERN, "M": game.replica.MARKER, "C": game.replica.COMPANION, "F": game.replica.SKILL_EFFECT}
				if scripts.has(type) and node.get_script() == scripts[type]:
					observed[type] = true

func _disable_fixture_obstacles(game: Node) -> void:
	# Isolate network movement from whichever random peer spawn meets a tree/stone.
	# Wall collision fidelity is covered independently by network_motion.gd.
	for child in game.get_children():
		if child.get_script() == game.GROUND_SCRIPT:
			for obstacle in child.get_children():
				if obstacle is StaticBody2D:
					obstacle.collision_layer = 0

func _add_stress_world(game: Node) -> void:
	for index in 130:
		var enemy: Node = game.enemy_manager.spawn(&"goblin", 5, Vector2(650 + index % 10 * 30, 450 + index / 10 * 20))
		enemy.max_health = 1000000
		enemy.health = 1000000
		enemy.damage = 0
		enemy.speed = 0
	for index in 120:
		var xp: Node = game.ORB_SCRIPT.new()
		xp.player = game.player
		xp.position = Vector2(900, 600 + index % 20)
		game.add_child(xp)
		var gold: Node = game.GOLD_ORB_SCRIPT.new()
		gold.player = game.player
		gold.position = Vector2(-900, 600 + index % 20)
		game.add_child(gold)
	for index in 24:
		game._spawn_skill(Vector2(700, 700), "roots", 100, Color.GREEN)
	var start := Time.get_ticks_usec()
	var packet: Dictionary = game.capture()
	var bytes: PackedByteArray = session.CODEC.encode(packet, game.REPLICA.FIELDS)
	print("NETWORK STRESS: entities=%d compressed_bytes=%d capture_encode_ms=%.3f" % [packet.rows.size(), bytes.size(), float(Time.get_ticks_usec() - start) / 1000.0])

func _assert_loot(game: Node, save: Node) -> void:
	var loot: Control = game.result_layer.find_child("RunRewards", true, false)
	assert(loot != null and loot.items.size() == 4, "Mimic, boss reward and both collective level rewards are shown")
	for entry in loot.items:
		assert(save.equipment_quantity(str(entry.id), game.player_class) > 0, "The screen shows items genuinely awarded to the class played")
	assert(not game.boss_music_active and not root.get_node("AudioManager").music_player.playing)

func _until(condition: Callable) -> void:
	var deadline := Time.get_ticks_msec() + 18000
	while not condition.call():
		assert(Time.get_ticks_msec() < deadline, "Online integration timed out: " + role)
		await process_frame
