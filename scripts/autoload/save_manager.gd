extends Node

signal progression_changed

const SAVE_PATH := "user://ashenwild_save.json"
const DEFAULT_SAVE := {
	"gold": 0,
	"crystals": 0,
	"unlocked_classes": ["warrior", "mage", "ranger"],
	"unlocked_maps": ["verdant_reach"],
	"completed_maps": [],
	"account_xp": 0,
	"allocated_talents": ["origin"],
	"progression_version": 2,
	"talent_schema": 3,
	"class_progression": {},
	"campaign_progress": {},
	"highest_difficulty": 0,
	"selected_phase": 1,
	"selected_difficulty": 0,
	"last_account_xp_gained": 0,
	"equipment": ["field_blade", "moon_staff", "thorn_bow"],
	"equipment_quantities": {},
	"transmutation": {"attempts": {}, "failures": {}, "last_result": {}},
	"equipment_exchange": {"sold": 0, "gold": 0, "crystals": 0, "last_receipt": {}},
	"equipped": {"weapon": "field_blade"},
	"selected_class": "warrior",
	"class_loadouts": {
		"warrior": {"weapon": "field_blade"},
		"mage": {"weapon": "moon_staff"},
		"ranger": {"weapon": "thorn_bow"}
	},
	"upgrades": {"vitality": 0, "might": 0, "fortune": 0, "resilience": 0, "swiftness": 0, "crit_mastery": 0, "xp_boost": 0, "attack_speed": 0},
	"best_wave": 0,
	"settings": {"master": 0.8, "music": 0.65, "effects": 0.85, "ui_scale": 1.0, "fullscreen": false, "vibration": true, "resolution": "1280x720"},
	"bestiary_kills": {},
	"achievements": {},
	"relics": [],
	"equipped_relics": [],
	"statistics": {
		"total_playtime": 0.0,
		"total_kills": 0,
		"total_runs": 0,
		"total_gold_earned": 0,
		"total_damage_dealt": 0.0,
		"total_bosses_killed": 0,
		"total_elites_killed": 0,
		"total_waves_completed": 0,
		"best_run_kills": 0,
		"class_runs": {"warrior": 0, "mage": 0, "ranger": 0},
		"class_best_wave": {"warrior": 0, "mage": 0, "ranger": 0},
		"most_used_ability": "",
		"ability_uses": {},
		"favorite_enemy": "",
		"damage_by_class": {"warrior": 0.0, "mage": 0.0, "ranger": 0.0}
	},
	"forge_upgrades": {},
	"active_bounties": [],
	"completed_bounties": [],
	"bounty_progress": {},
	"pending_achievement_rewards": []
}

var data: Dictionary = {}

func _ready() -> void:
	load_game()

func load_game() -> void:
	data = DEFAULT_SAVE.duplicate(true)
	if not FileAccess.file_exists(SAVE_PATH):
		_initialize_progression(false)
		save_game()
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	var migrate_legacy := true
	if parsed is Dictionary:
		_merge_defaults(data, parsed)
		data.talent_schema = int(parsed.get("talent_schema", 0))
		migrate_legacy = int(parsed.get("progression_version", 0)) < 1
		if not parsed.has("class_loadouts") and parsed.get("equipped", {}) is Dictionary:
			data.class_loadouts.warrior = parsed.get("equipped", {}).duplicate(true)
	for starter in ["field_blade", "moon_staff", "thorn_bow"]:
		if not data.equipment.has(starter):
			data.equipment.append(starter)
	data.selected_class = str(data.get("selected_class", "warrior"))
	var loadouts: Dictionary = data.get("class_loadouts", {})
	for class_id in ["warrior", "mage", "ranger"]:
		if not loadouts.has(class_id):
			loadouts[class_id] = {}
	data.class_loadouts = loadouts
	_initialize_progression(migrate_legacy)
	data.equipped = loadout_for(str(data.selected_class)).duplicate(true)
	# Migração: garantir upgrades novos existam
	var default_upgrades := {"vitality": 0, "might": 0, "fortune": 0, "resilience": 0, "swiftness": 0, "crit_mastery": 0, "xp_boost": 0, "attack_speed": 0}
	for k in default_upgrades:
		if not data.upgrades.has(k):
			data.upgrades[k] = 0
	save_game()

