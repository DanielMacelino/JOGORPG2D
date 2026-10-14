extends CharacterBody2D
class_name SurvivorPlayer

const ANIMATOR := preload("res://scripts/world/character_animator.gd")
const PORTRAITS := {
	"warrior": preload("res://assets/art/portraits/warrior.svg"),
	"mage": preload("res://assets/art/portraits/mage.svg"),
	"ranger": preload("res://assets/art/portraits/ranger.svg"),
	"assassin": preload("res://assets/art/portraits/assassin.svg"),
	"druid": preload("res://assets/art/portraits/druid.svg"),
	"paladin": preload("res://assets/art/portraits/paladin.svg")
}

signal died
signal damaged(amount: float)
signal stats_changed

var class_data: ClassData
var player_class := "warrior"
var max_health := 100.0
var health := 100.0
var damage := 10.0
var defense := 0.0
var move_speed := 200.0
var attack_cooldown := 0.9
var attack_range := 240.0
var projectile_speed := 450.0
var crit_chance := 0.05
var crit_multiplier := 1.7
var bonus_gold_xp := 0.0
var pickup_radius := 160.0
var lifesteal := 0.0
var regen := 0.0
var total_damage_dealt := 0.0
var regen_clock := 0.0
var level := 1
var character_level := 1
var cleave_targets := 0
var projectile_pierce := 0
var splash_bonus := 0.0
var class_power := false
var power_damage := 0.0
var base_run_stats: Dictionary = {}
var thorns := 0.0
var summon_count := 0
var summon_duration := 0.0
var summon_damage_pct := 0.0
var summon_speed_pct := 0.0
var projectile_bounces := 0
var burn_on_hit := 0.0
var chill_on_hit := 0.0
var external_direction := Vector2.ZERO
var use_local_input := true
var net_peer_id := 1
var facing := Vector2.RIGHT
var invulnerability := 0.0
var protected_damage := 0.0
var life_recovery_budget := 0.0
var flash := 0.0
var tint: Color = Color("#ffb35c")
var is_dead := false
var revive_progress := 0.0
var revive_protection := 0.0
var damage_serial := 0
var animation_time := 0.0
var moving_blend := 0.0
var attack_time := 0.0
var attack_duration := 0.24
var attack_serial := 0
var attack_direction := Vector2.RIGHT
var attack_critical := false
var attack_animation_style: StringName = &"melee"

func _ready() -> void:
	add_to_group("survivor_player")

