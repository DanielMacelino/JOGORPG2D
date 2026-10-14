extends Node
signal changed
signal launch_requested(config: Dictionary)
signal session_closed(reason: String)
signal lobby_requested
const PROTOCOL := "ashenwild-coop-6"
const CODEC := preload("res://scripts/network/snapshot_codec.gd")
const INPUT_STEP := 1.0 / 60.0
const INPUT_REDUNDANCY := 8
const PORT := 24567
const MAX_PLAYERS := 4
const PLAYER_STATS := ["max_health", "damage", "defense", "move_speed", "attack_cooldown", "attack_range", "projectile_speed", "crit_chance", "crit_multiplier", "bonus_gold_xp", "pickup_radius", "lifesteal", "regen", "cleave_targets", "projectile_pierce", "splash_bonus", "class_power", "power_damage", "thorns", "summon_duration", "summon_damage_pct", "projectile_bounces", "burn_on_hit", "chill_on_hit", "character_level"]
var active := false
var hosting := false
var running := false
var status := "Crie uma sala ou entre pelo IP do anfitrião no Radmin."
var players: Dictionary = {}
var config: Dictionary = {}
var local_profile: Dictionary = {}
var game: Node
var ready_peers: Dictionary = {}
var run_id := ""
var result_applied := ""
var pending_since := 0
var snapshot_clock := 0.0
var previous_world_ids: Dictionary = {}
var pending_world_batches: Array[Dictionary] = []
var world_batch_cursor := 0
var maximum_batch_flush_usec := 0
var input_clock := 0.0
var inputs: Dictionary = {}
var input_times: Dictionary = {}
var snapshot_sequence := 0
var last_snapshot_sequence := -1
var snapshot_parts: Dictionary = {}
var input_sequence := 0
var received_input_sequences: Dictionary = {}
var acknowledged_inputs: Dictionary = {}
var pending_inputs: Array[Dictionary] = []
var input_buffers: Dictionary = {}
var acknowledged_stamps: Dictionary = {}
var simulated_motion_commands: Dictionary = {}
var player_sequence := 0
var last_player_sequence := -1
var rtt_ms := 0.0
var test_network_enabled := false
var test_latency_ms := 0
var test_jitter_ms := 0
var test_loss := 0.0
var test_deliveries: Array[Dictionary] = []
var test_packet_counter := 0
var maximum_snapshot_usec := 0
var maximum_player_packet_bytes := 0
var snapshots_sent_bytes := 0
var player_snapshots_received := 0
var choice_epoch := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	multiplayer.peer_disconnected.connect(_peer_left)
	multiplayer.connected_to_server.connect(_connected)
	multiplayer.connection_failed.connect(func() -> void: close("Não foi possível conectar. Confira o IP, a porta e o firewall."))
	multiplayer.server_disconnected.connect(func() -> void: close("O anfitrião encerrou a sala ou perdeu a conexão."))

func profile(nickname: String, class_id: String) -> Dictionary:
	var actor := SurvivorPlayer.new()
	actor.configure(class_id, {})
	var stats := {}
	for key in PLAYER_STATS:
		stats[key] = actor.get(key)
	actor.free()
	var unlocked: Array[String] = []
	for region in ContentCatalog.MAP_ORDER:
		for tier in range(int(SaveManager.data.get("highest_difficulty", 0)) + 2):
			for phase in range(1, 11):
				if SaveManager.phase_unlocked(region, phase, tier):
					unlocked.append("%s:%d:%d" % [region, phase, tier])
	return {"version": PROTOCOL, "name": nickname.strip_edges().left(24) if not nickname.strip_edges().is_empty() else "Viajante", "class": class_id, "stats": stats, "owned": SaveManager.data.equipment.duplicate(), "unlocked": unlocked}

func host(value: Dictionary, destination: Dictionary, port: int = PORT) -> Error:
	if active:
		return ERR_ALREADY_IN_USE
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(port, MAX_PLAYERS - 1, 3)
	if error != OK:
		status = "Não foi possível abrir a porta %d. Tente outra porta." % port
		changed.emit()
		return error
	multiplayer.multiplayer_peer = peer
	active = true
	hosting = true
	local_profile = value
	players = {1: value}
	config = destination.duplicate()
	config.port = port
	status = "Sala aberta. Compartilhe seu IP do Radmin e a porta %d." % port
	changed.emit()
	return OK