func reset_progress() -> Error:
	if GameManager.run_active or NetworkSession.running:
		return ERR_BUSY
	var previous := data
	data = DEFAULT_SAVE.duplicate(true)
	_initialize_progression(false)
	var fresh := data
	data = previous
	# Replace the old file only after the entire fresh save has been written.
	var temporary := SAVE_PATH + ".reset_tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(fresh, "\t"))
	file.flush()
	var error := file.get_error()
	file.close()
	if error == OK:
		error = DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary), ProjectSettings.globalize_path(SAVE_PATH))
	if error != OK:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temporary))
		return error
	data = fresh
	progression_changed.emit()
	return OK

func _merge_defaults(target: Dictionary, source: Dictionary) -> void:
	for key in source:
		if target.has(key) and target[key] is Dictionary and source[key] is Dictionary:
			_merge_defaults(target[key], source[key])
		else:
			target[key] = source[key]

func save_game() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(data, "\t"))

# ═══════════════════════════════════════════════
# OURO E CRISTAIS
# ═══════════════════════════════════════════════
func grant_gold(amount: int) -> void:
	data.gold = int(data.get("gold", 0)) + maxi(0, amount)
	save_game()

func grant_crystals(amount: int) -> void:
	data.crystals = int(data.get("crystals", 0)) + maxi(0, amount)
	save_game()

func spend_gold(amount: int) -> bool:
	if amount < 0 or int(data.get("gold", 0)) < amount:
		return false
	data.gold -= amount
	save_game()
	return true

func spend_crystals(amount: int) -> bool:
	if amount < 0 or int(data.get("crystals", 0)) < amount:
		return false
	data.crystals -= amount
	save_game()
	return true

# ═══════════════════════════════════════════════
# UPGRADES PERMANENTES
# ═══════════════════════════════════════════════
func buy_upgrade(upgrade_id: String, _displayed_price: int = -1) -> bool:
	if GameManager.run_active or not PermanentUpgrades.can_buy(upgrade_id, data.upgrades):
		return false
	var price := PermanentUpgrades.cost(upgrade_id, data.upgrades)
	if int(data.gold) < price:
		return false
	data.gold = int(data.gold) - price
	data.upgrades[upgrade_id] = upgrade_level(upgrade_id) + 1
	save_game()
	return true

func upgrade_level(id: String) -> int:
	return int(data.upgrades.get(id, 0))

# ═══════════════════════════════════════════════
# EQUIPAMENTOS
# ═══════════════════════════════════════════════
func unlock_equipment(item_id: String) -> void:
	if not data.equipment.has(item_id):
		data.equipment.append(item_id)
		data.equipment_quantities[item_id] = 1
		save_game()

func equipment_quantity(id: String) -> int:
	return TransmutationRules.quantity(data, id)

func transmute_equipment(inputs: Array, owner: String) -> Dictionary:
	if GameManager.run_active or NetworkSession.running:
		return {"ok": false, "reason": "A fusão não pode ser usada durante uma partida."}
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var transaction := TransmutationRules.resolve(data, inputs, owner, rng)
	if not bool(transaction.ok): return transaction
	var error := _commit_inventory_transaction(transaction.save)
	if error != OK:
		return {"ok": false, "reason": "Não foi possível salvar a fusão. Seus itens foram preservados."}
	return {"ok": true, "result": transaction.result.duplicate(true)}

func exchange_equipment(id: String, amount: int, owner: String) -> Dictionary:
	if GameManager.run_active or NetworkSession.running:
		return {"ok": false, "reason": "Trocas não podem ser realizadas durante uma partida."}
	var transaction := EquipmentExchange.resolve(data, id, amount, owner)
	if not bool(transaction.ok): return transaction
	if _commit_inventory_transaction(transaction.save) != OK:
		return {"ok": false, "reason": "Não foi possível salvar. O item e suas moedas foram preservados."}
	return {"ok": true, "receipt": transaction.receipt.duplicate(true)}

