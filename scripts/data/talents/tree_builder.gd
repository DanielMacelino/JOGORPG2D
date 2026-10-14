extends RefCounted
## Shared graph rules; category content and shapes are supplied by independent modules.
const RINGS := 8
const SLOTS := 24
const AMOUNTS := {"damage_pct": 0.015, "health_pct": 0.018, "attack_speed_pct": 0.012, "speed_pct": 0.009, "crit_chance": 0.008, "bonus_gold_xp": 0.018, "pickup_radius": 6.0, "defense": 0.45, "regen": 0.12, "lifesteal": 0.0004, "crit_multiplier": 0.012, "cleave_targets": 0.025, "power_damage": 0.02, "splash_radius": 3.0}
static func root_id(category: String) -> String:
	return "origin" if category == "general" else category + "_origin"
static func node_id(category: String, ring: int, slot: int) -> String:
	return "%s_r%d_%02d" % [category, ring, posmod(slot, SLOTS)]
static func build(module: Script, class_id: String, profile: Array, describe: Callable) -> Dictionary:
	var root := root_id(module.ID)
	var tree := {root: {"id": root, "name": "Centelha - " + module.TITLE, "branch": module.ID, "position": Vector2.ZERO, "parents": [], "bonuses": {}, "cost": 0, "required_level": 1, "notable": false, "keystone": false, "power": false, "description": "Parta deste centro. Os pontos pertencem ao personagem e podem ser investidos nas seis árvores."}}
	var gates := [1, 1, 1, 8, 12, 18, 24, 30]
	var affinity: String = {"general": profile[2], "fury": profile[0], "vigor": profile[1], "cunning": profile[2], "survival": profile[1], "technique": profile[3]}[module.ID]
	for ring in range(1, RINGS + 1):
		for slot in SLOTS:
			var notable := ring in [4, 6, 8] and slot % 4 == 0
			var keystone := ring == 8 and notable
			var power: bool = module.ID == "technique" and keystone and slot == 0
			var stat: String = module.STATS[slot % module.STATS.size()]
			var value: float = AMOUNTS[stat] * (1.0 + (ring - 1) * 0.07)
			if (class_id == "warrior" and stat == "health_pct") or (class_id == "mage" and stat == "splash_radius") or (class_id == "ranger" and stat == "attack_speed_pct") or (class_id == "assassin" and stat == "crit_multiplier") or (class_id == "druid" and stat == "regen") or (class_id == "paladin" and stat == "defense"):
				value *= 1.35
			var bonuses := {stat: value}
			var title := "%s - %s %d.%d" % [affinity, module.NAMES[slot % module.NAMES.size()], ring, slot + 1]
			if notable:
				bonuses = module.KEYSTONE.duplicate() if keystone else module.NOTABLE.duplicate()
				title = ("Apoteose" if keystone else ("Domínio" if ring == 6 else "Despertar")) + " - %s %d" % [affinity, slot / 4 + 1]
				if keystone and slot == 4:
					if module.ID == "fury":
						bonuses["projectile_pierce" if class_id == "ranger" else ("splash_radius" if class_id in ["mage", "druid"] else "cleave_targets")] = 60.0 if class_id in ["mage", "druid"] else 3.0
					if module.ID == "technique" and class_id == "druid": bonuses["summon_duration"] = 4.0
			var description: String = describe.call(bonuses)
			if power:
				title = profile[3]
				bonuses = {}
				description = profile[4] + "\nAtivado automaticamente durante o combate."
			var id := node_id(module.ID, ring, slot)
			tree[id] = {"id": id, "name": title, "branch": module.ID, "position": shape_position(module.SHAPE, ring, slot), "parents": [], "bonuses": bonuses, "cost": 3 if keystone else (2 if notable else 1), "required_level": gates[ring - 1], "notable": notable, "keystone": keystone, "power": power, "description": description}
	for ring in range(1, RINGS + 1):
		for slot in SLOTS:
			var id := node_id(module.ID, ring, slot)
			if ring > 1: link(tree, id, node_id(module.ID, ring - 1, slot))
			if module.ID in ["general", "vigor", "technique"] or slot % 4 != 3:
				link(tree, id, node_id(module.ID, ring, slot + 1))
			if ring > 1 and slot % (3 if module.ID == "cunning" else 4) == 0:
				link(tree, id, node_id(module.ID, ring - 1, slot + (2 if module.ID == "cunning" else 1)))
	for slot in range(0, SLOTS, 4): link(tree, root, node_id(module.ID, 1, slot))
	return tree
static func link(tree: Dictionary, a: String, b: String) -> void:
	if not tree[a].parents.has(b): tree[a].parents.append(b)
	if not tree[b].parents.has(a): tree[b].parents.append(a)
static func shape_position(shape: String, ring: int, slot: int) -> Vector2:
	var angle := float(slot) * TAU / SLOTS
	var radius := 175.0 + (ring - 1) * 125.0
	match shape:
		"flame": return Vector2.from_angle(angle - PI / 2) * radius * (0.84 + 0.22 * cos(angle * 6)) * Vector2(0.9, 1.15)
		"heart": return Vector2(16 * pow(sin(angle), 3), -(13 * cos(angle) - 5 * cos(2 * angle) - 2 * cos(3 * angle) - cos(4 * angle))) * radius / 17
		"eye": return Vector2(cos(angle), sin(angle) * (0.48 + 0.10 * absf(cos(angle)))) * radius
		"leaf": return Vector2(sin(angle) * (0.55 + 0.3 * absf(cos(angle))), -cos(angle) * 1.10) * radius
		"hexagon":
			var segment := float(slot) / 4
			var first := Vector2.from_angle(floorf(segment) * TAU / 6 - PI / 2)
			var second := Vector2.from_angle((floorf(segment) + 1) * TAU / 6 - PI / 2)
			return first.lerp(second, fmod(segment, 1)) * radius
	return Vector2.from_angle(angle - PI / 2) * radius
