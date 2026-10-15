extends RefCounted
## Permanent purchases and relic discoveries belong to one character, not the account.
const RELIC_REQUIREMENTS := {
	"first_blood": "Derrote um inimigo com este personagem.",
	"boss_killer": "Derrote um chefe com este personagem.",
	"rich": "Ganhe 1.000 de ouro em expedições com este personagem.",
	"survivor_10": "Complete 10 ondas com este personagem.",
	"elite_hunter": "Derrote 10 elites com este personagem.",
	"wave_master": "Complete 25 ondas com este personagem.",
	"lore_seeker": "Use cinco habilidades diferentes na mesma expedição com este personagem.",
	"beast_hunter": "Derrote cada espécie comum e elite com este personagem.",
	"legend": "Vença a fase 10 das seis regiões com este personagem."}

static func fresh() -> Dictionary:
	var levels := {}
	for id in PermanentUpgrades.IDS: levels[id] = 0
	return {"upgrades": levels, "relics": [], "equipped_relics": [], "relic_progress": {"kills": 0, "bosses": 0, "elites": 0, "gold": 0, "waves": 0, "skills": 0, "species": {}, "regions": []}}

static func initialize(save: Dictionary) -> void:
	if not save.get("character_meta", {}) is Dictionary: save.character_meta = {}
	if not save.has("character_meta"): save.character_meta = {}
	for owner in ContentCatalog.CLASS_ORDER:
		if not save.character_meta.get(str(owner), {}) is Dictionary or not save.character_meta.has(str(owner)):
			save.character_meta[str(owner)] = fresh()
	if int(save.get("character_meta_schema", 0)) < 1:
		# Refund using the previous version's prices, once, before clearing global purchases.
		var refund := PermanentUpgrades.legacy_refund(save.get("upgrades", {}))
		save.gold = int(save.get("gold", 0)) + refund
		save.character_upgrade_refund = refund
		var owner := str(save.get("selected_class", "warrior"))
		if not save.character_meta.has(owner): owner = "warrior"
		var target: Dictionary = save.character_meta[owner]
		for id in save.get("relics", []):
			if not ContentCatalog.get_relic(str(id)).is_empty() and not target.relics.has(id): target.relics.append(id)
		for id in save.get("equipped_relics", []):
			if target.relics.has(id) and not target.equipped_relics.has(id) and target.equipped_relics.size() < 3: target.equipped_relics.append(id)
		save.character_meta_schema = 1
	# Legacy fields remain empty for older tooling; gameplay never reads them.
	save.upgrades = fresh().upgrades
	save.relics = []
	save.equipped_relics = []

static func profile(save: Dictionary, owner: String) -> Dictionary:
	if not ContentCatalog.classes.has(owner): owner = str(save.get("selected_class", "warrior"))
	if not save.has("character_meta"): initialize(save)
	if not save.character_meta.has(owner): save.character_meta[owner] = fresh()
	return save.character_meta[owner]

static func award_relics(entry: Dictionary) -> void:
	var progress: Dictionary = entry.relic_progress
	var all_species := true
	for enemy in ContentCatalog.enemies.values():
		if not enemy.boss and int(progress.species.get(str(enemy.id), 0)) == 0:
			all_species = false
			break
	var goals := {"first_blood": int(progress.kills) >= 1, "boss_killer": int(progress.bosses) >= 1, "rich": int(progress.gold) >= 1000, "survivor_10": int(progress.waves) >= 10, "elite_hunter": int(progress.elites) >= 10, "wave_master": int(progress.waves) >= 25, "lore_seeker": int(progress.skills) >= 5, "beast_hunter": all_species, "legend": progress.regions.size() >= 6}
	for relic in ContentCatalog.relics:
		if bool(goals.get(str(relic.unlock), false)) and not entry.relics.has(str(relic.id)):
			entry.relics.append(str(relic.id))