func acknowledge_transmutation() -> Error:
	var updated := data.duplicate(true)
	if updated.transmutation.last_result.is_empty(): return OK
	updated.transmutation.last_result.pending = false
	return _commit_inventory_transaction(updated)

func _commit_inventory_transaction(updated: Dictionary) -> Error:
	var temporary := SAVE_PATH + ".inventory_tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null: return FileAccess.get_open_error()
	file.store_string(JSON.stringify(updated, "\t"))
	file.flush()
	var error := file.get_error()
	file.close()
	if error == OK:
		error = DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary), ProjectSettings.globalize_path(SAVE_PATH))
	if error != OK:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temporary))
		return error
	data = updated
	progression_changed.emit()
	return OK

func set_selected_class(class_id: String) -> void:
	if not is_class_unlocked(class_id):
		return
	if not data.class_loadouts.has(class_id):
		data.class_loadouts[class_id] = {}
	data.selected_class = class_id
	data.equipped = data.class_loadouts[class_id].duplicate(true)
	save_game()

func loadout_for(class_id: String) -> Dictionary:
	var loadouts: Dictionary = data.get("class_loadouts", {})
	var loadout: Variant = loadouts.get(class_id, {})
	return loadout if loadout is Dictionary else {}

func equip_item(slot: String, item_id: String, class_id: String = "") -> void:
	if data.equipment.has(item_id):
		var target_class := class_id if not class_id.is_empty() else str(data.get("selected_class", "warrior"))
		if not is_class_unlocked(target_class):
			return
		var loadouts: Dictionary = data.get("class_loadouts", {})
		var loadout: Dictionary = loadouts.get(target_class, {})
		loadout[slot] = item_id
		loadouts[target_class] = loadout
		data.class_loadouts = loadouts
		if target_class == str(data.get("selected_class", "warrior")):
			data.equipped = loadout.duplicate(true)
		save_game()

# ═══════════════════════════════════════════════
# RELÍQUIAS
# ═══════════════════════════════════════════════
func unlock_relic(relic_id: String) -> void:
	var relics: Array = data.get("relics", [])
	if not relics.has(relic_id):
		relics.append(relic_id)
		data.relics = relics
		save_game()

func equip_relic(relic_id: String) -> bool:
	if not data.relics.has(relic_id):
		return false
	var equipped: Array = data.get("equipped_relics", [])
	if equipped.has(relic_id):
		return false
	if equipped.size() >= 3:  # Max 3 relíquias equipadas
		return false
	equipped.append(relic_id)
	data.equipped_relics = equipped
	save_game()
	return true

func unequip_relic(relic_id: String) -> void:
	var equipped: Array = data.get("equipped_relics", [])
	equipped.erase(relic_id)
	data.equipped_relics = equipped
	save_game()

func has_relic(relic_id: String) -> bool:
	return data.get("relics", []).has(relic_id)

func is_relic_equipped(relic_id: String) -> bool:
	return data.get("equipped_relics", []).has(relic_id)

func get_equipped_relics() -> Array:
	return data.get("equipped_relics", [])