func join(address: String, value: Dictionary, port: int = PORT) -> Error:
	if active:
		return ERR_ALREADY_IN_USE
	if not address.strip_edges().is_valid_ip_address():
		status = "Digite um IP válido, como 26.12.34.56."
		changed.emit()
		return ERR_INVALID_PARAMETER
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_client(address.strip_edges(), port, 3)
	if error != OK:
		return error
	multiplayer.multiplayer_peer = peer
	active = true
	hosting = false
	config.clear()
	players.clear()
	local_profile = value
	pending_since = Time.get_ticks_msec()
	status = "Conectando a %s:%d…" % [address.strip_edges(), port]
	changed.emit()
	return OK

func _connected() -> void:
	_register.rpc_id(1, local_profile)

@rpc("any_peer", "reliable")
func _register(value: Dictionary) -> void:
	if not hosting:
		return
	var id := multiplayer.get_remote_sender_id()
	if running or (players.size() >= MAX_PLAYERS and not players.has(id)) or str(value.get("version", "")) != PROTOCOL:
		_reject.rpc_id(id, "Sala em partida, cheia ou versão do jogo diferente.")
		return
	var class_id := str(value.get("class", ""))
	if not ContentCatalog.classes.has(class_id) or not value.get("stats", {}) is Dictionary:
		_reject.rpc_id(id, "Personagem inválido.")
		return
	var clean := value.duplicate(true)
	clean.name = str(clean.get("name", "Viajante")).strip_edges().left(24)
	var stats: Dictionary = clean.stats
	for key in PLAYER_STATS:
		if not stats.has(key) or (not stats[key] is float and not stats[key] is int and not stats[key] is bool):
			_reject.rpc_id(id, "Dados do personagem incompatíveis.")
			return
		if not is_finite(float(stats[key])):
			_reject.rpc_id(id, "Atributos inválidos.")
			return
	stats.max_health = clampf(float(stats.max_health), 1, 10000)
	stats.damage = clampf(float(stats.damage), 1, 5000)
	stats.move_speed = clampf(float(stats.move_speed), 50, 900)
	stats.attack_cooldown = clampf(float(stats.attack_cooldown), 0.05, 5)
	players[id] = clean
	_sync_lobby.rpc(players, config)

@rpc("authority", "reliable")
func _reject(reason: String) -> void:
	close(reason)

@rpc("authority", "call_local", "reliable")
func _sync_lobby(roster: Dictionary, destination: Dictionary) -> void:
	players = roster
	config = destination
	pending_since = 0
	if not hosting and players.has(1):
		status = "Conectado à sala de %s." % players[1].name
	changed.emit()

func start() -> bool:
	if not hosting or running or players.size() < 2:
		status = "Espere pelo menos um amigo entrar na sala."
		changed.emit()
		return false
	var key := "%s:%d:%d" % [config.map, config.phase, config.tier]
	for entry in players.values():
		if not entry.get("unlocked", []).has(key):
			status = "%s ainda não desbloqueou essa fase. Escolha uma fase disponível para todos antes de criar a sala." % entry.name
			changed.emit()
			return false
	ready_peers.clear()
	inputs.clear()
	input_times.clear()
	_launch.rpc(config, players, "%d-%d" % [Time.get_unix_time_from_system(), randi()])
	return true

func advance() -> bool:
	if not hosting or running:
		return false
	var ordinal := CampaignRules.ordinal(str(config.map), int(config.phase)) + 1
	var tier := int(config.tier)
	if ordinal >= CampaignRules.TOTAL_PHASES:
		ordinal = 0
		tier += 1
	var region: String = ContentCatalog.MAP_ORDER[floori(ordinal / 10.0)]
	var phase := ordinal % 10 + 1
	var key := "%s:%d:%d" % [region, phase, tier]
	for entry in players.values():
		if not entry.unlocked.has(key):
			status = "%s ainda não desbloqueou a próxima fase." % entry.name
			changed.emit()
			return false
	config.map = region
	config.phase = phase
	config.tier = tier
	status = "Próxima fase selecionada. O anfitrião pode iniciar a expedição."
	_sync_lobby.rpc(players, config)
	return true

func set_destination(region: String, phase: int, tier: int) -> bool:
	if not hosting or running or not ContentCatalog.maps.has(region) or phase < 1 or phase > 10 or tier < 0:
		return false
	var key := "%s:%d:%d" % [region, phase, tier]
	for entry in players.values():
		if not entry.unlocked.has(key):
			status = "%s ainda não desbloqueou esse destino." % entry.name
			changed.emit()
			return false
	config.map = region
	config.phase = phase
	config.tier = tier
	status = "Destino atualizado para todo o grupo."
	_sync_lobby.rpc(players, config)
	return true

