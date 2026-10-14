extends Node
## Each character owns XP, points, and six independent constellation graphs.
signal changed

const MAX_LEVEL := 216
const ORIGIN := "origin"
const RINGS := 8
const SLOTS := 24
const BUILDER := preload("res://scripts/data/talents/tree_builder.gd")
const TREE_ORDER := ["general", "fury", "vigor", "cunning", "survival", "technique"]
const ROOTS := ["origin", "fury_origin", "vigor_origin", "cunning_origin", "survival_origin", "technique_origin"]
const MODULES := {"general": preload("res://scripts/data/talents/general.gd"), "fury": preload("res://scripts/data/talents/fury.gd"), "vigor": preload("res://scripts/data/talents/vigor.gd"), "cunning": preload("res://scripts/data/talents/cunning.gd"), "survival": preload("res://scripts/data/talents/survival.gd"), "technique": preload("res://scripts/data/talents/technique.gd")}
const BRANCHES := TREE_ORDER
var BRANCH_NAMES: Dictionary = {}
var BRANCH_COLORS: Dictionary = {}
const BONUS_DEFAULTS := {"damage_pct": 0.0, "health_pct": 0.0, "attack_speed_pct": 0.0, "speed_pct": 0.0, "defense": 0.0, "crit_chance": 0.0, "bonus_gold_xp": 0.0, "pickup_radius": 0.0, "lifesteal": 0.0, "regen": 0.0, "cleave_targets": 0.0, "projectile_pierce": 0.0, "splash_radius": 0.0, "crit_multiplier": 0.0, "power_damage": 0.0}
const PROFILES := {
	"warrior": ["Aço", "Bastião", "Disciplina", "Terremoto", "A cada 8 s, rompe o solo e atinge os inimigos ao redor."],
	"mage": ["Éter", "Véu", "Oráculo", "Supernova", "A cada 10 s, libera uma explosão arcana de grande alcance."],
	"ranger": ["Espinhos", "Abrigo", "Mira", "Chuva de flechas", "A cada 7 s, dispara cinco flechas perfurantes em leque."],
	"assassin": ["Lâmina", "Sombra", "Emboscada", "Execução", "A cada 7 s, golpeia até seis inimigos próximos com dano elevado."],
	"druid": ["Raízes", "Seiva", "Ciclo", "Florescimento ancestral", "A cada 10 s, invoca um ancestral por 18 s, causa dano ao redor e recupera 20% da vida máxima."],
	"paladin": ["Sol", "Juramento", "Aurora", "Julgamento", "A cada 9 s, consagra o chão, causa dano e recupera 8% da vida máxima."]
}
var nodes: Dictionary = {}
var trees: Dictionary = {}
var subtrees: Dictionary = {}
var tree_id := "general"
var class_id := "warrior"

func _ready() -> void:
	for category in TREE_ORDER:
		BRANCH_NAMES[category] = str(MODULES[category].TITLE)
		BRANCH_COLORS[category] = Color(str(MODULES[category].COLOR))
	for id in ContentCatalog.CLASS_ORDER:
		var all_nodes := {}
		var categories := {}
		for category in TREE_ORDER:
			var built: Dictionary = BUILDER.build(MODULES[category], str(id), PROFILES[str(id)], describe_bonuses)
			categories[category] = built
			all_nodes.merge(built)
		subtrees[str(id)] = categories
		trees[str(id)] = all_nodes
	class_id = str(SaveManager.data.selected_class)
	nodes = subtrees[class_id][tree_id]
	_validate_allocations()
	SaveManager.progression_changed.connect(_progress_changed)

func _progress_changed() -> void:
	changed.emit()

func set_class(id: String) -> void:
	if trees.has(id):
		class_id = id
		nodes = subtrees[id][tree_id]
		changed.emit()

func character_xp(id: String = "") -> int:
	var target := class_id if id.is_empty() else id
	return maxi(0, int(SaveManager.data.class_progression.get(target, {}).get("xp", 0)))

func account_xp() -> int:
	return character_xp()

func level_cost(level: int) -> int:
	return int(140.0 + float(level - 1) * 25.0 + pow(float(level - 1), 1.25) * 7.0)

func character_level(id: String = "") -> int:
	var remaining := character_xp(id)
	var level := 1
	while level < MAX_LEVEL and remaining >= level_cost(level):
		remaining -= level_cost(level)
		level += 1
	return level

func account_level() -> int:
	return character_level()

func xp_into_level(id: String = "") -> int:
	var remaining := character_xp(id)
	for level in range(1, character_level(id)):
		remaining -= level_cost(level)
	return remaining

func xp_for_next_level() -> int:
	return level_cost(character_level())

func allocated(id: String = "") -> Array:
	var target := class_id if id.is_empty() else id
	return SaveManager.data.class_progression.get(target, {}).get("talents", ROOTS)

func is_allocated(id: String) -> bool:
	return allocated().has(id)

