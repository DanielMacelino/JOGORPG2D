extends ExpeditionGame
const ACTOR := preload("res://scripts/network/coop_actor.gd")
const REPLICA := preload("res://scripts/network/world_replica.gd")
var actors: Dictionary = {}
var revive_helpers: Dictionary = {}
const REVIVE_SECONDS := 4.0
const REVIVE_RADIUS := 76.0
var collective_paused := false
var group_pending := 0
var choice_round := 0
var choosing_skill := false
var waiting_players: Dictionary = {}
var team_xp_fraction := 0.0
var offers: Dictionary = {}
var level_rewards := 0
var started := false
var kill_kinds: Dictionary = {}
var replica: Node2D
var team_label: Control
var choice_ids: Array = []
var choice_ranks: Dictionary = {}
var ability_uses: Dictionary = {}

func _ready() -> void:
	if NetworkSession.hosting:
		super._ready()
		actors[1] = self
		enemy_manager.damage_dealt.disconnect(player.record_damage)
		enemy_manager.damage_dealt.connect(func(amount: float) -> void:
			if is_instance_valid(enemy_manager.damage_source):
				enemy_manager.damage_source.record_damage(amount))
		wave_director.stop()
		phase_director.set_process(false)
		player.set_physics_process(false)
		for id in NetworkSession.players:
			if int(id) == 1:
				continue
			var actor := ACTOR.new()
			actor.peer_id = int(id)
			actor.host_world = self
			actor.player_class = str(NetworkSession.players[id].class)
			add_child(actor)
			actors[id] = actor
	else:
		get_viewport().size_changed.connect(_on_viewport_resized)
		map_data = CampaignRules.expedition(map_id, phase_number, difficulty_tier)
		_build_world()
		player.set_physics_process(false)
		wave_director = WaveDirector.new()
		add_child(wave_director)
		experience = ExperienceManager.new()
		add_child(experience)
		abilities = AbilityManager.new()
		add_child(abilities)
		phase_director = ReplicaObjective.new()
		add_child(phase_director)
		_build_hud()
		replica = REPLICA.new()
		replica.world = self
		add_child(replica)
	_build_team_label()
	camera.position_smoothing_enabled = false
	NetworkSession.attach(self)

func begin_coop() -> void:
	if started:
		return
	started = true
	AudioManager.match_music(true)
	if NetworkSession.hosting:
		wave_director.start()
		phase_director.set_process(true)
		for actor in actors.values():
			actor.set_process(true)
			actor.player.set_physics_process(true)
	_show_notice("EXPEDIÇÃO COOPERATIVA · PROTEJAM O GRUPO")

func _build_team_label() -> void:
	team_label = preload("res://scripts/ui/party_hud.gd").new()
	ui_root.add_child(team_label)

func _process(delta: float) -> void:
	if not started or run_finished:
		return
	if NetworkSession.hosting:
		player.use_local_input = level_layer == null and pause_layer == null
		if not player.use_local_input:
			player.external_direction = Vector2.ZERO
		if not player.is_dead:
			enemy_manager.damage_source = player
			super._process(delta)
			enemy_manager.damage_source = null
		else:
			_update_hud()
			_update_boss_hud()
			for actor in actors.values():
				if not actor.player.is_dead:
					camera.global_position = actor.player.global_position
					break
		_update_revives(delta)
		if not player.is_dead:
			camera.position = Vector2.ZERO
		_refresh_team()

func _update_revives(delta: float) -> void:
	if collective_paused or run_finished:
		return
	for id in actors:
		var fallen: SurvivorPlayer = actors[id].player
		if not fallen.is_dead:
			continue
		var helper: SurvivorPlayer = null
		var nearest := REVIVE_RADIUS
		for other in actors:
			var candidate: SurvivorPlayer = actors[other].player
			if candidate.is_dead:
				continue
			var distance := candidate.global_position.distance_to(fallen.global_position)
			if distance <= nearest:
				nearest = distance
				helper = candidate
		if helper == null:
			revive_helpers.erase(id)
		else:
			var state: Array = revive_helpers.get(id, [])
			if state.is_empty() or state[0] != helper.get_instance_id():
				state = [helper.get_instance_id(), helper.damage_serial, 0.0]
			if state[1] != helper.damage_serial:
				state[1] = helper.damage_serial
				state[2] = 0.8
			elif float(state[2]) <= 0.0:
				fallen.revive_progress = minf(1.0, fallen.revive_progress + delta / REVIVE_SECONDS)
			state[2] = maxf(0.0, float(state[2]) - delta)
			revive_helpers[id] = state
			if fallen.revive_progress >= 1.0:
				fallen.revive()
				_spawn_skill(fallen.global_position, "summon", 65.0, Color("#8dffce"))
				revive_helpers.erase(id)
				_show_notice("ALIADO REANIMADO · PROTEJAM O GRUPO")
		fallen.queue_redraw()