@rpc("authority", "call_local", "reliable")
func _launch(destination: Dictionary, roster: Dictionary, token: String) -> void:
	config = destination
	players = roster
	run_id = token
	input_sequence = 0
	choice_epoch = 0
	pending_inputs.clear()
	input_buffers.clear()
	acknowledged_stamps.clear()
	simulated_motion_commands.clear()
	player_sequence = 0
	last_player_sequence = -1
	test_deliveries.clear()
	rtt_ms = 0.0
	acknowledged_inputs.clear()
	received_input_sequences.clear()
	last_snapshot_sequence = -1
	previous_world_ids.clear()
	pending_world_batches.clear()
	world_batch_cursor = 0
	snapshot_parts.clear()
	running = true
	game = null
	launch_requested.emit(config)

func attach(world: Node) -> void:
	game = world
	if hosting:
		_mark_ready(1)
	else:
		_loaded.rpc_id(1, run_id)

@rpc("any_peer", "reliable")
func _loaded(token: String) -> void:
	if hosting and token == run_id:
		_mark_ready(multiplayer.get_remote_sender_id())

func _mark_ready(id: int) -> void:
	if not players.has(id):
		return
	ready_peers[id] = true
	if ready_peers.size() == players.size() and is_instance_valid(game):
		_begin.rpc(run_id, game.REPLICA.capture_players(game))

@rpc("authority", "call_local", "reliable")
func _begin(token: String, initial_players: Dictionary) -> void:
	if token == run_id and is_instance_valid(game):
		if not hosting:
			game.replica.apply_players(initial_players)
		game.begin_coop()

func _process(delta: float) -> void:
	_deliver_test_packets()
	if not active:
		return
	if pending_since > 0 and Time.get_ticks_msec() - pending_since > 12000:
		close("Tempo de conexão esgotado. Confira o IP do Radmin e a porta.")
		return
	if not running or not is_instance_valid(game):
		return
	if hosting:
		snapshot_clock -= delta
		if snapshot_clock <= 0 and pending_world_batches.is_empty():
			snapshot_clock = 1.0 / 20.0
			if game.started and not game.run_finished:
				var started_at := Time.get_ticks_usec()
				var packet: Dictionary = game.capture(not game.collective_paused)
				snapshot_sequence += 1
				if not game.collective_paused:
					_send_world_rows(packet.rows)
				packet.rows = []
				var bytes := CODEC.encode(packet, game.REPLICA.FIELDS)
				snapshots_sent_bytes += bytes.size()
				var count := ceili(bytes.size() / 950.0)
				for index in count:
					_snapshot.rpc(run_id, snapshot_sequence, index, count, bytes.slice(index * 950, (index + 1) * 950))
				maximum_snapshot_usec = maxi(maximum_snapshot_usec, Time.get_ticks_usec() - started_at)
		if game.started and not game.run_finished and not game.collective_paused and not pending_world_batches.is_empty():
			_flush_world_batches()

func _send_world_rows(rows: Array) -> void:
	var current := {}
	for row in rows:
		current[str(row.id)] = true
	var removed: Array = []
	for id in previous_world_ids:
		if not current.has(id):
			removed.append(id)
	previous_world_ids = current
	if not removed.is_empty():
		_world_despawn.rpc(run_id, snapshot_sequence, removed)
	for offset in range(0, rows.size(), 8):
		pending_world_batches.append({"frame": snapshot_sequence, "rows": rows.slice(offset, offset + 8)})

func _flush_world_batches() -> void:
	var started := Time.get_ticks_usec()
	while world_batch_cursor < pending_world_batches.size():
		var batch: Dictionary = pending_world_batches[world_batch_cursor]
		var rows: Array = batch.rows
		var size := rows.size()
		var bytes := CODEC.encode({"rows": rows}, game.REPLICA.FIELDS)
		while bytes.size() > 900 and size > 1:
			size = maxi(1, floori(float(size) / 2.0))
			bytes = CODEC.encode({"rows": rows.slice(0, size)}, game.REPLICA.FIELDS)
		snapshots_sent_bytes += bytes.size()
		_world_slice.rpc(run_id, int(batch.frame), bytes)
		if size < rows.size():
			batch.rows = rows.slice(size)
		else:
			world_batch_cursor += 1
		if Time.get_ticks_usec() - started >= 3000:
			break
	maximum_batch_flush_usec = maxi(maximum_batch_flush_usec, Time.get_ticks_usec() - started)
	if world_batch_cursor == pending_world_batches.size():
		pending_world_batches.clear()
		world_batch_cursor = 0

