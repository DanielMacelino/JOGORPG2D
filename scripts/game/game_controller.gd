extends Node2D
class_name ExpeditionGame
const STYLE := preload("res://scripts/ui/wild_theme.gd")

signal return_to_menu
signal restart_requested
signal next_stage_requested

const PLAYER_SCRIPT := preload("res://scripts/world/player.gd")
const GROUND_SCRIPT := preload("res://scripts/world/forest_ground.gd")
const PROJECTILE_SCRIPT := preload("res://scripts/world/projectile.gd")
const ORB_SCRIPT := preload("res://scripts/world/xp_orb.gd")
const GOLD_ORB_SCRIPT := preload("res://scripts/world/gold_orb.gd")
const SKILL_EFFECT_SCRIPT := preload("res://scripts/world/skill_effect.gd")
const REWARD_PANEL_SCRIPT := preload("res://scripts/ui/run_reward_panel.gd")
const RESULT_VIEWPORT_SCRIPT := preload("res://scripts/ui/result_viewport.gd")
const BURST_SCRIPT := preload("res://scripts/world/burst_effect.gd")
const TELEGRAPH_SCRIPT := preload("res://scripts/world/telegraph.gd")
const AMBIENCE_SCRIPT := preload("res://scripts/world/forest_ambience.gd")
const LIGHTNING_SCRIPT := preload("res://scripts/world/lightning_arc.gd")
const LEVEL_HEADER_SCRIPT := preload("res://scripts/ui/level_up_header.gd")
const LEVEL_CARD_SCRIPT := preload("res://scripts/ui/level_choice_card.gd")
const COMPANION_SCRIPT := preload("res://scripts/world/forest_companion.gd")
const GOLD := Color("#c6aa72")
const MINT := Color("#91ad8a")

var player_class := "warrior"
var online_remote := false
var map_id := "verdant_reach"
var phase_number := 1
var difficulty_tier := 0
var power_clock := 3.0
var summon_clock := 1.0
var taunt_clock := 0.5
var starting_character_level := 1
var map_data: MapData
var player: SurvivorPlayer
var camera: Camera2D
var camera_tween: Tween
var wave_director: WaveDirector
var enemy_manager: EnemyManager
var experience: ExperienceManager
var abilities: AbilityManager
var loot: LootManager
var phase_director: Node
var objective_label: Label
var ui_layer: CanvasLayer
var ui_root: Control
var joystick: Control
var health_bar: ProgressBar
var xp_bar: ProgressBar
var health_text: Label
var xp_text: Label
var wave_label: Label
var timer_label: Label
var combo_label: Label
var gold_label: Label
var skill_label: Label
var skill_rail: HFlowContainer
var skill_rail_signature := ""
var boss_panel: VBoxContainer
var boss_bar: ProgressBar
var boss_name_label: Label
var pause_layer: Control
var level_layer: Control
var result_layer: Control
var attack_clock := 0.0
var special_clocks: Dictionary = {"ember_orb": 2.0, "thorn_aura": 0.0, "storm_arc": 2.0, "starfall": 3.0, "blade_storm": 1.0, "time_warp": 2.0, "void_rift": 3.0, "challenge_shout": 1.0, "glacial_ring": 1.0, "volley": 1.0, "shadow_burst": 1.0, "ancient_guardian": 1.0, "roots_snare": 1.0, "sunfire": 1.0}
var pending_levelups := 0
var pending_level_equipment: Array[String] = []
var enemies_defeated := 0
var bosses_defeated := 0
var elites_defeated := 0
var kill_chain := 0
var best_chain := 0
var chain_clock := 0.0
var pickup_burst_clock := 0.0
var hud_clock := 0.0
var phoenix_used := false
var defeated_boss_name := ""
var run_gold := 0
var run_finished := false
var boss: ChaserEnemy
var reward: Dictionary = {}
var reward_banked := false
var boss_music_active := false
var run_items: Array[Dictionary] = []
var attack_count := 0
var notice_label: Label
var modal_panels: Array[PanelContainer] = []
var hud_layout_dirty := false

func _ready() -> void:
	get_viewport().size_changed.connect(_on_viewport_resized)
	map_data = CampaignRules.expedition(map_id, phase_number, difficulty_tier)
	starting_character_level = TalentManager.character_level(player_class)
	_build_world()
	_build_systems()
	_build_hud()
	_connect_systems()
	abilities.reset(player.class_data.starting_ability, player_class, difficulty_tier)
	_apply_starting_ability()
	wave_director.start()

func _build_world() -> void:
	var ground := GROUND_SCRIPT.new()
	ground.configure(map_data.theme)
	ground.z_index = -20
	add_child(ground)
	var ambience := AMBIENCE_SCRIPT.new() as Node2D
	ambience.call("configure", map_data.theme)
	ambience.z_index = -10
	add_child(ambience)
	player = PLAYER_SCRIPT.new() as SurvivorPlayer
	player.configure(player_class, {})
	player.position = Vector2.ZERO
	player.z_index = 5
	add_child(player)
	var player_shape := CollisionShape2D.new()
	var player_circle := CircleShape2D.new()
	player_circle.radius = 12.0
	player_shape.shape = player_circle
	player.add_child(player_shape)
	camera = Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.0
	camera.limit_left = -1275
	camera.limit_right = 1275
	camera.limit_top = -905
	camera.limit_bottom = 905
	player.add_child(camera)
	camera.make_current()

func _build_systems() -> void:
	wave_director = WaveDirector.new()
	wave_director.configure(map_data)
	wave_director.name = "WaveDirector"
	add_child(wave_director)
	enemy_manager = EnemyManager.new()
	enemy_manager.name = "EnemyManager"
	enemy_manager.configure(self, player, map_data)
	add_child(enemy_manager)
	experience = ExperienceManager.new()
	experience.name = "ExperienceManager"
	add_child(experience)
	abilities = AbilityManager.new()
	abilities.name = "AbilityManager"
	add_child(abilities)
	loot = LootManager.new()
	loot.name = "LootManager"
	add_child(loot)
	phase_director = preload("res://scripts/systems/phase_director.gd").new()
	phase_director.configure(self, map_data)
	phase_director.completed.connect(_on_objective_complete)
	phase_director.failed.connect(func() -> void: _show_notice("O ALTAR FOI DESTRUÍDO"); _finish_run(false))
	add_child(phase_director)

func _connect_systems() -> void:
	wave_director.wave_changed.connect(_on_wave_changed)
	wave_director.spawn_requested.connect(_on_spawn_requested)
	wave_director.boss_summoned.connect(_on_boss_summoned)
	enemy_manager.enemy_died.connect(_on_enemy_died)
	enemy_manager.player_hit.connect(_on_player_hit)
	enemy_manager.enemy_shot.connect(_on_enemy_shot)
	enemy_manager.boss_attack.connect(_on_boss_attack)
	enemy_manager.boss_pattern.connect(_on_boss_pattern)
	enemy_manager.boss_enraged.connect(_on_boss_enraged)
	enemy_manager.enemy_spell.connect(_on_enemy_spell)
	enemy_manager.damage_dealt.connect(player.record_damage)
	experience.changed.connect(_on_experience_changed)
	experience.level_up.connect(_on_level_up)
	abilities.loadout_changed.connect(_refresh_skill_list)
	player.stats_changed.connect(_refresh_hud)
	player.died.connect(_on_player_died)
	player.damaged.connect(_on_player_damaged)