# ═══════════════════════════════════════════════
# FORJA
# ═══════════════════════════════════════════════
func forge_item(recipe_id: String) -> bool:
	var recipe: Dictionary = ContentCatalog.get_forge_recipe(recipe_id)
	if recipe.is_empty():
		return false
	if not can_forge(recipe_id): return false
	# Verificar se tem os itens
	for ing in recipe.get("ingredients", []):
		if equipment_quantity(str(ing.id)) < int(ing.get("qty", 1)):
			return false
	# Verificar custos
	if int(data.get("crystals", 0)) < int(recipe.get("crystal_cost", 0)):
		return false
	if int(data.get("gold", 0)) < int(recipe.get("gold_cost", 0)):
		return false
	# Remover ingredientes (apenas os não básicos de starter)
	var starters := _starter_weapons()
	for ing in recipe.get("ingredients", []):
		if not starters.has(ing.id):
			TransmutationRules.consume(data, str(ing.id), int(ing.get("qty", 1)))
	var result_item: EquipmentData = ContentCatalog.equipment.get(str(recipe.result))
	for owner in data.class_loadouts:
		var loadout: Dictionary = data.class_loadouts[owner]
		for slot in loadout.keys():
			if data.equipment.has(str(loadout[slot])): continue
			if result_item != null and str(result_item.slot) == str(slot) and (result_item.class_id == &"" or str(result_item.class_id) == str(owner)):
				loadout[slot] = str(result_item.id)
			else: loadout.erase(slot)
	data.equipped = loadout_for(str(data.selected_class)).duplicate(true)
	# Cobrar
	data.crystals = int(data.get("crystals", 0)) - int(recipe.get("crystal_cost", 0))
	data.gold = int(data.get("gold", 0)) - int(recipe.get("gold_cost", 0))
	# Dar o resultado
	unlock_equipment(recipe.result)
	# Registrar na forja
	var forged: Dictionary = data.get("forge_upgrades", {})
	forged[recipe_id] = int(forged.get(recipe_id, 0)) + 1
	data.forge_upgrades = forged
	save_game()
	# Verificar conquistas de forja
	_check_forge_achievements()
	return true

func can_forge(recipe_id: String) -> bool:
	var recipe: Dictionary = ContentCatalog.get_forge_recipe(recipe_id)
	if recipe.is_empty():
		return false
	if bool(recipe.get("generated", false)):
		var item: EquipmentData = ContentCatalog.equipment.get(str(recipe.result))
		if item == null or not is_class_unlocked(str(item.class_id)) or int(data.highest_difficulty) < item.required_difficulty or not phase_unlocked(str(item.region_id), 1, item.required_difficulty): return false
		if int(data.forge_upgrades.get(recipe_id, 0)) > 0 or data.equipment.has(str(recipe.result)): return false
	for ing in recipe.get("ingredients", []):
		if equipment_quantity(str(ing.id)) < int(ing.get("qty", 1)):
			return false
	if int(data.get("crystals", 0)) < int(recipe.get("crystal_cost", 0)):
		return false
	if int(data.get("gold", 0)) < int(recipe.get("gold_cost", 0)):
		return false
	return true

func _check_forge_achievements() -> void:
	var forged: Dictionary = data.get("forge_upgrades", {})
	var total_forged := 0
	for k in forged:
		total_forged += int(forged[k])
	if total_forged >= 1:
		unlock_achievement("first_forge")
	# Verificar se forjou algo lendário
	for r in ContentCatalog.forge_recipes:
		if r.get("rarity_result", "") == "legendary":
			if int(data.forge_upgrades.get(r.id, 0)) > 0:
				unlock_achievement("master_forge")
				break

# ═══════════════════════════════════════════════
# BOUNTIES / CAÇADAS
# ═══════════════════════════════════════════════
func activate_bounty(bounty_id: String) -> bool:
	var active: Array = data.get("active_bounties", [])
	var completed: Array = data.get("completed_bounties", [])
	if active.has(bounty_id) or completed.has(bounty_id):
		return false
	if active.size() >= 3:  # Max 3 bounties ativas
		return false
	active.append(bounty_id)
	data.active_bounties = active
	save_game()
	return true

func record_bounty_kill(enemy_id: String) -> void:
	var active: Array = data.get("active_bounties", [])
	var progress: Dictionary = data.get("bounty_progress", {})
	for bounty_id in active:
		for b in ContentCatalog.bounties:
			if b.id == bounty_id and b.target == enemy_id:
				progress[bounty_id] = int(progress.get(bounty_id, 0)) + 1
				# Verificar se completou
				if int(progress[bounty_id]) >= int(b.target_count):
					_complete_bounty(bounty_id, b)
	data.bounty_progress = progress
	# Não faz save aqui — será feito em lote pelo game