@rpc("authority", "call_remote", "unreliable", 1)
func _world_slice(token: String, sequence: int, bytes: PackedByteArray) -> void:
	if test_network_enabled and _queue_test_packet(Callable(self, "_receive_world_slice").bind(token, sequence, bytes)):
		return
	_receive_world_slice(token, sequence, bytes)

func _receive_world_slice(token: String, sequence: int, bytes: PackedByteArray) -> void:
	if token != run_id or not running or not is_instance_valid(game) or game.run_finished or bytes.size() > 16384:
		return
	var packet := CODEC.decode(bytes, game.replica.FIELDS)
	if not packet.is_empty():
		game.replica.apply_slice(packet, sequence)

@rpc("authority", "call_remote", "reliable", 0)
func _world_despawn(token: String, sequence: int, ids: Array) -> void:
	if token == run_id and running and is_instance_valid(game) and not game.run_finished:
		game.replica.remove_entities(ids, sequence)

func local_direction() -> Vector2:
	if not is_instance_valid(game) or game.collective_paused or game.level_layer != null or game.pause_layer != null:
		return Vector2.ZERO
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction.is_zero_approx() and game.joystick != null: direction = game.joystick.get("value")
	return direction.limit_length()

func send_input(direction: Vector2, _delta: float) -> void:
	if not active or hosting or not running:
		return
	input_sequence += 1
	pending_inputs.append({"seq": input_sequence, "direction": direction, "delta": INPUT_STEP, "stamp": Time.get_ticks_msec()})
	if pending_inputs.size() > 180:
		pending_inputs.pop_front()
	var batch: Array = []
	for index in range(maxi(0, pending_inputs.size() - INPUT_REDUNDANCY), pending_inputs.size()):
		var command: Dictionary = pending_inputs[index]
		batch.append([command.seq, command.direction, command.stamp])
	_input_batch.rpc_id(1, run_id, batch, choice_epoch)

func simulate_remote_player(player: Node) -> void:
	var id := int(player.net_peer_id)
	var queue: Dictionary = input_buffers.get(id, {})
	var sequences: Array = queue.keys()
	sequences.sort()
	var consumed := 0
	player.velocity = Vector2.ZERO
	for sequence in sequences:
		if consumed >= 8:
			break
		var command: Dictionary = queue[sequence]
		queue.erase(sequence)
		if not player.is_dead:
			if not Vector2(command.direction).is_zero_approx():
				simulated_motion_commands[id] = int(simulated_motion_commands.get(id, 0)) + 1
			player.simulate_network_step(command.direction, INPUT_STEP)
		acknowledged_inputs[id] = int(sequence)
		acknowledged_stamps[id] = int(command.stamp)
		consumed += 1

@rpc("any_peer", "call_remote", "unreliable_ordered", 2)
func _input_batch(token: String, batch: Array, epoch: int) -> void:
	var id := multiplayer.get_remote_sender_id()
	if test_network_enabled and _queue_test_packet(Callable(self, "_receive_inputs").bind(id, token, batch, epoch)):
		return
	_receive_inputs(id, token, batch, epoch)

func _receive_inputs(id: int, token: String, batch: Array, epoch: int) -> void:
	if not hosting or not running or token != run_id or not players.has(id) or not is_instance_valid(game) or epoch != choice_epoch or batch.size() > INPUT_REDUNDANCY:
		return
	if not input_buffers.has(id):
		input_buffers[id] = {}
	var queue: Dictionary = input_buffers[id]
	for packed in batch:
		if not packed is Array or packed.size() != 3 or not packed[1] is Vector2 or not Vector2(packed[1]).is_finite():
			continue
		var sequence := int(packed[0])
		if sequence <= int(acknowledged_inputs.get(id, 0)) or sequence > int(received_input_sequences.get(id, 0)) + 240:
			continue
		received_input_sequences[id] = maxi(sequence, int(received_input_sequences.get(id, 0)))
		if game.collective_paused:
			acknowledged_inputs[id] = sequence
			continue
		if queue.size() < 120:
			queue[sequence] = {"direction": Vector2(packed[1]).limit_length(), "stamp": int(packed[2])}