func _process(delta: float) -> void:
	if run_finished:
		return
	chain_clock = maxf(0.0, chain_clock - delta)
	if chain_clock <= 0.0:
		kill_chain = 0
	pickup_burst_clock = maxf(0.0, pickup_burst_clock - delta)
	if joystick != null and is_instance_valid(joystick):
		var joystick_value: Vector2 = joystick.get("value")
		player.set_virtual_direction(joystick_value)
	attack_clock -= delta
	if attack_clock <= 0.0:
		_try_basic_attack()
	if player_class == "druid":
		summon_clock -= delta
		if summon_clock <= 0.0:
			summon_clock = 18.0
			_summon_companions("wolf", 2 + player.summon_count, 14.0 + player.summon_duration)
	if player_class == "warrior":
		taunt_clock -= delta
		if taunt_clock <= 0.0:
			taunt_clock = 6.0
			_provoke_enemies(460.0, 3.5)
	for id in special_clocks.keys():
		var rank := abilities.level_of(StringName(id))
		if rank <= 0:
			continue
		special_clocks[id] = float(special_clocks.get(id, 0.0)) - delta
		if float(special_clocks[id]) <= 0.0:
			_cast_special(id, rank)
	if player.class_power:
		power_clock -= delta
		if power_clock <= 0.0:
			_cast_class_power()
	hud_clock -= delta
	if hud_clock <= 0.0:
		hud_clock = 0.1
		_update_hud()
		_update_boss_hud()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not run_finished:
		_toggle_pause()