func spent_points(id: String = "") -> int:
	var target := class_id if id.is_empty() else id
	var tree: Dictionary = trees.get(target, {})
	var spent := 0
	for key in allocated(target):
		spent += int(tree.get(str(key), {}).get("cost", 0))
	return spent

func points() -> int:
	return maxi(0, character_level() - spent_points())

func can_allocate(id: String) -> bool:
	if not SaveManager.is_class_unlocked(class_id) or not trees[class_id].has(id) or is_allocated(id):
		return false
	var node: Dictionary = trees[class_id][id]
	if points() < int(node.cost) or character_level() < int(node.required_level):
		return false
	for parent in node.parents:
		if is_allocated(str(parent)):
			return true
	return false

func allocate(id: String) -> bool:
	if not can_allocate(id):
		return false
	var chosen := allocated().duplicate()
	chosen.append(id)
	SaveManager.data.class_progression[class_id].talents = chosen
	SaveManager.save_game()
	changed.emit()
	return true

func refund_all() -> void:
	SaveManager.data.class_progression[class_id].talents = ROOTS.duplicate()
	SaveManager.save_game()
	changed.emit()

func bonuses(id: String = "") -> Dictionary:
	var target := class_id if id.is_empty() else id
	var tree: Dictionary = trees.get(target, {})
	var result := BONUS_DEFAULTS.duplicate()
	result["class_power"] = false
	for key in allocated(target):
		var node: Dictionary = tree.get(str(key), {})
		if bool(node.get("power", false)):
			result.class_power = true
		var values: Dictionary = node.get("bonuses", {})
		for stat in values:
			result[stat] = float(result.get(stat, 0.0)) + float(values[stat])
	return result

func _validate_allocations() -> void:
	var dirty := false
	for target in trees:
		var tree: Dictionary = trees[target]
		var valid: Array = ROOTS.duplicate()
		var pending := allocated(str(target)).duplicate()
		for root in ROOTS: pending.erase(root)
		var budget := character_level(str(target))
		var advanced := true
		while advanced:
			advanced = false
			for raw_id in pending.duplicate():
				var key := str(raw_id)
				if not tree.has(key) or valid.has(key):
					pending.erase(raw_id)
					continue
				var node: Dictionary = tree[key]
				if int(node.cost) > budget or int(node.required_level) > character_level(str(target)):
					continue
				for parent in node.parents:
					if valid.has(str(parent)):
						valid.append(key)
						budget -= int(node.cost)
						pending.erase(raw_id)
						advanced = true
						break
		if valid != allocated(str(target)):
			SaveManager.data.class_progression[target].talents = valid
			dirty = true
	if dirty:
		SaveManager.save_game()

func describe_bonuses(values: Dictionary) -> String:
	var labels := {"damage_pct": "Dano causado", "health_pct": "Vida máxima", "attack_speed_pct": "Velocidade de ataque", "speed_pct": "Movimento", "crit_chance": "Chance de crítico", "bonus_gold_xp": "Ouro e experiência", "lifesteal": "Roubo de vida", "crit_multiplier": "Dano crítico", "power_damage": "Dano do poder supremo"}
	var lines := PackedStringArray()
	for key in values:
		var value := float(values[key])
		if labels.has(key):
			lines.append("%s +%s%%" % [labels[key], ("%.1f" % (value * 100.0)).trim_suffix(".0").replace(".", ",")])
		else:
			match str(key):
				"defense": lines.append("Defesa +%.1f" % value)
				"pickup_radius": lines.append("Alcance de coleta +%d" % roundi(value))
				"regen": lines.append("Regeneração +%.1f vida/s" % value)
				"cleave_targets": lines.append("Alvos por golpe +%d" % roundi(value))
				"projectile_pierce": lines.append("Perfuração de projéteis +%d" % roundi(value))
				"splash_radius": lines.append("Raio das explosões +%d" % roundi(value))
				"summon_duration": lines.append("Duração das invocações +%.1f s" % value)
	return "\n".join(lines)

func set_tree(id: String) -> void:
	if TREE_ORDER.has(id):
		tree_id = id
		nodes = subtrees[class_id][id]
		changed.emit()

func root_id(category: String = "") -> String:
	return BUILDER.root_id(tree_id if category.is_empty() else category)

func node_id(ring: int, slot: int, category: String = "general") -> String:
	return BUILDER.node_id(category, ring, slot)

func tree_allocated(category: String) -> int:
	var count := 0
	for id in allocated():
		if subtrees[class_id][category].has(id) and not ROOTS.has(id): count += 1
	return count

func refund_tree(category: String) -> void:
	var chosen: Array = allocated().duplicate()
	for id in chosen.duplicate():
		if subtrees[class_id][category].has(id) and not ROOTS.has(id): chosen.erase(id)
	SaveManager.data.class_progression[class_id].talents = chosen
	SaveManager.save_game()
	changed.emit()