func _refresh_team() -> void:
	var members: Array[Dictionary] = []
	for id in actors:
		var unit: SurvivorPlayer = actors[id].player
		members.append({"name": NetworkSession.players.get(id, {}).get("name", "Viajante"), "class_id": str(unit.class_data.id), "health": unit.health, "maximum": unit.max_health, "dead": unit.is_dead, "revive": unit.revive_progress})
	team_label.update_members(members)

func _record_kill(_kind: String) -> void:
	pass # Each participant banks the final shared kill ledger in their own save.

func _record_ability_use(id: String) -> void:
	ability_uses[id] = int(ability_uses.get(id, 0)) + 1

func _award_mimic_loot(at: Vector2) -> void:
	if mimic_loot_awarded or not NetworkSession.hosting: return
	var rewards := {}
	for id in actors:
		var actor: Node = actors[id]
		var drop := loot.roll_boss_reward(map_id, actor.player_class, phase_number, NetworkSession.players[id].owned, difficulty_tier)
		rewards[id] = str(drop.equipment)
	NetworkSession.award_mimic_items(rewards, at)

func _on_enemy_died(enemy: ChaserEnemy) -> void:
	if run_finished:
		return
	kill_kinds[str(enemy.kind)] = int(kill_kinds.get(str(enemy.kind), 0)) + 1
	for id in actors:
		if int(id) != 1:
			var actor: Node = actors[id]
			actor.enemies_defeated += 1
			actor.elites_defeated += int(enemy.data.elite)
			actor.bosses_defeated += int(enemy.data.boss)
			actor.kill_chain += 1
			actor.best_chain = maxi(actor.best_chain, actor.kill_chain)
			actor.chain_clock = 6
			if not enemy.data.boss and (actor.kill_chain == 10 or actor.kill_chain % 25 == 0):
				var bonus := 5 if actor.kill_chain == 10 else 12
				actor.run_gold += bonus

	if enemy.data.boss:
		_set_boss_music(false)
		AudioManager.feedback("boss")
		# Independent drops are rolled against each participant's collection at the end.
		bosses_defeated += 1
		enemies_defeated += 1
		defeated_boss_name = enemy.data.display_name
		if phase_director.objective_complete():
			_finish_run(true)
		else:
			_show_notice("CHEFE DERROTADO · CONCLUAM O OBJETIVO")
		return
	super._on_enemy_died(enemy)

func _on_orb_collected(amount: int) -> void:
	if run_finished: return
	team_xp_fraction += amount / (1.0 + 0.25 * (actors.size() - 1))
	var earned := floori(team_xp_fraction)
	team_xp_fraction -= earned
	super._on_orb_collected(earned)
func _on_gold_collected(amount: int) -> void:
	if run_finished:
		return
	super._on_gold_collected(amount)
	for id in actors:
		if int(id) != 1:
			actors[id].run_gold += amount

func _on_level_up(value: int) -> void:
	for actor in actors.values():
		actor.abilities.expedition_level = value
		actor.player.level = value
		actor.player.rebuild_run_stats(actor.abilities.accumulated_bonuses())
		actor.player.heal(actor.player.max_health * 0.01)
		actor.level_rewards += 1
		actor.pending_levelups += 1
	group_pending += 1
	if not collective_paused:
		call_deferred("_start_group_choice")

func _start_group_choice() -> void:
	if collective_paused or run_finished or group_pending <= 0: return
	choice_round += 1
	waiting_players.clear()
	for id in actors:
		waiting_players[id] = false
	NetworkSession.group_state(true, _waiting_names())
	for id in actors:
		offer_choice(int(id))