func _build_hud() -> void:
	if ui_layer != null and is_instance_valid(ui_layer):
		ui_layer.queue_free()
	notice_label = null
	var layer := CanvasLayer.new()
	layer.layer = 20
	ui_layer = layer
	add_child(ui_layer)
	ui_root = Control.new()
	ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_root.mouse_filter = Control.MOUSE_FILTER_PASS
	ui_root.process_mode = Node.PROCESS_MODE_ALWAYS
	ui_root.scale = Vector2.ONE
	layer.add_child(ui_root)
	ui_root.theme = STYLE.create_theme()
	skill_rail = HFlowContainer.new()
	skill_rail.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	skill_rail.offset_left = -210
	skill_rail.offset_right = -14
	skill_rail.offset_top = 124 if get_viewport_rect().size.x >= 720 else 174
	skill_rail.offset_bottom = skill_rail.offset_top + 65
	skill_rail.add_theme_constant_override("h_separation", 4)
	skill_rail.add_theme_constant_override("v_separation", 4)
	ui_root.add_child(skill_rail)
	skill_rail_signature = ""
	var vignette := ColorRect.new()
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var atmosphere := ShaderMaterial.new()
	atmosphere.shader = preload("res://scripts/ui/world_vignette.gdshader")
	vignette.material = atmosphere
	ui_root.add_child(vignette)
	var mobile_layout := get_viewport_rect().size.x < 820.0
	var top: Control = VBoxContainer.new() if mobile_layout else HBoxContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 12 if mobile_layout else 18
	top.offset_top = 12 if mobile_layout else 16
	top.offset_right = -12 if mobile_layout else -18
	top.offset_bottom = 111 if mobile_layout else 103
	top.add_theme_constant_override("separation", 5 if mobile_layout else 12)
	ui_root.add_child(top)
	var row: HBoxContainer = HBoxContainer.new() if mobile_layout else top as HBoxContainer
	row.add_theme_constant_override("separation", 8)
	if mobile_layout:
		top.add_child(row)
	var main_row := row
	var left := _ui_panel(main_row, Vector2(190 if get_viewport_rect().size.x >= 370 else 144, 64) if mobile_layout else Vector2(310, 78))
	var vitals_style := left.get_theme_stylebox("panel") as StyleBoxFlat
	vitals_style.border_color = Color(GOLD, 0.62)
	left.name = "BattleVitals"
	var vitals_row := HBoxContainer.new()
	vitals_row.add_theme_constant_override("separation", 8 if not mobile_layout else 5)
	left.add_child(_pad(vitals_row, 8 if mobile_layout else 12, 5 if mobile_layout else 8, 8 if mobile_layout else 12, 5 if mobile_layout else 8))
	if get_viewport_rect().size.x >= 370:
		var portrait := preload("res://scripts/ui/battle_portrait.gd").new()
		portrait.name = "BattlePortrait"
		portrait.class_id = player_class
		portrait.custom_minimum_size = Vector2(38, 52) if mobile_layout else Vector2(58, 64)
		vitals_row.add_child(portrait)
	var stats := VBoxContainer.new()
	stats.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats.add_theme_constant_override("separation", 3 if mobile_layout else 4)
	vitals_row.add_child(stats)
	health_text = _ui_label(stats, "VIDA   100 / 100", 10 if mobile_layout else 12, Color("#f0d8c2"))
	health_bar = _progress(stats, Color("#e9232c"), 10 if mobile_layout else 13)
	xp_text = _ui_label(stats, "NV 1   ·   0 / 20 XP", 9 if mobile_layout else 11, Color("#c4d8cb"))
	xp_bar = _progress(stats, Color("#91c99c"), 5 if mobile_layout else 6)
	for label in [health_text, xp_text]:
		label.autowrap_mode = TextServer.AUTOWRAP_OFF
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		label.clip_text = true
		label.custom_minimum_size.x = 0
	var center := VBoxContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_theme_constant_override("separation", 2)
	main_row.add_child(center)
	wave_label = _ui_label(center, "ONDA 01", 17 if mobile_layout else 21, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	timer_label = _ui_label(center, "00:00", 10 if mobile_layout else 12, Color("#b9c9be"), HORIZONTAL_ALIGNMENT_CENTER)
	combo_label = _ui_label(center, "0 ABATES", 9 if mobile_layout else 11, MINT, HORIZONTAL_ALIGNMENT_CENTER)
	var right: Control = HBoxContainer.new() if mobile_layout else VBoxContainer.new()
	right.add_theme_constant_override("separation", 5)
	if not mobile_layout:
		right.custom_minimum_size.x = 190
		main_row.add_child(right)
		gold_label = _ui_label(right, "◈  0", 15, Color("#f0d178"), HORIZONTAL_ALIGNMENT_RIGHT)
		skill_label = _ui_label(right, "✦  %s" % _class_ability_name(), 11, Color("#c5d6ca"), HORIZONTAL_ALIGNMENT_RIGHT)
	else:
		top.add_child(right)
		gold_label = _ui_label(right, "◈  0", 13, Color("#f0d178"))
		skill_label = _ui_label(right, "✦  %s" % _class_ability_name(), 10, Color("#c5d6ca"))
	skill_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var pause := _ui_button(main_row, "Ⅱ" if mobile_layout else "Ⅱ   PAUSAR", _toggle_pause, false, 34)
	pause.custom_minimum_size.x = 48 if mobile_layout else 110
	pause.size_flags_horizontal = Control.SIZE_SHRINK_END
	pause.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	boss_panel = VBoxContainer.new()
	boss_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	boss_panel.anchor_left = 0.22
	boss_panel.anchor_right = 0.78
	boss_panel.offset_top = 118 if mobile_layout else 111
	boss_panel.offset_bottom = 166 if mobile_layout else 163
	boss_panel.add_theme_constant_override("separation", 4)
	ui_root.add_child(boss_panel)
	boss_name_label = _ui_label(boss_panel, "REI DO ESPINHEIRO", 12, Color("#ffc377"), HORIZONTAL_ALIGNMENT_CENTER)
	boss_bar = _progress(boss_panel, Color("#de6470"), 15)
	boss_panel.hide()
	var bottom_hint := _ui_label(ui_root, "%s · FASE %02d/10 · %s · PERSONAGEM NV %d" % [map_data.display_name.to_upper(), phase_number, CampaignRules.difficulty_name(difficulty_tier).to_upper(), player.character_level], 10, Color(0.79, 0.86, 0.79, 0.58), HORIZONTAL_ALIGNMENT_CENTER)
	bottom_hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom_hint.offset_top = -30
	bottom_hint.offset_bottom = -12
	objective_label = _ui_label(ui_root, phase_director.status(), 11, Color("#f0deb8"), HORIZONTAL_ALIGNMENT_CENTER)
	objective_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	objective_label.offset_left = 20
	objective_label.offset_right = -20
	objective_label.offset_top = -79
	objective_label.offset_bottom = -37
	if OS.has_feature("mobile"):
		var joystick_script := load("res://scripts/ui/virtual_joystick.gd") as Script
		joystick = joystick_script.new() as Control
		joystick.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
		joystick.offset_left = 14
		joystick.offset_top = -190
		joystick.offset_right = 184
		joystick.offset_bottom = -20
		ui_root.add_child(joystick)
		bottom_hint.hide()
		objective_label.offset_left = 205
		objective_label.offset_top = -130

func _update_hud() -> void:
	if health_bar == null:
		return
	health_bar.max_value = player.max_health
	health_bar.value = player.health
	health_text.text = "VIDA   %d / %d" % [roundi(player.health), roundi(player.max_health)]
	xp_bar.max_value = experience.required_xp
	xp_bar.value = experience.current_xp
	xp_text.text = "NÍVEL %02d   ·   %d / %d XP" % [experience.level, experience.current_xp, experience.required_xp]
	if get_viewport_rect().size.x < 820:
		health_text.text = "VIDA %d/%d" % [roundi(player.health), roundi(player.max_health)]
		xp_text.text = "NV %02d · %d/%d XP" % [experience.level, experience.current_xp, experience.required_xp]
	gold_label.text = "◈  %d" % run_gold
	for label in [wave_label, timer_label, combo_label]: label.visible = not is_instance_valid(level_layer)
	var compact_choice := is_instance_valid(level_layer) and get_viewport_rect().size.x < 820
	gold_label.visible = not compact_choice
	skill_label.visible = not compact_choice
	if objective_label != null and phase_director != null:
		objective_label.text = phase_director.status()
	combo_label.text = "%d ABATES%s" % [enemies_defeated, "   ·   CADEIA %d" % kill_chain if kill_chain >= 5 else ""]
	if wave_director != null:
		wave_label.text = "ONDA %02d" % wave_director.wave
		timer_label.text = _format_time(wave_director.match_time)

func _refresh_hud() -> void:
	_update_hud()

func _refresh_skill_list() -> void:
	if skill_label == null:
		return
	var signature := JSON.stringify(abilities.levels)
	if is_instance_valid(skill_rail) and signature != skill_rail_signature:
		skill_rail_signature = signature
		for badge in skill_rail.get_children(): badge.queue_free()
		for id in abilities.levels:
			var badge := preload("res://scripts/ui/ability_badge.gd").new()
			badge.ability_id = str(id)
			badge.rank = abilities.level_of(StringName(id))
			skill_rail.add_child(badge)
	var parts: PackedStringArray = []
	for id in abilities.levels:
		var data: AbilityData = ContentCatalog.abilities.get(str(id))
		if data != null:
			parts.append("%s %d" % [data.display_name, abilities.level_of(id)])
	skill_label.text = "✦  %s  ·  %d/3 PODERES  ·  %d MELHORIAS" % [_class_ability_name(), abilities.active_power_count(), parts.size()]
	skill_label.max_lines_visible = 2
	skill_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	skill_label.tooltip_text = "\n".join(parts)

func _update_boss_hud() -> void:
	if is_instance_valid(level_layer):
		boss_panel.hide()
		return
	if boss != null and is_instance_valid(boss) and not boss.dead:
		boss_panel.show()
		boss_bar.max_value = boss.max_health
		boss_bar.value = boss.health
	else:
		boss_panel.hide()

func _on_wave_changed(wave: int) -> void:
	AudioManager.feedback("wave")
	wave_label.text = "ONDA %02d" % wave
	_show_notice("ONDA %02d   ·   %s" % [wave, _wave_epithet(wave)])

func _on_spawn_requested(kind: StringName, wave: int) -> void:
	enemy_manager.spawn(kind, wave)

func _on_boss_summoned(boss_id: StringName) -> void:
	boss = enemy_manager.spawn_boss(boss_id, wave_director.wave)
	boss_name_label.text = boss.data.display_name.to_upper()
	_set_boss_music(true)
	_spawn_skill(boss.global_position, "void", 110.0, Color("#ffd08e"))
	_show_notice("O GUARDIÃO DESPERTA   ·   " + boss.data.display_name.to_upper())

func _on_enemy_died(enemy: ChaserEnemy) -> void:
	if run_finished:
		return
	enemies_defeated += 1
	_record_kill(str(enemy.kind))
	if enemy.data.elite:
		elites_defeated += 1
	kill_chain += 1
	best_chain = maxi(best_chain, kill_chain)
	chain_clock = 6.0
	if is_instance_valid(enemy.data) and enemy.data.boss:
		_set_boss_music(false)
		AudioManager.feedback("boss")
		defeated_boss_name = enemy.data.display_name
		bosses_defeated += 1
		var result := loot.roll_boss_reward(map_id, player_class, phase_number, null, difficulty_tier)
		result.gold = roundi(int(result.gold) * CampaignRules.reward_multiplier(difficulty_tier, phase_number))
		reward = result
		if phase_director == null or phase_director.objective_complete():
			_finish_run(true)
		else:
			_show_notice("CHEFE DERROTADO · CONCLUA O OBJETIVO PARA RECEBER O DROP")
		return
	AudioManager.feedback("kill")
	if kill_chain == 10 or kill_chain % 25 == 0:
		var chain_bonus := 5 if kill_chain == 10 else 12
		run_gold += chain_bonus
		experience.add_experience(chain_bonus)
		_show_notice("CADEIA DE %d   ·   +%d OURO E XP" % [kill_chain, chain_bonus])
	if enemies_defeated % 2 == 0 or enemy.data.elite:
		_spawn_burst(enemy.global_position, 26.0 if not enemy.data.elite else 44.0, Color("#e4d29d"))
	var earned_gold := maxi(1, roundi(enemy.gold_reward * (1.0 + player.bonus_gold_xp) * CampaignRules.reward_multiplier(difficulty_tier, phase_number)))
	if get_tree().get_nodes_in_group("gold_drop").size() >= 150:
		_on_gold_collected(earned_gold)
	else:
		_spawn_gold_drop(enemy, earned_gold)
	if get_tree().get_nodes_in_group("xp_drop").size() >= 150:
		_on_orb_collected(roundi(enemy.xp_reward * (1.0 + player.bonus_gold_xp + player.bonus_xp_only) * CampaignRules.reward_multiplier(difficulty_tier, phase_number)))
	else:
		_spawn_xp_drop(enemy)
	if randf() < 0.025:
		_spawn_burst(enemy.global_position, 19.0, Color("#84e4b4"))
		player.heal(player.max_health * 0.012)
	if phase_director != null:
		phase_director.record_enemy(enemy)

func _on_objective_complete() -> void:
	_show_notice("OBJETIVO CONCLUÍDO")
	if bosses_defeated > 0:
		_finish_run(true)

func _on_boss_enraged() -> void:
	if is_instance_valid(boss):
		var brain := boss.get_node("BossBrain")
		boss_name_label.text = boss.data.display_name.to_upper() + (" · FÚRIA FINAL" if brain.final_phase else " · FÚRIA")
		_show_notice("FÚRIA FINAL · A SOBREVIVÊNCIA SERÁ POSTA À PROVA" if brain.final_phase else "SEGUNDA ETAPA · O GUARDIÃO DESPERTA SUA FÚRIA")

func _on_boss_pattern(spec: Dictionary) -> void:
	if get_tree().get_nodes_in_group("danger_area").size() >= 36:
		return
	var pattern := preload("res://scripts/world/boss_pattern.gd").new()
	pattern.spec = spec.duplicate()
	pattern.position = spec.get("position", Vector2.ZERO)
	pattern.volley_requested.connect(_on_enemy_shot)
	add_child(pattern)

func _spawn_gold_drop(enemy: ChaserEnemy, earned_gold: int) -> void:
	var gold_orb := GOLD_ORB_SCRIPT.new()
	gold_orb.player = player
	gold_orb.value = earned_gold
	gold_orb.global_position = enemy.global_position + Vector2(randf_range(-9.0, 9.0), randf_range(-8.0, 8.0))
	gold_orb.collected.connect(_on_gold_collected)
	add_child(gold_orb)

func _spawn_xp_drop(enemy: ChaserEnemy) -> void:
	var orb := ORB_SCRIPT.new()
	orb.player = player
	orb.value = enemy.xp_reward
	orb.bonus = (1.0 + player.bonus_gold_xp + player.bonus_xp_only) * CampaignRules.reward_multiplier(difficulty_tier, phase_number) - 1.0
	orb.global_position = enemy.global_position
	orb.collected.connect(_on_orb_collected)
	add_child(orb)

func _set_boss_music(enabled: bool) -> void:
	if online_remote:
		return
	boss_music_active = enabled
	AudioManager.boss_music(enabled)

func _exit_tree() -> void:
	if not online_remote:
		AudioManager.boss_music(false)

func _spawn_skill(at: Vector2, kind: String, radius: float, color: Color, direction := Vector2.RIGHT) -> void:
	if get_tree().get_nodes_in_group("skill_effect").size() >= 24:
		return
	var effect := SKILL_EFFECT_SCRIPT.new()
	effect.kind = kind
	effect.radius = radius
	effect.color = color
	effect.direction = direction
	effect.position = at
	add_child(effect)

func _animate_skill(id: String, rank: int, target: Vector2) -> void:
	var styles := {"challenge_shout": "taunt", "glacial_ring": "frost", "roots_snare": "roots", "sunfire": "holy", "volley": "arrows", "shadow_burst": "shadow", "ancient_guardian": "summon", "ember_orb": "fire", "thorn_aura": "roots", "storm_arc": "arcane", "starfall": "starfall", "blade_storm": "blades", "time_warp": "time", "void_rift": "void"}
	var colors := {"frost": Color("#a4f1ff"), "roots": Color("#a1ffa9"), "holy": Color("#ffe2a1"), "arrows": Color("#eaffaf"), "shadow": Color("#e3aaff"), "summon": Color("#96ffd1"), "fire": Color("#ffb278"), "blades": Color("#fff1c9"), "void": Color("#c1a0ff"), "time": Color("#a4e2ef"), "taunt": Color("#ffce87"), "starfall": Color("#d9a8ff"), "arcane": Color("#a4e6ff")}
	var kind: String = styles.get(id, "arcane")
	var radius: float = {"glacial_ring": 115.0 + rank * 15.0, "roots_snare": 115.0 + rank * 15.0, "sunfire": 115.0 + rank * 15.0, "thorn_aura": 102.0 + rank * 7.0, "blade_storm": 150.0 + rank * 8.0, "void_rift": 210.0 + rank * 14.0, "time_warp": 220.0}.get(id, 95.0)
	var center := target if id in ["glacial_ring", "starfall"] else player.global_position
	var direction := (target - player.global_position).normalized()
	if id != "thorn_aura":
		player.play_attack(direction, false, player.class_data.attack_style)
	_spawn_skill(center, kind, radius, colors[kind], direction)

func _spawn_burst(at: Vector2, radius: float, color: Color) -> void:
	if get_tree().get_nodes_in_group("combat_burst").size() >= 18:
		return
	var burst := BURST_SCRIPT.new()
	burst.radius = radius
	burst.color = color
	burst.global_position = at
	add_child(burst)
	burst.add_to_group("combat_burst")

func _on_orb_collected(amount: int) -> void:
	experience.add_experience(amount)
	AudioManager.feedback("xp")
	if pickup_burst_clock <= 0.0:
		pickup_burst_clock = 0.18
		_spawn_burst(player.global_position, 19.0, Color("#73e7ca"))

func _on_gold_collected(amount: int) -> void:
	run_gold += amount
	_update_hud()

func _on_player_hit(amount: float, _position: Vector2, victim: SurvivorPlayer = null) -> void:
	var target := victim if is_instance_valid(victim) else player
	target.take_damage(amount)

func _on_player_damaged(_amount: float) -> void:
	if player.thorns > 0.0 and not player.is_dead:
		for enemy in _nearest_enemies(player.global_position, 150.0, 12):
			enemy.take_hit(_amount * player.thorns)
	var flash := BURST_SCRIPT.new()
	flash.radius = 34.0
	flash.color = Color("#ef7776")
	flash.global_position = player.global_position
	add_child(flash)
	var frost_rank := abilities.level_of(&"frost_nova")
	if frost_rank > 0:
		for enemy in _nearest_enemies(player.global_position, 145.0 + frost_rank * 9.0, 18):
			enemy.apply_slow(0.7, 1.4 + frost_rank * 0.15)
		_spawn_skill(player.global_position, "frost", 145.0 + frost_rank * 9.0, Color("#9ddbe4"))
	if camera != null:
		if camera_tween != null and camera_tween.is_running():
			camera_tween.kill()
		camera_tween = create_tween()
		camera_tween.tween_method(_set_camera_shake, 8.0, 0.0, 0.24)
		camera_tween.tween_callback(func() -> void: camera.offset = Vector2.ZERO)

func _set_camera_shake(strength: float) -> void:
	if camera != null:
		camera.offset = Vector2(randf_range(-strength, strength), randf_range(-strength, strength) * 0.72)

func _on_enemy_shot(position: Vector2, direction: Vector2, amount: float, color: Color, victim: SurvivorPlayer = null) -> void:
	if get_tree().get_nodes_in_group("hostile_projectile").size() >= 48:
		return
	var projectile := PROJECTILE_SCRIPT.new()
	projectile.player_team = false
	projectile.player = victim if is_instance_valid(victim) else player
	projectile.position = position
	projectile.direction = direction
	projectile.speed = 285.0
	projectile.damage = amount
	projectile.magic = true
	projectile.color = color.lerp(Color("#ff986e"), 0.55)
	add_child(projectile)

func _on_boss_attack(position: Vector2, radius: float, amount: float, victim: SurvivorPlayer = null) -> void:
	var area := TELEGRAPH_SCRIPT.new()
	area.player = victim if is_instance_valid(victim) else player
	area.global_position = position
	area.radius = radius
	area.damage = amount
	add_child(area)
	area.add_to_group("danger_area")

func _on_enemy_spell(position: Vector2, radius: float, amount: float, victim: SurvivorPlayer = null) -> void:
	if get_tree().get_nodes_in_group("danger_area").size() >= 18:
		return
	var area := TELEGRAPH_SCRIPT.new()
	area.player = victim if is_instance_valid(victim) else player
	area.global_position = position
	area.radius = radius
	area.damage = amount
	area.lingering = true
	add_child(area)
	area.add_to_group("danger_area")

func _on_level_up(_level: int) -> void:
	abilities.expedition_level = _level
	AudioManager.feedback("level")
	player.level = _level
	player.rebuild_run_stats(abilities.accumulated_bonuses())
	player.heal(player.max_health * 0.03)
	pending_levelups += 1
	var item_id := EquipmentManager.unlock_next_class_item(player_class, map_id, difficulty_tier)
	if item_id.is_empty():
		SaveManager.grant_gold(30)
		pending_level_equipment.append("")
	else:
		pending_level_equipment.append(item_id)
		run_items.append({"id": item_id, "source": "level", "duplicate": false})
	if pending_levelups == 1:
		_show_level_choices()

func _on_experience_changed(_level: int, _current: int, _required: int) -> void:
	_update_hud()

func _apply_starting_ability() -> void:
	player.rebuild_run_stats(abilities.accumulated_bonuses())
	_refresh_skill_list()

func _try_basic_attack() -> void:
	var targets := _nearest_enemies(player.global_position, player.attack_range, 1)
	if targets.is_empty():
		attack_clock = 0.12
		return
	attack_count += 1
	attack_clock = player.attack_cooldown
	var target: ChaserEnemy = targets[0]
	var direction: Vector2 = (target.global_position - player.global_position).normalized()
	player.facing = direction
	var critical: bool = randf() < player.crit_chance
	var attack_damage: float = player.damage * (player.crit_multiplier if critical else 1.0)
	var fury_rank := abilities.level_of(&"berserker")
	attack_damage *= 1.0 + minf(1.0, (1.0 - player.health / maxf(player.max_health, 1.0)) * 1.25) * 0.25 * fury_rank
	if randf() < minf(1.0, abilities.level_of(&"echo_strike") * 0.2):
		attack_damage *= 2.0
	if abilities.level_of(&"echo_strike") > 0:
		_record_ability_use("echo_strike")
	player.play_attack(direction, critical, player.class_data.attack_style)
	if player.class_data.attack_style == &"melee":
		var max_targets := 3 + player.cleave_targets + floori(float(abilities.level_of(&"keen_edge")) / 2.0)
		var nearby := _nearest_enemies(player.global_position, maxf(112.0, player.attack_range + 12.0), max_targets)
		for enemy in nearby:
			var to_enemy: Vector2 = (enemy.global_position - player.global_position).normalized()
			if direction.dot(to_enemy) > -0.25:
				enemy.take_hit(attack_damage * (1.0 if enemy == target else 0.88), critical and enemy == target)
				if not enemy.dead:
					enemy.apply_burn(attack_damage * player.burn_on_hit, 3.0)
					if player.chill_on_hit > 0.0:
						enemy.apply_slow(player.chill_on_hit, 2.0)
		_spawn_burst(player.position + direction * 32.0, 60.0, Color("#f7d590"))
	else:
		var projectile := PROJECTILE_SCRIPT.new()
		projectile.player_team = true
		projectile.enemies = enemy_manager.enemies
		projectile.enemy_manager = enemy_manager
		projectile.position = player.global_position + direction * 20.0
		projectile.direction = direction
		projectile.speed = player.projectile_speed
		projectile.damage = attack_damage
		projectile.magic = player.class_data.attack_style == &"magic"
		projectile.splash_radius = player.class_data.splash_radius + player.splash_bonus if projectile.magic else 0.0
		projectile.pierce_left = player.projectile_pierce + (0 if projectile.magic else 1)
		projectile.critical = critical
		projectile.color = player.tint.lightened(0.25)
		projectile.rng.randomize()
		add_child(projectile)
		if player.class_data.attack_style == &"ranged" and attack_count % 3 == 0:
			var side_projectile := PROJECTILE_SCRIPT.new()
			side_projectile.player_team = true
			side_projectile.enemies = enemy_manager.enemies
			side_projectile.enemy_manager = enemy_manager
			side_projectile.position = player.global_position + direction.rotated(0.13) * 19.0
			side_projectile.direction = direction.rotated(0.13)
			side_projectile.speed = player.projectile_speed
			side_projectile.damage = attack_damage * 0.65
			side_projectile.pierce_left = 1 + player.projectile_pierce
			side_projectile.color = Color("#dbe3bd")
			add_child(side_projectile)

func _cast_class_power() -> void:
	var targets := _nearest_enemies(player.global_position, 300.0, 24)
	if targets.is_empty():
		power_clock = 0.5
		return
	var power_kind: String = {"warrior": "taunt", "mage": "arcane", "ranger": "arrows", "assassin": "shadow", "druid": "summon", "paladin": "holy"}.get(player_class, "arcane")
	player.play_attack((targets[0].global_position - player.global_position).normalized(), true, player.class_data.attack_style)
	_spawn_skill(player.global_position, power_kind, 180.0, player.tint.lightened(0.25), player.attack_direction)
	var multiplier := 2.8
	var radius := 170.0
	power_clock = 8.0
	match player_class:
		"mage":
			multiplier = 3.0
			radius = 240.0
			power_clock = 10.0
		"ranger":
			power_clock = 7.0
			var direction: Vector2 = (targets[0].global_position - player.global_position).normalized()
			for index in 5:
				var arrow := PROJECTILE_SCRIPT.new()
				arrow.player_team = true
				arrow.enemy_manager = enemy_manager
				arrow.enemies = enemy_manager.enemies
				arrow.position = player.global_position
				arrow.direction = direction.rotated(float(index - 2) * 0.17)
				arrow.speed = player.projectile_speed * 1.2
				arrow.damage = player.damage * 2.1 * (1.0 + player.power_damage)
				arrow.pierce_left = 4 + player.projectile_pierce
				arrow.color = player.tint.lightened(0.3)
				add_child(arrow)
			_spawn_burst(player.position, 42.0, player.tint.lightened(0.35))
			return
		"assassin":
			power_clock = 7.0
			var struck := 0
			for enemy in targets:
				if not is_instance_valid(enemy) or enemy.dead:
					continue
				_spawn_burst(enemy.global_position, 34.0, player.tint.lightened(0.45))
				enemy.take_hit(player.damage * 2.3 * (1.0 + player.power_damage), true)
				struck += 1
				if struck >= 6 or run_finished:
					break
			return
		"druid":
			power_clock = 10.0
			multiplier = 2.0
			radius = 188.0
			player.heal(player.max_health * 0.20)
			_summon_companions("ancient", 1, 18.0 + player.summon_duration)
		"paladin":
			power_clock = 9.0
			multiplier = 2.6
			radius = 185.0
			player.heal(player.max_health * 0.08)
	_spawn_burst(player.global_position, radius, player.tint.lightened(0.45))
	for enemy in targets:
		if is_instance_valid(enemy) and not enemy.dead and player.global_position.distance_to(enemy.global_position) <= radius:
			enemy.take_hit(player.damage * multiplier * (1.0 + player.power_damage))
			if run_finished:
				break

func configure_projectile(projectile: Node2D) -> void:
	projectile.source_player = player
	projectile.bounces_left = player.projectile_bounces if not projectile.magic else 0
	projectile.burn_on_hit = player.burn_on_hit
	projectile.chill_on_hit = player.chill_on_hit

func _record_ability_use(id: String) -> void:
	if not online_remote:
		SaveManager.record_ability_use(id)

func _record_kill(kind: String) -> void:
	SaveManager.record_kill(kind)

func _cast_special(id: String, rank: int) -> void:
	var nearest := _nearest_enemies(player.global_position, 390.0, 4)
	if nearest.is_empty():
		special_clocks[id] = 0.5
		return
	_record_ability_use(id)
	_animate_skill(id, rank, nearest[0].global_position)
	match id:
		"challenge_shout":
			special_clocks[id] = 8.0
			_provoke_enemies(300.0 + rank * 35.0, 2.5 + rank * 0.5)
			for enemy in _nearest_enemies(player.global_position, 300.0 + rank * 35.0, 40):
				enemy.apply_slow(0.20 + rank * 0.04, 2.0 + rank * 0.25)
		"glacial_ring", "roots_snare", "sunfire":
			special_clocks[id] = 7.0 - rank * 0.4
			var center: Vector2 = nearest[0].global_position if id == "glacial_ring" else player.global_position
			var radius := 115.0 + rank * 15.0
			var amount := player.damage * (0.9 + rank * 0.28)
			var color := Color("#9bf0ff") if id == "glacial_ring" else (Color("#a5ffa4") if id == "roots_snare" else Color("#ffe0a1"))
			for enemy in _nearest_enemies(center, radius, 24):
				enemy.take_hit(amount)
				if id != "sunfire" and not enemy.dead:
					enemy.apply_slow(0.35 + rank * 0.06, 2.0 + rank * 0.2)
			_spawn_burst(center, radius, color)
		"volley":
			special_clocks[id] = 8.0 - rank * 0.5
			var direction: Vector2 = (nearest[0].global_position - player.global_position).normalized()
			for index in 3 + rank:
				var arrow := PROJECTILE_SCRIPT.new()
				arrow.player_team = true
				arrow.enemy_manager = enemy_manager
				arrow.position = player.global_position
				arrow.direction = direction.rotated((float(index) - float(2 + rank) * 0.5) * 0.12)
				arrow.speed = player.projectile_speed
				arrow.damage = player.damage * (0.65 + rank * 0.12)
				arrow.pierce_left = 1 + player.projectile_pierce
				arrow.color = Color("#eaffaf")
				add_child(arrow)
		"shadow_burst":
			special_clocks[id] = 6.0 - rank * 0.4
			for enemy in _nearest_enemies(player.global_position, 210.0, 2 + rank):
				enemy.take_hit(player.damage * (1.0 + rank * 0.25))
				_spawn_burst(enemy.global_position, 28.0, Color("#e3aaff"))
		"ancient_guardian":
			special_clocks[id] = 22.0 - rank
			_summon_companions("guardian", 1 + floori(float(rank - 1) / 2.0), 12.0 + rank * 2.0 + player.summon_duration, rank)
		"ember_orb":
			special_clocks[id] = maxf(2.1, 5.2 - rank * 0.36)
			var target: ChaserEnemy = nearest[0]
			var projectile := PROJECTILE_SCRIPT.new()
			projectile.player_team = true
			projectile.enemies = enemy_manager.enemies
			projectile.enemy_manager = enemy_manager
			projectile.position = player.global_position
			projectile.direction = (target.global_position - player.global_position).normalized()
			projectile.speed = player.projectile_speed * 0.78
			projectile.damage = player.damage * (1.15 + rank * 0.28)
			projectile.magic = true
			projectile.splash_radius = 65.0 + rank * 8.0
			projectile.color = Color("#ff985f")
			add_child(projectile)
		"thorn_aura":
			special_clocks[id] = maxf(0.35, 1.12 - rank * 0.11)
			var affected := _nearest_enemies(player.global_position, 102.0 + rank * 7.0, 12)
			for enemy in affected:
				enemy.take_hit(player.damage * (0.3 + rank * 0.13))
			var ring := BURST_SCRIPT.new()
			ring.radius = 94.0 + rank * 7.0
			ring.color = Color("#93d780")
			ring.global_position = player.global_position
			add_child(ring)
		"storm_arc":
			special_clocks[id] = maxf(2.8, 7.4 - rank * 0.65)
			var chain := _nearest_enemies(player.global_position, 430.0, 2 + rank)
			var previous: Vector2 = player.global_position
			for enemy in chain:
				enemy.take_hit(player.damage * (0.9 + rank * 0.3))
				var bolt := LIGHTNING_SCRIPT.new()
				bolt.setup(previous, enemy.global_position, Color("#8ddcff"))
				add_child(bolt)
				previous = enemy.global_position
		"starfall":
			special_clocks[id] = maxf(5.0, 10.0 - rank * 0.8)
			var target: ChaserEnemy = nearest[0]
			var comet := PROJECTILE_SCRIPT.new()
			comet.player_team = true
			comet.enemies = enemy_manager.enemies
			comet.enemy_manager = enemy_manager
			comet.position = player.global_position
			comet.direction = (target.global_position - player.global_position).normalized()
			comet.speed = player.projectile_speed * 0.62
			comet.damage = player.damage * (1.8 + rank * 0.45)
			comet.magic = true
			comet.splash_radius = 125.0 + rank * 12.0
			comet.color = Color("#d9a8ff")
			add_child(comet)
		"blade_storm":
			special_clocks[id] = maxf(1.2, 3.0 - rank * 0.25)
			for enemy in _nearest_enemies(player.global_position, 150.0 + rank * 8.0, 16):
				enemy.take_hit(player.damage * (0.8 + rank * 0.2))
			_spawn_burst(player.global_position, 150.0 + rank * 8.0, Color("#d5d7bf"))
		"time_warp":
			special_clocks[id] = maxf(6.0, 12.0 - rank)
			for enemy in enemy_manager.living_enemies():
				enemy.apply_slow(rank * 0.10, 4.0)
			_spawn_burst(player.global_position, 220.0, Color("#a4c7db"))
		"void_rift":
			special_clocks[id] = maxf(7.0, 14.0 - rank)
			var affected := _nearest_enemies(player.global_position, 210.0 + rank * 14.0, 22)
			for enemy in affected:
				if not enemy.data.boss:
					enemy.global_position = enemy.global_position.lerp(player.global_position, 0.32)
				enemy.take_hit(player.damage * (2.0 + rank * 0.45))
			_spawn_burst(player.global_position, 210.0 + rank * 14.0, Color("#b5a0c9"))

func _provoke_enemies(radius: float, duration: float) -> void:
	var found := false
	for enemy in _nearest_enemies(player.global_position, radius, 144):
		enemy.provoke(player, duration)
		found = true
	if found:
		_spawn_skill(player.global_position, "taunt", 110.0, Color("#f8c777"))

func _summon_companions(kind: String, count: int, duration: float, rank: int = 1) -> void:
	# Recasting replaces spirits of the same kind; a long duration never creates unlimited armies.
	for companion in get_tree().get_nodes_in_group("forest_companion"):
		if companion.summoner == player and companion.kind == kind:
			companion.remove_from_group("forest_companion")
			companion.queue_free()
	player.play_attack(player.facing, false, &"magic")
	_spawn_skill(player.global_position, "summon", 75.0, Color("#96ffd1"))
	for index in count:
		var companion := COMPANION_SCRIPT.new()
		companion.summoner = player
		companion.enemy_manager = enemy_manager
		companion.kind = kind
		companion.rank = rank
		companion.remaining = duration
		companion.position = player.global_position + Vector2.from_angle(float(index) * TAU / maxf(1, count)) * 44.0
		add_child(companion)

func _show_level_choices() -> void:
	if run_finished or level_layer != null:
		return
	get_tree().paused = true
	level_layer = _make_modal()
	level_layer.get_child(0).color.a = 0.42
	var screen := preload("res://scripts/ui/ability_choice_screen.gd").new()
	for ability in abilities.roll_choices(3):
		screen.choices.append(str(ability.id))
	screen.ranks = abilities.levels
	if not pending_level_equipment.is_empty():
		var reward_id := pending_level_equipment[0]
		screen.reward_text = "RELÍQUIA ENCONTRADA · " + str(ContentCatalog.equipment[reward_id].display_name) if not reward_id.is_empty() else "MOCHILA CHEIA · +30 OURO"
	screen.selected.connect(_choose_ability)
	level_layer.add_child(screen)
	_update_hud()
	_update_boss_hud()
func _choose_ability(id: StringName) -> void:
	if id != &"" and not abilities.grant(id):
		return
	var item_reward := ""
	if not pending_level_equipment.is_empty():
		item_reward = pending_level_equipment.pop_front()
	if id != &"":
		var ability: AbilityData = ContentCatalog.abilities[str(id)]
		_apply_stat_ability(ability)
		var notice := ability.display_name + "   ·   NÍVEL " + str(abilities.level_of(id))
		if not item_reward.is_empty():
			notice += "   ·   RELÍQUIA: " + str(ContentCatalog.equipment[item_reward].display_name)
		_show_notice(notice)
	elif not item_reward.is_empty():
		_show_notice("RELÍQUIA: " + str(ContentCatalog.equipment[item_reward].display_name))
	pending_levelups = maxi(0, pending_levelups - 1)
	if level_layer != null:
		level_layer.queue_free()
		level_layer = null
	get_tree().paused = false
	if pending_levelups > 0:
		_show_level_choices()
	_refresh_skill_list()
	_refresh_hud()

func _on_viewport_resized() -> void:
	for panel in modal_panels:
		if is_instance_valid(panel):
			var requested_width := float(panel.get_meta("requested_width", 0.0))
			panel.custom_minimum_size.x = maxf(0.0, minf(requested_width, get_viewport_rect().size.x - 32.0))
	if ui_root != null and pause_layer == null and result_layer == null:
		var retained_choices := level_layer if is_instance_valid(level_layer) else null
		if retained_choices != null:
			ui_root.remove_child(retained_choices)
		_build_hud()
		_update_hud()
		_update_boss_hud()
		if retained_choices != null:
			ui_root.add_child(retained_choices)
	elif ui_root != null:
		hud_layout_dirty = true

func _apply_stat_ability(ability: AbilityData) -> void:
	_spawn_skill(player.global_position, "arcane", 45.0, STYLE.RARITY_COLORS.get(str(ability.rarity), player.tint))
	var old_duration := player.summon_duration
	player.rebuild_run_stats(abilities.accumulated_bonuses())
	if ability.stat == &"health":
		player.heal(player.max_health * 0.20)
	elif ability.stat == &"heal":
		player.heal(player.max_health * ability.stat_amount)
	if player.summon_duration > old_duration:
		for companion in get_tree().get_nodes_in_group("forest_companion"):
			if companion.summoner == player:
				companion.remaining += player.summon_duration - old_duration
				companion.full_duration += player.summon_duration - old_duration
	if ability.id == &"wolf_pack":
		summon_clock = 0.0

func _toggle_pause() -> void:
	if run_finished:
		return
	if pause_layer != null:
		pause_layer.queue_free()
		pause_layer = null
		get_tree().paused = false
		if hud_layout_dirty:
			hud_layout_dirty = false
			_build_hud()
			_update_hud()
			_update_boss_hud()
		return
	get_tree().paused = true
	pause_layer = _make_modal()
	var panel := _modal_panel(pause_layer, Vector2(440, 0))
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 9)
	panel.add_child(_pad(content, 24, 22, 24, 22))
	_ui_label(content, "EXPEDIÇÃO EM PAUSA", 23, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	_ui_label(content, "Até as raízes precisam respirar.", 12, Color("#aebfba"), HORIZONTAL_ALIGNMENT_CENTER)
	_ui_button(content, "CONTINUAR", _toggle_pause, true)
	var volume := HSlider.new()
	volume.min_value = 0.0
	volume.max_value = 1.0
	volume.step = 0.05
	volume.value = float(SaveManager.data.settings.master)
	volume.value_changed.connect(_setting_master_changed)
	content.add_child(volume)
	_ui_button(content, "REINICIAR EXPEDIÇÃO", _confirm_restart, false)
	_ui_button(content, "SAIR PARA O MENU", _confirm_menu, false)

func _setting_master_changed(value: float) -> void:
	SaveManager.data.settings.master = value
	SaveManager.save_game()
	var bus := AudioServer.get_bus_index("Master")
	if bus >= 0:
		AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(value, 0.001)))