func _complete_bounty(bounty_id: String, bounty: Dictionary) -> void:
	var active: Array = data.get("active_bounties", [])
	active.erase(bounty_id)
	data.active_bounties = active
	var completed: Array = data.get("completed_bounties", [])
	completed.append(bounty_id)
	data.completed_bounties = completed
	# Guardar recompensas pendentes
	var pending: Array = data.get("pending_achievement_rewards", [])
	pending.append({"type": "bounty", "id": bounty_id, "gold": bounty.get("reward_gold", 0), "crystals": bounty.get("reward_crystals", 0)})
	data.pending_achievement_rewards = pending

func get_bounty_progress(bounty_id: String) -> int:
	return int(data.get("bounty_progress", {}).get(bounty_id, 0))

# ═══════════════════════════════════════════════
# CONQUISTAS
# ═══════════════════════════════════════════════
func unlock_achievement(achievement_id: String) -> bool:
	var achs: Dictionary = data.get("achievements", {})
	if achs.has(achievement_id):
		return false
	achs[achievement_id] = true
	data.achievements = achs
	# Dar recompensas automaticamente
	for ach in ContentCatalog.achievements:
		if ach.id == achievement_id:
			if int(ach.get("reward_gold", 0)) > 0:
				data.gold = int(data.get("gold", 0)) + int(ach.reward_gold)
			if int(ach.get("reward_crystals", 0)) > 0:
				data.crystals = int(data.get("crystals", 0)) + int(ach.reward_crystals)
			if not str(ach.get("reward_relic", "")).is_empty():
				unlock_relic(str(ach.reward_relic))
			break
	save_game()
	return true

func has_achievement(achievement_id: String) -> bool:
	return data.get("achievements", {}).has(achievement_id)

func get_achievement_count() -> int:
	return data.get("achievements", {}).size()

# ═══════════════════════════════════════════════
# ESTATÍSTICAS
# ═══════════════════════════════════════════════
func record_run(wave: int, gold_earned: int, playtime: float = 0.0, kills: int = 0, class_id: String = "", bosses: int = 0, elites: int = 0, damage: float = 0.0, victory: bool = false, xp_multiplier: float = 1.0) -> void:
	data.gold = int(data.get("gold", 0)) + gold_earned
	data.best_wave = maxi(int(data.get("best_wave", 0)), wave)

	var stats: Dictionary = data.get("statistics", {})
	stats["total_runs"] = int(stats.get("total_runs", 0)) + 1
	stats["total_gold_earned"] = int(stats.get("total_gold_earned", 0)) + gold_earned
	stats["total_playtime"] = float(stats.get("total_playtime", 0.0)) + playtime
	stats["total_damage_dealt"] = float(stats.get("total_damage_dealt", 0.0)) + maxf(0.0, damage)
	stats["total_kills"] = int(stats.get("total_kills", 0)) + kills
	stats["total_bosses_killed"] = int(stats.get("total_bosses_killed", 0)) + bosses
	stats["total_elites_killed"] = int(stats.get("total_elites_killed", 0)) + elites
	stats["total_waves_completed"] = int(stats.get("total_waves_completed", 0)) + maxi(0, wave - 1) + (1 if victory else 0)
	stats["best_run_kills"] = maxi(int(stats.get("best_run_kills", 0)), kills)

	if not class_id.is_empty():
		var class_runs: Dictionary = stats.get("class_runs", {})
		class_runs[class_id] = int(class_runs.get(class_id, 0)) + 1
		stats["class_runs"] = class_runs

		var class_best: Dictionary = stats.get("class_best_wave", {})
		class_best[class_id] = maxi(int(class_best.get(class_id, 0)), wave)
		stats["class_best_wave"] = class_best

		var dmg_by_class: Dictionary = stats.get("damage_by_class", {})
		dmg_by_class[class_id] = float(dmg_by_class.get(class_id, 0.0)) + damage
		stats["damage_by_class"] = dmg_by_class

	data.statistics = stats
	var earned_xp := roundi(run_account_xp(wave, playtime, kills, bosses, elites) * maxf(1.0, xp_multiplier))
	data.account_xp = int(data.get("account_xp", 0)) + earned_xp
	data.last_account_xp_gained = earned_xp
	var target_class := class_id if ContentCatalog.classes.has(class_id) else str(data.selected_class)
	var progress: Dictionary = data.class_progression[target_class]
	progress.xp = int(progress.xp) + earned_xp
	progress.last_xp = earned_xp
	_check_run_achievements(wave, kills, class_id, bosses)
	save_game()
	progression_changed.emit()