func _waiting_names() -> Array:
	var names: Array = []
	for id in waiting_players:
		if not waiting_players[id] and NetworkSession.players.has(id):
			names.append(str(NetworkSession.players[id].name))
	return names

func _complete_group_choice() -> void:
	var names := _waiting_names()
	if not names.is_empty():
		NetworkSession.group_state(true, names)
		return
	group_pending = maxi(0, group_pending - 1)
	NetworkSession.group_state(false, [])
	if group_pending > 0:
		call_deferred("_start_group_choice")

func update_waiting(waiting: Array, paused: bool) -> void:
	if not paused:
		choosing_skill = false
		if level_layer != null:
			level_layer.queue_free()
			level_layer = null
		choice_ids = []
		return
	if level_layer != null and choosing_skill: return
	if level_layer != null: level_layer.queue_free()
	level_layer = _make_modal()
	var panel := _modal_panel(level_layer, Vector2(520, 0))
	var content := VBoxContainer.new()
	panel.add_child(_pad(content, 20, 20, 20, 20))
	_ui_label(content, "ESPERANDO PLAYER(S)", 23, GOLD)
	_ui_label(content, ", ".join(waiting), 16, MINT)
	_ui_label(content, "O grupo continua quando todos escolherem.", 12, MINT)
func offer_choice(id: int) -> void:
	if not actors.has(id) or run_finished:
		return
	var actor: Node = actors[id]
	var choices: Array = []
	for ability in actor.abilities.roll_choices(3):
		choices.append(str(ability.id))
	offers[id] = choices
	NetworkSession.offer(id, choices, actor.abilities.levels)

func accept_choice(peer: int, id: String, epoch: int = -1) -> bool:
	if run_finished or not collective_paused or not actors.has(peer) or not waiting_players.has(peer) or waiting_players[peer] or (epoch >= 0 and epoch != choice_round):
		return false
	var candidates: Array = offers.get(peer, [])
	if (not id.is_empty() and not candidates.has(id)) or (id.is_empty() and not candidates.is_empty()): return false
	var actor: Node = actors[peer]
	if not id.is_empty():
		if not actor.abilities.grant(StringName(id)): return false
		actor._apply_stat_ability(ContentCatalog.abilities[id])
	actor.pending_levelups = maxi(0, actor.pending_levelups - 1)
	offers.erase(peer)
	waiting_players[peer] = true
	_complete_group_choice()
	return true
func present_choices(ids: Array, ranks: Dictionary) -> void:
	choosing_skill = true
	choice_ids = ids
	choice_ranks = ranks
	if level_layer != null:
		level_layer.queue_free()
	level_layer = _make_modal()
	level_layer.get_child(0).color.a = 0.40
	var screen := preload("res://scripts/ui/ability_choice_screen.gd").new()
	screen.choices = ids
	screen.ranks = ranks
	screen.online = true
	screen.selected.connect(func(id: StringName) -> void:
		choosing_skill = false
		level_layer.queue_free()
		level_layer = null
		choice_ids = []
		update_waiting([], true)
		NetworkSession.choose(str(id)))
	level_layer.add_child(screen)
	_update_hud()
	_update_boss_hud()
func _show_level_choices() -> void:
	if choosing_skill:
		present_choices(choice_ids, choice_ranks)

func _on_player_died() -> void:
	super._on_player_died()

func check_party() -> void:
	if not started or run_finished:
		return
	for actor in actors.values():
		if not actor.player.is_dead:
			_show_notice("UM VIAJANTE CAIU · OS ALIADOS CONTINUAM")
			return
	_finish_run(false, true)

func _finish_run(victory: bool, party_defeated: bool = false) -> void:
	if not NetworkSession.hosting or run_finished:
		return
	if not victory and not party_defeated and (phase_director == null or not is_instance_valid(phase_director.altar) or phase_director.altar.health > 0):
		check_party()
		return
	run_finished = true
	wave_director.stop()
	var results := {}
	for id in actors:
		var actor: Node = actors[id]
		actor.run_finished = true
		var drop := loot.roll_boss_reward(map_id, actor.player_class, phase_number, NetworkSession.players[id].owned, difficulty_tier) if victory else {}
		if victory:
			drop.gold = roundi(int(drop.gold) * CampaignRules.reward_multiplier(difficulty_tier, phase_number))
		results[id] = {"class": actor.player_class, "victory": victory, "reward": drop, "gold": actor.run_gold, "wave": wave_director.wave, "time": wave_director.match_time, "kills": enemies_defeated, "bosses": bosses_defeated, "elites": elites_defeated, "damage": actor.player.total_damage_dealt, "level_rewards": actor.level_rewards, "multiplier": CampaignRules.reward_multiplier(difficulty_tier, phase_number) * (1 + actor.player.bonus_gold_xp + actor.player.bonus_xp_only), "kinds": kill_kinds, "uses": actor.ability_uses, "skill_count": actor.abilities.levels.size()}
	NetworkSession.finish(results)