func _setting_ui_scale_changed(value: float) -> void:
	SaveManager.data.settings.ui_scale = value
	SaveManager.save_game()
	_build_hud()
	_update_hud()
	_update_boss_hud()

func _confirm_restart() -> void:
	var dialog := ConfirmationDialog.new()
	dialog.dialog_text = "Recomeçar agora? O ouro desta expedição será perdido."
	dialog.confirmed.connect(func() -> void: get_tree().paused = false; restart_requested.emit())
	ui_root.add_child(dialog)
	dialog.popup_centered(Vector2i(maxi(180, mini(420, roundi(get_viewport_rect().size.x - 28.0))), 150))

func _confirm_menu() -> void:
	var dialog := ConfirmationDialog.new()
	dialog.dialog_text = "Sair para o menu? O ouro desta expedição será perdido."
	dialog.confirmed.connect(func() -> void: get_tree().paused = false; return_to_menu.emit())
	ui_root.add_child(dialog)
	dialog.popup_centered(Vector2i(maxi(180, mini(420, roundi(get_viewport_rect().size.x - 28.0))), 150))

func _on_player_died() -> void:
	if abilities.level_of(&"phoenix_flame") > 0 and not phoenix_used:
		phoenix_used = true
		player.is_dead = false
		player.health = player.max_health * (0.40 + float(abilities.level_of(&"phoenix_flame") - 1) * 0.12)
		player.invulnerability = 2.0
		_spawn_skill(player.global_position, "fire", 180.0, Color("#e8ae6c"))
		_show_notice("CHAMA FÊNIX   ·   UMA NOVA CHANCE")
		return
	_finish_run(false)