func _check_run_achievements(wave: int, kills: int, class_id: String, bosses: int) -> void:
	var stats: Dictionary = data.get("statistics", {})
	var total_kills := int(stats.get("total_kills", 0))

	if total_kills >= 1:
		unlock_achievement("first_blood")
	if total_kills >= 100:
		unlock_achievement("slayer_100")
	if total_kills >= 1000:
		unlock_achievement("slayer_1000")
	if wave >= 5:
		unlock_achievement("survivor_5")
	if int(stats.get("total_waves_completed", 0)) >= 10:
		unlock_achievement("survivor_10")
	if bosses > 0:
		unlock_achievement("boss_killer")
	if int(stats.get("total_elites_killed", 0)) >= 10:
		unlock_achievement("elite_hunter")

	var gold_total := int(data.get("gold", 0))
	if gold_total >= 1000:
		unlock_achievement("rich")
	if gold_total >= 5000:
		unlock_achievement("very_rich")

	# Class mastery
	var class_runs: Dictionary = stats.get("class_runs", {})
	for id in ContentCatalog.CLASS_ORDER:
		if int(class_runs.get(id, 0)) >= 5:
			unlock_achievement("%s_mastery" % id)

	# The starter classes each reach the regional boss on wave five.
	var class_best: Dictionary = stats.get("class_best_wave", {})
	if int(class_best.get("warrior", 0)) >= 5 and int(class_best.get("mage", 0)) >= 5 and int(class_best.get("ranger", 0)) >= 5:
		unlock_achievement("wave_master")

	# Beast hunter: checar kills
	_check_beast_hunter()

func _check_beast_hunter() -> void:
	var kills: Dictionary = data.get("bestiary_kills", {})
	for enemy_data in ContentCatalog.enemies.values():
		if bool(enemy_data.boss):
			continue
		if int(kills.get(str(enemy_data.id), 0)) < 1:
			return
	unlock_achievement("beast_hunter")

func record_kill(enemy_id: String) -> void:
	var bestiary: Dictionary = data.get("bestiary_kills", {})
	bestiary[enemy_id] = int(bestiary.get(enemy_id, 0)) + 1
	data.bestiary_kills = bestiary

	# Bounties
	record_bounty_kill(enemy_id)

func record_ability_use(ability_id: String) -> void:
	var stats: Dictionary = data.get("statistics", {})
	var uses: Dictionary = stats.get("ability_uses", {})
	uses[ability_id] = int(uses.get(ability_id, 0)) + 1
	# Atualizar favorita
	var most := ""
	var most_count := 0
	for k in uses:
		if int(uses[k]) > most_count:
			most_count = int(uses[k])
			most = k
	stats["ability_uses"] = uses
	stats["most_used_ability"] = most
	data.statistics = stats

# ═══════════════════════════════════════════════
# HELPERS
# ═══════════════════════════════════════════════
func get_stat(key: String, default: Variant = 0) -> Variant:
	return data.get("statistics", {}).get(key, default)