func _physics_process(_delta: float) -> void:
	if not hosting or not running or not is_instance_valid(game) or not game.started or game.run_finished:
		return
	player_sequence += 1
	var packet: Dictionary = game.REPLICA.capture_players(game)
	packet["frame"] = player_sequence
	var bytes := CODEC.encode(packet, game.REPLICA.FIELDS)
	maximum_player_packet_bytes = maxi(maximum_player_packet_bytes, bytes.size())
	snapshots_sent_bytes += bytes.size()
	_player_snapshot.rpc(run_id, bytes)

@rpc("authority", "call_remote", "unreliable_ordered", 2)
func _player_snapshot(token: String, bytes: PackedByteArray) -> void:
	if test_network_enabled and _queue_test_packet(Callable(self, "_receive_players").bind(token, bytes)):
		return
	_receive_players(token, bytes)

func _receive_players(token: String, bytes: PackedByteArray) -> void:
	if token != run_id or not running or not is_instance_valid(game) or game.run_finished or bytes.size() > 16384:
		return
	var packet := CODEC.decode(bytes, game.replica.FIELDS)
	if packet.is_empty() or int(packet.get("frame", -1)) <= last_player_sequence:
		return
	last_player_sequence = int(packet.frame)
	player_snapshots_received += 1
	game.replica.apply_players(packet)

func configure_test_network(delay_ms: int, jitter_ms: int, loss: float) -> void:
	assert(str(ProjectSettings.get_setting("application/config/name")).begins_with("Ashenwild Online Test"))
	test_network_enabled = delay_ms != 0 or jitter_ms != 0 or loss != 0.0
	test_latency_ms = delay_ms
	test_jitter_ms = jitter_ms
	test_loss = loss

func _queue_test_packet(deliver: Callable) -> bool:
	if test_latency_ms == 0 and test_jitter_ms == 0 and test_loss == 0.0:
		return false
	test_packet_counter += 1
	var sample := posmod(test_packet_counter * 7919, 1000) / 1000.0
	if sample < test_loss:
		return true
	var jitter := posmod(test_packet_counter * 3571, maxi(1, test_jitter_ms * 2 + 1)) - test_jitter_ms
	test_deliveries.append({"time": Time.get_ticks_msec() + maxi(0, test_latency_ms + jitter), "deliver": deliver})
	return true

func _deliver_test_packets() -> void:
	var now := Time.get_ticks_msec()
	for index in range(test_deliveries.size() - 1, -1, -1):
		if int(test_deliveries[index].time) <= now:
			var deliver: Callable = test_deliveries[index].deliver
			test_deliveries.remove_at(index)
			deliver.call()

@rpc("authority", "call_remote", "unreliable", 1)
func _snapshot(token: String, sequence: int, index: int, count: int, payload: PackedByteArray) -> void:
	if test_network_enabled and _queue_test_packet(Callable(self, "_receive_snapshot").bind(token, sequence, index, count, payload)):
		return
	_receive_snapshot(token, sequence, index, count, payload)

func _receive_snapshot(token: String, sequence: int, index: int, count: int, payload: PackedByteArray) -> void:
	if token != run_id or not running or not is_instance_valid(game) or sequence <= last_snapshot_sequence or count < 1 or count > 256 or index < 0 or index >= count or payload.size() > 950:
		return
	if not snapshot_parts.has(sequence):
		snapshot_parts[sequence] = {}
	snapshot_parts[sequence][index] = payload
	for old in snapshot_parts.keys():
		if int(old) < sequence - 2:
			snapshot_parts.erase(old)
	if snapshot_parts[sequence].size() != count:
		return
	var assembled := PackedByteArray()
	for part in count:
		assembled.append_array(snapshot_parts[sequence][part])
	snapshot_parts.erase(sequence)
	last_snapshot_sequence = sequence
	var decoded := CODEC.decode(assembled, game.replica.FIELDS)
	if not decoded.is_empty():
		game.apply_snapshot(decoded)

func offer(id: int, choices: Array, ranks: Dictionary) -> void:
	choice_epoch = game.choice_round
	if id == 1:
		game.present_choices(choices, ranks)
	else:
		_choices.rpc_id(id, run_id, choice_epoch, choices, ranks)