func _finish_run(victory: bool) -> void:
	if run_finished:
		return
	run_finished = true
	_set_boss_music(false)
	if victory and not reward_banked and not reward.is_empty():
		reward_banked = true
		var item_id := str(reward.equipment)
		if SaveManager.data.equipment.has(item_id):
			reward.gold = int(reward.gold) + 100
			reward["duplicate"] = true
		else:
			SaveManager.unlock_equipment(item_id)
		run_items.append({"id": item_id, "source": "boss", "duplicate": bool(reward.get("duplicate", false))})
		SaveManager.data.crystals = int(SaveManager.data.get("crystals", 0)) + int(reward.get("crystals", 1))
		run_gold += int(reward.gold)
	wave_director.stop()
	var playtime_val := wave_director.match_time if wave_director != null else 0.0
	var damage_dealt := float(player.get("total_damage_dealt") if player != null and player.get("total_damage_dealt") != null else 0.0)
	SaveManager.record_run(wave_director.wave, run_gold, playtime_val, enemies_defeated, player_class, bosses_defeated, elites_defeated, damage_dealt, victory, CampaignRules.reward_multiplier(difficulty_tier, phase_number) * (1.0 + player.bonus_gold_xp + player.bonus_xp_only))
	if victory:
		SaveManager.complete_phase(map_id, phase_number, difficulty_tier)
	GameManager.finish_run()
	get_tree().paused = true
	result_layer = _make_modal()
	var panel := _result_panel(result_layer, 720.0)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	panel.add_child(_pad(content, 16, 14, 16, 14))
	if victory:
		_ui_label(content, "FASE CONCLUÍDA!", 28, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
		_ui_label(content, "%s · Fase %02d/10 · %s\n%s foi derrotado." % [map_data.display_name, phase_number, CampaignRules.difficulty_name(difficulty_tier), defeated_boss_name], 15, Color("#d4e0d6"), HORIZONTAL_ALIGNMENT_CENTER)
		_ui_label(content, "+%d ouro do chefe  ·  +%d cristais" % [int(reward.get("gold", 0)), int(reward.get("crystals", 0))], 14, Color("#f0d58b"), HORIZONTAL_ALIGNMENT_CENTER)
		_add_run_rewards(content, run_items)
		_ui_label(content, _summary_text(), 13, Color("#bac9c2"), HORIZONTAL_ALIGNMENT_CENTER)
		var next_label := "PRÓXIMA DIFICULDADE · " + CampaignRules.difficulty_name(difficulty_tier + 1).to_upper() if CampaignRules.ordinal(map_id, phase_number) == 59 else "PRÓXIMA FASE"
		var actions := HFlowContainer.new()
		content.add_child(actions)
		_ui_button(actions, next_label, _request_next_stage, true)
		_ui_button(actions, "JOGAR NOVAMENTE", _restart, false)
	else:
		_ui_label(content, "VOCÊ FOI DERROTADO", 28, Color("#e98b7d"), HORIZONTAL_ALIGNMENT_CENTER)
		_ui_label(content, "Sua jornada continua. A experiência conquistada fica com você.", 14, Color("#c7d1c9"), HORIZONTAL_ALIGNMENT_CENTER)
		_ui_label(content, _summary_text(), 13, Color("#bac9c2"), HORIZONTAL_ALIGNMENT_CENTER)
		_ui_button(content, "TENTAR NOVAMENTE", _restart, true)
	var current_level := TalentManager.character_level(player_class)
	_ui_label(content, "%s · +%d XP · NÍVEL %d → %d\n%d PONTOS DE TALENTO DISPONÍVEIS" % [player.class_data.display_name.to_upper(), int(SaveManager.data.class_progression[player_class].last_xp), starting_character_level, current_level, maxi(0, current_level - TalentManager.spent_points(player_class))], 12, MINT, HORIZONTAL_ALIGNMENT_CENTER)
	_ui_button(content, "MENU PRINCIPAL", _leave_to_menu, false)

func _restart() -> void:
	get_tree().paused = false
	restart_requested.emit()

func _request_next_stage() -> void:
	get_tree().paused = false
	next_stage_requested.emit()

func _leave_to_menu() -> void:
	get_tree().paused = false
	return_to_menu.emit()

func _summary_text() -> String:
	return "Onda %d   ·   Nível %d   ·   %d abates   ·   Maior cadeia: %d\nOuro desta expedição: %d   ·   Tempo: %s" % [wave_director.wave, experience.level, enemies_defeated, best_chain, run_gold, _format_time(wave_director.match_time)]

func _add_run_rewards(parent: Control, items: Array) -> void:
	var panel := REWARD_PANEL_SCRIPT.new()
	panel.items = items
	parent.add_child(panel)

func _result_panel(layer: Control, requested_width: float) -> PanelContainer:
	var viewport := RESULT_VIEWPORT_SCRIPT.new()
	viewport.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	viewport.preferred_width = requested_width
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = STYLE.SURFACE
	style.border_color = STYLE.GOLD
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	panel.add_theme_stylebox_override("panel", style)
	viewport.content = panel
	layer.add_child(viewport)
	return panel

func _make_modal() -> Control:
	var layer := Control.new()
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	layer.mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.015, 0.027, 0.033, 0.78)
	layer.add_child(shade)
	ui_root.add_child(layer)
	layer.modulate.a = 0.0
	var reveal := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	reveal.tween_property(layer, "modulate:a", 1.0, 0.18)
	return layer