func configure(class_id: String, permanent_equipment: Dictionary) -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	collision_layer = 1
	collision_mask = 4
	player_class = class_id
	class_data = ContentCatalog.classes.get(class_id, ContentCatalog.classes.get("warrior"))
	crit_chance = 0.05
	crit_multiplier = 1.7
	var save: Dictionary = SaveManager.data
	var upgrades: Dictionary = save.get("upgrades", {})
	var equipment_bonuses: Dictionary = EquipmentManager.equipped_bonuses(class_id)
	max_health = class_data.max_health * (1.0 + int(upgrades.get("vitality", 0)) * 0.05)
	damage = class_data.damage * (1.0 + int(upgrades.get("might", 0)) * 0.04)
	defense = class_data.defense
	defense += float(equipment_bonuses.get("defense", 0.0))
	move_speed = class_data.speed
	attack_cooldown = class_data.attack_cooldown
	attack_range = class_data.attack_range
	projectile_speed = class_data.projectile_speed
	bonus_gold_xp = int(upgrades.get("fortune", 0)) * 0.05
	bonus_gold_xp += int(upgrades.get("xp_boost", 0)) * 0.025
	defense += int(upgrades.get("resilience", 0)) * 0.6
	move_speed *= 1.0 + int(upgrades.get("swiftness", 0)) * 0.03
	crit_chance += minf(0.2, int(upgrades.get("crit_mastery", 0)) * 0.015)
	attack_cooldown /= 1.0 + int(upgrades.get("attack_speed", 0)) * 0.03
	attack_cooldown /= 1.0 + float(equipment_bonuses.get("attack_speed_pct", 0.0))
	damage += float(equipment_bonuses.get("damage", 0.0))
	damage *= 1.0 + float(equipment_bonuses.get("damage_pct", 0.0))
	move_speed *= 1.0 + float(equipment_bonuses.get("speed_pct", 0.0))
	max_health += float(equipment_bonuses.get("health", 0.0)) + float(permanent_equipment.get("health", 0.0))
	var talents: Dictionary = TalentManager.bonuses(class_id)
	character_level = TalentManager.character_level(class_id)
	max_health *= 1.0 + float(character_level - 1) * 0.008
	damage *= 1.0 + float(character_level - 1) * 0.01
	max_health *= 1.0 + clampf(float(talents.get("health_pct", 0.0)), 0.0, 2.5)
	damage *= 1.0 + clampf(float(talents.get("damage_pct", 0.0)), 0.0, 2.5)
	attack_cooldown /= 1.0 + clampf(float(talents.get("attack_speed_pct", 0.0)), 0.0, 1.0)
	move_speed *= 1.0 + clampf(float(talents.get("speed_pct", 0.0)), 0.0, 0.6)
	defense += clampf(float(talents.get("defense", 0.0)), 0.0, 24.0)
	crit_chance += clampf(float(talents.get("crit_chance", 0.0)), 0.0, 0.65)
	bonus_gold_xp += clampf(float(talents.get("bonus_gold_xp", 0.0)), 0.0, 1.5)
	pickup_radius += clampf(float(talents.get("pickup_radius", 0.0)), 0.0, 240.0)
	lifesteal = clampf(float(talents.get("lifesteal", 0.0)), 0.0, 0.04)
	regen = clampf(float(talents.get("regen", 0.0)), 0.0, 8.0)
	cleave_targets = roundi(float(talents.get("cleave_targets", 0.0)))
	projectile_pierce = roundi(float(talents.get("projectile_pierce", 0.0)))
	splash_bonus = float(talents.get("splash_radius", 0.0))
	crit_multiplier += float(talents.get("crit_multiplier", 0.0))
	crit_chance += float(equipment_bonuses.get("crit_chance", 0.0))
	pickup_radius += float(equipment_bonuses.get("pickup_radius", 0.0))
	cleave_targets += roundi(float(equipment_bonuses.get("cleave_targets", 0.0)))
	splash_bonus += float(equipment_bonuses.get("splash_radius", 0.0))
	thorns = float(equipment_bonuses.get("thorns", 0.0))
	summon_duration = float(equipment_bonuses.get("summon_duration", 0.0)) + float(talents.get("summon_duration", 0.0))
	summon_damage_pct = float(equipment_bonuses.get("summon_damage_pct", 0.0))
	projectile_bounces = roundi(float(equipment_bonuses.get("projectile_bounces", 0.0)))
	burn_on_hit = float(equipment_bonuses.get("burn_on_hit", 0.0))
	chill_on_hit = float(equipment_bonuses.get("chill_on_hit", 0.0))
	class_power = bool(talents.get("class_power", false))
	power_damage = float(talents.get("power_damage", 0.0))
	health = max_health
	life_recovery_budget = max_health * 0.01
	tint = class_data.accent
	is_dead = false
	base_run_stats = {"max_health": max_health, "damage": damage, "defense": defense, "move_speed": move_speed, "attack_cooldown": attack_cooldown, "attack_range": attack_range, "crit_chance": crit_chance, "bonus_gold_xp": bonus_gold_xp, "pickup_radius": pickup_radius, "lifesteal": lifesteal, "regen": regen, "cleave_targets": cleave_targets, "projectile_pierce": projectile_pierce, "splash_bonus": splash_bonus}
	base_run_stats.merge({"thorns": thorns, "summon_duration": summon_duration, "summon_damage_pct": summon_damage_pct})
	queue_redraw()

func rebuild_run_stats(bonuses: Dictionary) -> void:
	# Every percentage is summed first, then applied once to the expedition baseline.
	var old_max := max_health
	max_health = float(base_run_stats.max_health) * (1.0 + float(bonuses.get("health_pct", 0.0)))
	damage = float(base_run_stats.damage) * pow(1.015, maxi(0, level - 1)) * (1.0 + float(bonuses.get("damage_pct", 0.0)))
	attack_cooldown = float(base_run_stats.attack_cooldown) / (1.0 + float(bonuses.get("attack_speed_pct", 0.0)))
	move_speed = float(base_run_stats.move_speed) * (1.0 + float(bonuses.get("speed_pct", 0.0)))
	attack_range = float(base_run_stats.attack_range) * (1.0 + float(bonuses.get("range_pct", 0.0)))
	for stat in ["defense", "crit_chance", "bonus_gold_xp", "pickup_radius", "lifesteal", "regen"]:
		set(stat, float(base_run_stats[stat]) + float(bonuses.get(stat, 0.0)))
	cleave_targets = int(base_run_stats.cleave_targets) + roundi(float(bonuses.get("cleave_targets", 0.0)))
	projectile_pierce = int(base_run_stats.projectile_pierce) + roundi(float(bonuses.get("projectile_pierce", 0.0)))
	splash_bonus = float(base_run_stats.splash_bonus) + float(bonuses.get("splash_radius", 0.0))
	thorns = float(base_run_stats.thorns) + float(bonuses.get("thorns", 0.0))
	summon_count = roundi(float(bonuses.get("summon_count", 0.0)))
	summon_duration = float(base_run_stats.summon_duration) + float(bonuses.get("summon_duration", 0.0))
	summon_damage_pct = float(base_run_stats.summon_damage_pct) + float(bonuses.get("summon_damage_pct", 0.0))
	summon_speed_pct = float(bonuses.get("summon_speed_pct", 0.0))
	health = 0.0 if is_dead else clampf(health + max_health - old_max, 0.0, max_health)
	stats_changed.emit()