func _initialize_progression(migrate_legacy: bool) -> void:
	data.account_xp = maxi(0, int(data.get("account_xp", 0)))
	if migrate_legacy:
		var legacy_stats: Dictionary = data.get("statistics", {})
		var previous_xp := run_account_xp(int(legacy_stats.get("total_waves_completed", 0)), float(legacy_stats.get("total_playtime", 0.0)), int(legacy_stats.get("total_kills", 0)), int(legacy_stats.get("total_bosses_killed", 0)), int(legacy_stats.get("total_elites_killed", 0)))
		data.account_xp = maxi(int(data.account_xp), previous_xp)
	var migrate_class_xp: bool = data.get("class_progression", {}).is_empty()
	if not data.get("allocated_talents", []) is Array:
		data.allocated_talents = []
	if not data.allocated_talents.has("origin"):
		data.allocated_talents.push_front("origin")
	var loadouts: Dictionary = data.get("class_loadouts", {})
	var stats: Dictionary = data.get("statistics", {})
	for class_id in ContentCatalog.CLASS_ORDER:
		if not loadouts.has(class_id):
			loadouts[class_id] = {}
		if is_class_unlocked(class_id):
			var class_data: Resource = ContentCatalog.classes.get(class_id)
			var starter := str(class_data.starter_weapon)
			if not starter.is_empty() and ContentCatalog.equipment.has(starter):
				if not data.equipment.has(starter):
					data.equipment.append(starter)
				if loadouts[class_id].is_empty():
					loadouts[class_id] = {"weapon": starter}
		for key in ["class_runs", "class_best_wave", "damage_by_class"]:
			var per_class: Dictionary = stats.get(key, {})
			if not per_class.has(class_id):
				per_class[class_id] = 0
			stats[key] = per_class
	data.class_loadouts = loadouts
	data.statistics = stats
	if not is_class_unlocked(str(data.get("selected_class", "warrior"))):
		data.selected_class = "warrior"
	var progression: Dictionary = data.get("class_progression", {})
	for class_id in ContentCatalog.CLASS_ORDER:
		if not progression.get(class_id, {}) is Dictionary or not progression.has(class_id):
			progression[class_id] = {"xp": 0, "talents": ["origin", "fury_origin", "vigor_origin", "cunning_origin", "survival_origin", "technique_origin"], "last_xp": 0}
		var entry: Dictionary = progression[class_id]
		if int(data.get("talent_schema", 0)) < 3:
			entry.talents = ["origin", "fury_origin", "vigor_origin", "cunning_origin", "survival_origin", "technique_origin"]
		entry.xp = maxi(0, int(entry.get("xp", 0)))
		entry.last_xp = maxi(0, int(entry.get("last_xp", 0)))
		if not entry.get("talents", []) is Array:
			entry.talents = ["origin"]
		if not entry.has("talents"):
			entry.talents = ["origin"]
	if migrate_class_xp:
		# Preserve legacy experience once, on the selected character; old points are refunded.
		progression[str(data.selected_class)].xp = int(data.account_xp)
	data.talent_schema = 3
	data.class_progression = progression
	if data.get("campaign_progress", {}).is_empty():
		var cleared := 0
		for map_id in ContentCatalog.MAP_ORDER:
			if not data.get("completed_maps", []).has(str(map_id)):
				break
			cleared += CampaignRules.PHASES_PER_REGION
		data.campaign_progress = {"0": cleared}
		data.highest_difficulty = 1 if cleared == CampaignRules.TOTAL_PHASES else 0
	data.highest_difficulty = maxi(0, int(data.get("highest_difficulty", 0)))
	data.selected_difficulty = clampi(int(data.get("selected_difficulty", 0)), 0, int(data.highest_difficulty))
	data.selected_phase = clampi(int(data.get("selected_phase", 1)), 1, 10)
	data.progression_version = 2

func _starter_weapons() -> Array:
	var starters: Array = []
	for class_data in ContentCatalog.classes.values():
		var starter := str(class_data.starter_weapon)
		if not starter.is_empty():
			starters.append(starter)
	return starters

func is_class_unlocked(class_id: String) -> bool:
	return ContentCatalog.classes.has(class_id) and data.get("unlocked_classes", []).has(class_id)