func _modal_panel(layer: Control, minimum: Vector2) -> PanelContainer:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.add_theme_constant_override("margin_left", 16)
	center.add_theme_constant_override("margin_right", 16)
	layer.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(maxf(0.0, minf(minimum.x, get_viewport_rect().size.x - 32.0)), minimum.y)
	panel.set_meta("requested_width", minimum.x)
	modal_panels.append(panel)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var style := StyleBoxFlat.new()
	style.bg_color = STYLE.SURFACE
	style.border_color = STYLE.LINE
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)
	return panel

func _show_notice(message: String) -> void:
	if ui_root == null:
		return
	if notice_label != null and is_instance_valid(notice_label):
		notice_label.queue_free()
	notice_label = Label.new()
	notice_label.text = STYLE.clean_text(message)
	notice_label.add_theme_font_size_override("font_size", 15)
	notice_label.add_theme_color_override("font_color", Color("#f0d389"))
	notice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notice_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	notice_label.clip_text = false
	notice_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	notice_label.anchor_left = 0.1
	notice_label.anchor_right = 0.9
	notice_label.offset_top = 158
	notice_label.offset_bottom = 214
	ui_root.add_child(notice_label)
	var tween := create_tween()
	tween.tween_interval(2.2)
	tween.tween_property(notice_label, "modulate:a", 0.0, 0.45)
	tween.tween_callback(notice_label.queue_free)