func threat_score(from: Vector2) -> float:
	return global_position.distance_to(from) / maxf(1.0, class_data.threat_priority)

func _physics_process(delta: float) -> void:
	if NetworkSession.running and NetworkSession.hosting and net_peer_id != 1:
		NetworkSession.simulate_remote_player(self)
	if is_dead:
		return
	animation_time += delta
	# Area hits share a recovery budget, so attacking a crowd cannot heal a full bar instantly.
	var recovery_rate := max_health * 0.015
	life_recovery_budget = minf(recovery_rate, life_recovery_budget + recovery_rate * delta)
	attack_time = maxf(0.0, attack_time - delta)
	revive_protection = maxf(0.0, revive_protection - delta)
	invulnerability = maxf(0.0, invulnerability - delta)
	flash = maxf(0.0, flash - delta)
	regen_clock += delta
	if regen > 0.0 and regen_clock >= 0.5:
		heal(regen * regen_clock)
		regen_clock = 0.0
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down") if use_local_input else Vector2.ZERO
	if direction.is_zero_approx():
		direction = external_direction
	if direction.length_squared() > 1.0:
		direction = direction.normalized()
	moving_blend = move_toward(moving_blend, 1.0 if not direction.is_zero_approx() else 0.0, delta * 7.0)
	if not direction.is_zero_approx():
		facing = direction.normalized()
	if not (NetworkSession.running and NetworkSession.hosting and net_peer_id != 1):
		velocity = direction * move_speed
		move_and_slide()
		_clamp_to_arena()
	queue_redraw()

func simulate_network_step(direction: Vector2, step: float) -> void:
	velocity = direction.limit_length() * move_speed
	external_direction = direction
	var remaining := velocity * step
	for slide in 4:
		if remaining.is_zero_approx():
			break
		var collision := move_and_collide(remaining)
		if collision == null:
			break
		remaining = collision.get_remainder().slide(collision.get_normal())
	_clamp_to_arena()

func _clamp_to_arena() -> void:
	global_position.x = clampf(global_position.x, -1190.0, 1190.0)
	global_position.y = clampf(global_position.y, -820.0, 820.0)

func set_virtual_direction(direction: Vector2) -> void:
	external_direction = direction

func play_attack(direction: Vector2, critical: bool = false, style: StringName = &"melee") -> void:
	attack_direction = direction.normalized() if not direction.is_zero_approx() else facing
	attack_critical = critical
	attack_animation_style = style
	attack_serial += 1
	attack_duration = {"warrior": 0.30, "mage": 0.34, "ranger": 0.17, "assassin": 0.15, "druid": 0.34, "paladin": 0.30}.get(player_class, 0.24)
	attack_time = attack_duration
	queue_redraw()

func take_damage(amount: float, area_damage: bool = false, source: Node = null) -> void:
	if is_instance_valid(source) and (source is SurvivorPlayer or source.get_meta("team", "") == "players"):
		return
	if is_dead:
		return
	if revive_protection > 0.0:
		return
	# Within the grace period, only the strongest hit counts. A weak hit cannot hide a boss hit.
	var incoming := maxf(1.0, amount) if area_damage else maxf(maxf(1.0, amount * 0.30), amount - defense)
	var actual := incoming - (protected_damage if invulnerability > 0.0 else 0.0)
	if actual <= 0.0:
		return
	if invulnerability <= 0.0:
		invulnerability = 0.25
	protected_damage = incoming
	damage_serial += 1
	health = maxf(0.0, health - actual)
	var lethal := health <= 0.0
	if lethal:
		is_dead = true
	flash = 0.22
	damaged.emit(actual)
	stats_changed.emit()
	if lethal:
		died.emit()
	queue_redraw()