@rpc("authority", "reliable")
func _choices(token: String, epoch: int, choices: Array, ranks: Dictionary) -> void:
	if token == run_id and is_instance_valid(game):
		choice_epoch = epoch
		game.present_choices(choices, ranks)

func choose(id: String) -> void:
	if hosting:
		game.accept_choice(1, id, choice_epoch)
	else:
		_choose.rpc_id(1, run_id, choice_epoch, id)

@rpc("any_peer", "reliable")
func _choose(token: String, epoch: int, id: String) -> void:
	if hosting and token == run_id and is_instance_valid(game):
		game.accept_choice(multiplayer.get_remote_sender_id(), id, epoch)

func group_state(paused: bool, waiting: Array) -> void:
	_group_state.rpc(run_id, paused, waiting)

@rpc("authority", "call_local", "reliable")
func _group_state(token: String, paused: bool, waiting: Array) -> void:
	if token != run_id or not is_instance_valid(game): return
	game.collective_paused = paused
	get_tree().paused = paused
	inputs.clear()
	pending_inputs.clear()
	input_buffers.clear()
	pending_world_batches.clear()
	world_batch_cursor = 0
	if hosting:
		for id in received_input_sequences:
			acknowledged_inputs[id] = int(received_input_sequences[id])
		for actor in game.actors.values(): actor.player.external_direction = Vector2.ZERO
	game.update_waiting(waiting, paused)

func finish(results: Dictionary) -> void:
	_results.rpc(run_id, results)

@rpc("authority", "call_local", "reliable")
func _results(token: String, results: Dictionary) -> void:
	if token != run_id or result_applied == token:
		return
	var id := multiplayer.get_unique_id()
	if not results.has(id):
		return
	result_applied = token
	var result: Dictionary = results[id]
	var reward: Dictionary = result.reward
	var gold := int(result.gold)
	var items: Array[Dictionary] = []
	if result.victory and not reward.is_empty():
		var item := str(reward.equipment)
		var duplicate: bool = SaveManager.data.equipment.has(item)
		items.append({"id": item, "source": "boss", "duplicate": duplicate})
		if duplicate:
			gold += 100
		else:
			SaveManager.unlock_equipment(item)
		SaveManager.data.crystals = int(SaveManager.data.crystals) + int(reward.crystals)
		gold += int(reward.gold)
	for kind in result.kinds:
		for index in int(result.kinds[kind]):
			SaveManager.record_kill(str(kind))
	for ability in result.get("uses", {}):
		for index in int(result.uses[ability]):
			SaveManager.record_ability_use(str(ability))
	for index in int(result.level_rewards):
		var item := EquipmentManager.unlock_next_class_item(str(result.class), str(config.map), int(config.tier))
		if item.is_empty():
			gold += 30
		else:
			items.append({"id": item, "source": "level", "duplicate": false})
	SaveManager.record_run(int(result.wave), gold, float(result.time), int(result.kills), str(result.class), int(result.bosses), int(result.elites), float(result.damage), bool(result.victory), float(result.multiplier))
	if result.victory:
		SaveManager.complete_phase(str(config.map), int(config.phase), int(config.tier))
	result["items"] = items
	if is_instance_valid(game):
		game.show_coop_result(result, gold)

func return_lobby() -> void:
	if hosting:
		_lobby.rpc()

@rpc("authority", "call_local", "reliable")
func _lobby() -> void:
	running = false
	game = null
	lobby_requested.emit()
	# Refresh equipment, talent progression and stats before the next expedition.
	local_profile = profile(str(local_profile.name), str(local_profile.class))
	if hosting:
		players[1] = local_profile
		_sync_lobby.rpc(players, config)
	else:
		_register.rpc_id(1, local_profile)

func _peer_left(id: int) -> void:
	if not hosting:
		return
	players.erase(id)
	ready_peers.erase(id)
	inputs.erase(id)
	input_times.erase(id)
	if running and is_instance_valid(game):
		game.remove_peer(id)
		if not game.started:
			_mark_ready(1)
	else:
		_sync_lobby.rpc(players, config)
	changed.emit()

func close(reason: String = "Sala encerrada.") -> void:
	get_tree().paused = false
	active = false
	hosting = false
	running = false
	pending_since = 0
	game = null
	players.clear()
	inputs.clear()
	ready_peers.clear()
	input_buffers.clear()
	test_deliveries.clear()
	pending_world_batches.clear()
	world_batch_cursor = 0
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	status = reason
	changed.emit()
	session_closed.emit(reason)
