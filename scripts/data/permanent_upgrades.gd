extends RefCounted
class_name PermanentUpgrades
## Ten purchases in every attribute unlock the next shared mastery tier.
const STEPS := 10
const RATES := [0.001, 0.005, 0.01, 0.015, 0.02, 0.025, 0.03]
const NAMES := ["Aprendiz", "Iniciado", "Veterano", "Mestre", "Ascendente", "Semideus", "Divino"]
const IDS := ["vitality", "might", "fortune", "resilience", "swiftness", "crit_mastery", "xp_boost", "attack_speed"]
const MAX_RANK := 70

static func tier(levels: Dictionary) -> int:
	var lowest := MAX_RANK
	for id in IDS:
		lowest = mini(lowest, clampi(int(levels.get(id, 0)), 0, MAX_RANK))
	return mini(RATES.size() - 1, floori(float(lowest) / STEPS))

static func bonus(rank: int) -> float:
	var total := 0.0
	for index in RATES.size():
		total += clampi(rank - index * STEPS, 0, STEPS) * float(RATES[index])
	return total

static func effective_bonus(id: String, rank: int) -> float:
	if id not in ["resilience", "crit_mastery"]:
		return bonus(rank)
	# Diminishing returns keep every purchase useful without reaching immunity or guaranteed criticals.
	var remaining := 1.0
	for index in RATES.size():
		remaining *= pow(1.0 - float(RATES[index]), clampi(rank - index * STEPS, 0, STEPS))
	return 1.0 - remaining

static func can_buy(id: String, levels: Dictionary) -> bool:
	return IDS.has(id) and int(levels.get(id, 0)) < (tier(levels) + 1) * STEPS

static func cost(id: String, levels: Dictionary) -> int:
	var base := 100
	for entry in ContentCatalog.upgrades:
		if entry.id == id:
			base = int(entry.base_cost)
	var rank := clampi(int(levels.get(id, 0)), 0, MAX_RANK)
	var stage := mini(RATES.size() - 1, floori(float(rank) / STEPS))
	return roundi(base * 0.25 * pow(1.9, stage) * (1.0 + (rank % STEPS) * 0.12))

static func progress(levels: Dictionary) -> int:
	var stage := tier(levels)
	var total := 0
	for id in IDS:
		total += clampi(int(levels.get(id, 0)) - stage * STEPS, 0, STEPS)
	return total

static func percent(value: float) -> String:
	return ("%.1f" % (value * 100.0)).trim_suffix(".0").replace(".", ",") + "%"