func unlock_class(class_id: String, currency: String = "gold") -> bool:
	if not ContentCatalog.classes.has(class_id) or is_class_unlocked(class_id):
		return false
	if currency == "gems":
		currency = "crystals"
	if currency != "gold" and currency != "crystals":
		return false
	var class_data: Resource = ContentCatalog.classes[class_id]
	var cost := int(class_data.cost_gold) if currency == "gold" else int(class_data.cost_crystals)
	if cost <= 0 or int(data.get(currency, 0)) < cost:
		return false
	data[currency] = int(data.get(currency, 0)) - cost
	data.unlocked_classes.append(class_id)
	var starter := str(class_data.starter_weapon)
	if not starter.is_empty() and ContentCatalog.equipment.has(starter):
		if not data.equipment.has(starter):
			data.equipment.append(starter)
		data.class_loadouts[class_id] = {"weapon": starter}
	save_game()
	progression_changed.emit()
	return true

func is_map_unlocked(map_id: String) -> bool:
	return ContentCatalog.maps.has(map_id) and data.get("unlocked_maps", []).has(map_id)

func complete_map(map_id: String) -> void:
	# Compatibility entry point: a map victory now completes the selected phase.
	complete_phase(map_id, int(data.get("selected_phase", 1)), int(data.get("selected_difficulty", 0)))

func campaign_cleared(tier: int) -> int:
	return clampi(int(data.get("campaign_progress", {}).get(str(tier), 0)), 0, CampaignRules.TOTAL_PHASES)

func phase_unlocked(map_id: String, phase: int, tier: int) -> bool:
	var index := CampaignRules.ordinal(map_id, phase)
	return index >= 0 and tier >= 0 and tier <= int(data.highest_difficulty) and index <= campaign_cleared(tier)

func phase_completed(map_id: String, phase: int, tier: int) -> bool:
	var index := CampaignRules.ordinal(map_id, phase)
	return index >= 0 and tier >= 0 and index < campaign_cleared(tier)

func complete_phase(map_id: String, phase: int, tier: int) -> bool:
	if not phase_unlocked(map_id, phase, tier):
		return false
	var cleared := maxi(campaign_cleared(tier), CampaignRules.ordinal(map_id, phase) + 1)
	data.campaign_progress[str(tier)] = cleared
	if cleared == CampaignRules.TOTAL_PHASES:
		data.highest_difficulty = maxi(int(data.highest_difficulty), tier + 1)
		if not data.campaign_progress.has(str(tier + 1)):
			data.campaign_progress[str(tier + 1)] = 0
		unlock_achievement("legend")
	if phase == CampaignRules.PHASES_PER_REGION:
		_mark_region_completed(map_id)
	save_game()
	progression_changed.emit()
	return true

func _mark_region_completed(map_id: String) -> void:
	var completed: Array = data.get("completed_maps", [])
	if not completed.has(map_id):
		completed.append(map_id)
	data.completed_maps = completed
	if map_id != "verdant_reach":
		unlock_achievement("region_%s" % map_id)
	var index: int = ContentCatalog.MAP_ORDER.find(map_id)
	if index >= 0 and index + 1 < ContentCatalog.MAP_ORDER.size():
		var next_map := str(ContentCatalog.MAP_ORDER[index + 1])
		if not data.unlocked_maps.has(next_map):
			data.unlocked_maps.append(next_map)
	var conquered_all := true
	for id in ContentCatalog.MAP_ORDER:
		if not completed.has(str(id)):
			conquered_all = false
			break
	if conquered_all:
		unlock_achievement("legend")
	save_game()

func run_account_xp(wave: int, playtime: float, kills: int, bosses: int, elites: int) -> int:
	# Account experience is committed once, at the end of an expedition.
	return maxi(0, kills) * 2 + maxi(0, bosses) * 150 + maxi(0, elites) * 8 + maxi(0, wave) * 12 + int(maxf(0.0, playtime) / 10.0) * 4