func _nearest_enemies(position: Vector2, radius: float, max_count: int) -> Array[ChaserEnemy]:
	var candidates: Array[ChaserEnemy] = []
	for enemy in enemy_manager.nearby(position, radius):
		if is_instance_valid(enemy) and not enemy.dead and position.distance_squared_to(enemy.global_position) <= radius * radius:
			candidates.append(enemy)
	candidates.sort_custom(func(a: ChaserEnemy, b: ChaserEnemy) -> bool: return position.distance_squared_to(a.global_position) < position.distance_squared_to(b.global_position))
	if candidates.size() > max_count:
		candidates.resize(max_count)
	return candidates

func _class_ability_name() -> String:
	var data: ClassData = ContentCatalog.classes.get(player_class, ContentCatalog.classes.get("warrior"))
	var ability: AbilityData = ContentCatalog.abilities.get(str(data.starting_ability))
	return ability.display_name if ability != null else "Ataque automático"

func _wave_epithet(wave: int) -> String:
	return {1:"AS PRIMEIRAS HORDAS", 2:"A PRESSÃO AUMENTA", 3:"ELITES NO CAMINHO", 4:"O GUARDIÃO DESPERTA"}.get(wave, "CONFRONTO FINAL")

func _format_time(seconds: float) -> String:
	var whole := maxi(0, floori(seconds))
	return "%02d:%02d" % [whole / 60, whole % 60]