func show_coop_result(result: Dictionary, banked_gold: int) -> void:
	_close_pause_settings()
	get_tree().paused = false
	collective_paused = false
	run_finished = true
	for node in get_children():
		if node != ui_layer:
			node.process_mode = Node.PROCESS_MODE_DISABLED
	if level_layer != null:
		level_layer.queue_free()
		level_layer = null
	if pause_layer != null:
		pause_layer.queue_free()
		pause_layer = null
	GameManager.finish_run()
	_set_boss_music(false)
	AudioManager.match_music(false)
	result_layer = _make_modal()
	var panel := _result_panel(result_layer, 720.0)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	panel.add_child(_pad(content, 20, 20, 20, 20))
	_ui_label(content, "FASE CONCLUÍDA EM GRUPO!" if result.victory else "O GRUPO FOI DERROTADO", 25, GOLD)
	_ui_label(content, "%d abates · Onda %d · %s\n+%d ouro · +%d XP para %s" % [result.kills, result.wave, _format_time(float(result.time)), banked_gold, SaveManager.data.class_progression[player_class].last_xp, player.class_data.display_name], 14, MINT)
	if result.victory:
		_ui_label(content, "+%d cristais do chefe" % int(result.reward.get("crystals", 0)), 14, GOLD)
	if not result.get("items", []).is_empty(): _add_run_rewards(content, result.get("items", []))
	_ui_label(content, "Seu progresso foi salvo neste computador.", 12, MINT)
	if NetworkSession.hosting:
		_ui_button(content, "VOLTAR À SALA COM O GRUPO", NetworkSession.return_lobby, true)
	else:
		_ui_label(content, "Aguardando o anfitrião voltar à sala…", 13, MINT)
	_ui_button(content, "SAIR DA SALA", func() -> void: NetworkSession.close("Você saiu da sala."))

func remove_peer(id: int) -> void:
	if actors.has(id):
		actors[id].queue_free()
		actors.erase(id)
		waiting_players.erase(id)
		if collective_paused: _complete_group_choice()
		_show_notice("UM VIAJANTE DESCONECTOU")
	check_party()

func _toggle_pause() -> void:
	if _close_pause_settings(): return
	if run_finished:
		return
	if pause_layer != null:
		pause_layer.queue_free()
		pause_layer = null
		if hud_layout_dirty:
			hud_layout_dirty = false
			_build_hud()
			_build_team_label()
			_update_hud()
		return
	pause_layer = _make_modal()
	var panel := _modal_panel(pause_layer, Vector2(440, 0))
	var content := VBoxContainer.new()
	panel.add_child(_pad(content, 20, 20, 20, 20))
	_ui_label(content, "EXPEDIÇÃO ONLINE", 23, GOLD)
	_ui_label(content, "O grupo continua jogando. A partida não pausa.", 13, MINT)
	_ui_button(content, "CONTINUAR", _toggle_pause, true)
	_ui_button(content, "CONFIGURAÇÕES", _open_pause_settings, false).name = "OpenPauseSettings"
	_ui_button(content, "SAIR DA SALA", func() -> void: NetworkSession.close("Você saiu da sala."))

func _on_viewport_resized() -> void:
	super._on_viewport_resized()
	if ui_root != null and (team_label == null or not is_instance_valid(team_label) or team_label.get_parent() != ui_root):
		_build_team_label()

func capture(include_rows: bool = true) -> Dictionary:
	return REPLICA.capture_world(self, include_rows)

func apply_snapshot(value: Dictionary) -> void:
	if not run_finished:
		replica.apply(value)

class ReplicaObjective extends Node:
	var text := "Aguardando o anfitrião…"
	func status() -> String:
		return text