func revive() -> void:
	if not is_dead:
		return
	is_dead = false
	revive_progress = 0.0
	health = max_health * 0.35
	revive_protection = 2.0
	invulnerability = 0.0
	protected_damage = 0.0
	velocity = Vector2.ZERO
	stats_changed.emit()
	queue_redraw()

func downed_status() -> String:
	return "REANIMANDO %d%%" % roundi(revive_progress * 100) if revive_progress > 0.0 else "CAIU · APROXIME-SE (4s)"

func heal(amount: float) -> void:
	if is_dead:
		return
	var healed := minf(max_health, health + maxf(0.0, amount))
	if is_equal_approx(healed, health):
		return
	health = healed
	stats_changed.emit()
	queue_redraw()

func record_damage(amount: float) -> void:
	total_damage_dealt += amount
	if lifesteal > 0.0:
		var recovered := minf(amount * lifesteal, life_recovery_budget)
		life_recovery_budget -= recovered
		heal(recovered)

func animation_state() -> Dictionary:
	return {"time": animation_time, "moving": moving_blend, "facing": facing, "attacking": attack_time > 0.0, "attack_progress": 1.0 - attack_time / maxf(0.001, attack_duration), "attack_serial": attack_serial}

func _draw() -> void:
	if is_dead:
		draw_circle(Vector2.ZERO, 27, Color("#061018", 0.95))
		draw_arc(Vector2.ZERO, 27, 0, TAU, 48, Color("#ffcd6a"), 2, true)
		if revive_progress > 0.0:
			draw_arc(Vector2.ZERO, 31, -PI / 2, -PI / 2 + TAU * revive_progress, 48, Color("#72ffc4"), 4, true)
		draw_line(Vector2(-10, 0), Vector2(10, 0), Color("#fff2de"), 5, true)
		draw_line(Vector2(0, -10), Vector2(0, 10), Color("#fff2de"), 5, true)
		return
	draw_set_transform(Vector2(0, 8), 0.0, Vector2(1.0, 0.39))
	draw_circle(Vector2.ZERO, 18, Color(0.015, 0.02, 0.025, 0.48))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_arc(Vector2(0, 10), 20, 0, TAU, 36, Color("#a9f3ff", 0.75), 1.7, true)
	var body_color := Color(1.6, 1.6, 1.6) if flash > 0 else Color.WHITE
	if invulnerability > 0 and int(invulnerability * 22.0) % 2 == 0:
		body_color.a = 0.55
	ANIMATOR.draw_character(self, player_class, animation_state(), body_color)

	if attack_time > 0.0:
		var progress := 1.0 - attack_time / maxf(0.001, attack_duration)
		draw_set_transform(Vector2.ZERO, attack_direction.angle(), Vector2.ONE)
		var alpha := (1.0 - progress) * (0.92 if attack_critical else 0.72)
		var slash_color := Color("#fff0b0", alpha) if attack_critical else Color("#f5d99b", alpha)
		if attack_animation_style == &"melee":
			draw_arc(Vector2(13, -1), 24.0 + progress * 9.0, -1.2 + progress * 0.4, 1.15 + progress * 0.45, 24, Color(slash_color, alpha * 0.24), 8.0 * (1.0 - progress) + 1.0, true)
			draw_arc(Vector2(13, -1), 24.0 + progress * 9.0, -1.2 + progress * 0.4, 1.15 + progress * 0.45, 24, slash_color, 2.4 * (1.0 - progress) + 0.6, true)
		elif attack_animation_style == &"ranged":
			draw_arc(Vector2(13, 1), 12.0, -1.1, 1.1, 18, Color("#d9cda9", alpha), 2.0, true)
			draw_line(Vector2(14, -10), Vector2(14, 12), Color("#f1e5c8", alpha * 0.82), 1.0, true)
			draw_line(Vector2(5, 0), Vector2(30 + progress * 12.0, 0), slash_color, 2.0, true)
		else:
			var spark := Vector2(25 + progress * 7.0, 0)
			draw_circle(spark, 9.0 * (1.0 - progress), Color(tint.lightened(0.65), alpha * 0.22))
			draw_circle(spark, 4.2 * (1.0 - progress), Color("#eff6ff", alpha))
			for index in 4:
				var ray := Vector2.RIGHT.rotated(float(index) * TAU / 4.0 + progress) * (11.0 + progress * 8.0)
				draw_line(spark + ray * 0.48, spark + ray, slash_color, 1.5, true)
		if attack_critical:
			draw_circle(Vector2(38, 0), 3.5 * (1.0 - progress), Color("#fff0a0", alpha))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