func _rarity_name(id: String) -> String:
	return {"common":"comum", "uncommon":"incomum", "rare":"rara", "epic":"épica", "legendary":"lendária", "demigod":"semideus", "divine":"deus"}.get(id, id)

func _ui_panel(parent: Node, minimum: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = minimum
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.09, 0.09, 0.86)
	style.border_color = STYLE.LINE
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.shadow_color = Color(0.012, 0.02, 0.018, 0.34)
	style.shadow_size = 0
	style.shadow_offset = Vector2(0, 4)
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)
	return panel

func _progress(parent: Node, color: Color, height: int) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size.y = height
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var background := StyleBoxFlat.new()
	background.bg_color = Color("#2a3a2e")
	background.set_corner_radius_all(5)
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(5)
	bar.add_theme_stylebox_override("background", background)
	bar.add_theme_stylebox_override("fill", fill)
	parent.add_child(bar)
	return bar

func _ui_label(parent: Node, text: String, size: int, color: Color, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new()
	label.text = STYLE.clean_text(text)
	var ui_scale := clampf(float(SaveManager.data.get("settings", {}).get("ui_scale", 1.0)), 0.85, 1.2)
	label.add_theme_font_size_override("font_size", roundi(size * ui_scale))
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = align
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.clip_text = false
	label.custom_minimum_size.x = minf(120, STYLE.body_font().get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x)
	parent.add_child(label)
	return label

func _ui_button(parent: Node, text: String, callback: Callable, primary := false, height := 46) -> Button:
	var button := Button.new()
	button.text = STYLE.clean_text(text)
	button.custom_minimum_size.y = height
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	STYLE.apply_button(button, primary)
	var ui_scale := clampf(float(SaveManager.data.settings.get("ui_scale", 1.0)), 0.85, 1.2)
	button.add_theme_font_size_override("font_size", roundi(13 * ui_scale))
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func _animate_hud_button(button: Control, target_scale: float) -> void:
	if not is_instance_valid(button):
		return
	button.pivot_offset = button.size * 0.5
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", Vector2.ONE * target_scale, 0.12)

func _pad(child: Control, left: int, top: int, right: int, bottom: int) -> MarginContainer:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", left)
	margin.add_theme_constant_override("margin_top", top)
	margin.add_theme_constant_override("margin_right", right)
	margin.add_theme_constant_override("margin_bottom", bottom)
	margin.add_child(child)
	return margin
