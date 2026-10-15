extends ExpeditionGame
var host_world: Node
var peer_id := 0
var level_rewards := 0
var ability_uses: Dictionary = {}

func _ready() -> void:
	online_remote = true
	map_data = host_world.map_data
	map_id = host_world.map_id
	phase_number = host_world.phase_number
	difficulty_tier = host_world.difficulty_tier
	wave_director = host_world.wave_director
	enemy_manager = host_world.enemy_manager
	phase_director = host_world.phase_director
	player = PLAYER_SCRIPT.new()
	player.configure(player_class, {})
	player.equipped_weapon_id = str(NetworkSession.players[peer_id].get("weapon", player.equipped_weapon_id))
	player.use_local_input = false
	var stats: Dictionary = NetworkSession.players[peer_id].stats
	for key in NetworkSession.PLAYER_STATS:
		player.set(key, stats[key])
	for key in player.base_run_stats:
		player.base_run_stats[key] = player.get(key)
	player.health = player.max_health
	player.position = Vector2.from_angle(peer_id % 4 * TAU / 4) * 60
	player.z_index = 5
	add_child(player)
	var collision := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 12
	collision.shape = circle
	player.add_child(collision)
	var label := Label.new()
	label.text = str(NetworkSession.players[peer_id].name)
	label.position = Vector2(-65, -65)
	label.size = Vector2(130, 20)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", Color("#baffdd"))
	player.add_child(label)
	experience = host_world.experience
	abilities = AbilityManager.new()
	add_child(abilities)
	player.net_peer_id = peer_id
	player.damaged.connect(_on_player_damaged)
	player.died.connect(_on_player_died)
	abilities.reset(player.class_data.starting_ability, player_class, difficulty_tier)
	_apply_starting_ability()
	set_process(false)
	player.set_physics_process(false)

func _process(delta: float) -> void:
	if not player.is_dead:
		enemy_manager.damage_source = player
		super._process(delta)
		enemy_manager.damage_source = null

func _on_level_up(value: int) -> void:
	abilities.expedition_level = value
	player.level = value
	player.rebuild_run_stats(abilities.accumulated_bonuses())
	player.heal(player.max_health * 0.03)
	level_rewards += 1
	pending_levelups += 1
	if pending_levelups == 1:
		host_world.offer_choice(peer_id)

func _update_boss_hud() -> void:
	pass

func _record_ability_use(id: String) -> void:
	ability_uses[id] = int(ability_uses.get(id, 0)) + 1

func _show_notice(_message: String) -> void:
	pass

func _finish_run(_victory: bool) -> void:
	host_world.check_party()

func _unhandled_input(_event: InputEvent) -> void:
	pass
