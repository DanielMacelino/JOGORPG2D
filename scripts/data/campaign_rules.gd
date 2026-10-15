extends RefCounted
class_name CampaignRules

const PHASES_PER_REGION := 10
const MAP_ORDER: Array[StringName] = [&"verdant_reach", &"hollow_cairn", &"ember_crater", &"black_keep", &"frostwood", &"sunken_mire"]
const TOTAL_PHASES := 60
const DIFFICULTIES := ["Fácil", "Médio", "Moderado", "Difícil", "Épico", "Semideus", "Deus"]
const PHASE_NAMES := ["Limiar", "Maré da noite", "Caçada aos marcados", "Altar da vigília", "Fendas antigas", "Conselho dos elites", "Último bastião", "Tempestade arcana", "Cerco dos campeões", "Trono da dimensão"]
const ENCOUNTERS := ["survival", "horde", "hunt", "altar", "rifts", "hunt", "altar", "anomaly", "siege", "throne"]

static func difficulty_name(tier: int) -> String:
	if tier < 7:
		return DIFFICULTIES[clampi(tier, 0, 6)]
	var remaining := tier - 5
	if remaining >= 4000:
		return "Deus %d" % remaining
	var roman := ""
	for pair in [[1000, "M"], [900, "CM"], [500, "D"], [400, "CD"], [100, "C"], [90, "XC"], [50, "L"], [40, "XL"], [10, "X"], [9, "IX"], [5, "V"], [4, "IV"], [1, "I"]]:
		while remaining >= int(pair[0]):
			roman += str(pair[1])
			remaining -= int(pair[0])
	return "Deus " + roman

static func ordinal(map_id: String, phase: int) -> int:
	var index: int = MAP_ORDER.find(map_id)
	return index * PHASES_PER_REGION + phase - 1 if index >= 0 and phase >= 1 and phase <= PHASES_PER_REGION else -1

static func strength(tier: int, phase: int) -> float:
	return (1.0 + float(phase - 1) * 0.055) * pow(1.32, minf(float(tier), 40.0)) * (1.0 + maxf(0.0, float(tier - 40)) * 0.15)

static func reward_multiplier(tier: int, phase: int) -> float:
	return (1.0 + float(tier) * 0.25 + float(phase - 1) * 0.035) * (1.65 if phase == 10 else (1.25 if phase == 5 else 1.0))

static func phase_objective(phase: int) -> String:
	match ENCOUNTERS[clampi(phase - 1, 0, 9)]:
		"horde": return "Enfrente hordas extras e derrote o guardião."
		"hunt": return "Elimine %d campeões marcados e derrote o guardião." % (3 if phase == 3 else 5)
		"altar": return "Proteja o altar dos invasores até derrotar o guardião."
		"rifts": return "DESAFIO DA METADE · Sele três fendas e enfrente o guardião fortalecido. +25% de ganhos; repita para aprimorar seu personagem."
		"anomaly": return "Atravesse a tempestade arcana e derrote o guardião."
		"siege": return "Elimine quatro campeões marcados durante o cerco e derrote o guardião."
		"throne": return "TRONO DO SOBERANO · Chefe com vida massiva, ataques exclusivos e fúria final aos 25% de vida. +65% de ganhos."
	return "Sobreviva às quatro ondas e derrote o guardião."

static func expedition(map_id: String, phase: int, tier: int) -> MapData:
	var catalog: Node = (Engine.get_main_loop() as SceneTree).root.get_node("ContentCatalog")
	var base: MapData = catalog.maps.get(map_id, catalog.maps["verdant_reach"])
	var stage := base.duplicate() as MapData
	stage.phase_number = clampi(phase, 1, PHASES_PER_REGION)
	stage.difficulty_tier = maxi(0, tier)
	stage.phase_title = PHASE_NAMES[stage.phase_number - 1]
	stage.encounter = StringName(ENCOUNTERS[stage.phase_number - 1])
	stage.difficulty *= strength(stage.difficulty_tier, stage.phase_number)
	stage.duration *= 1.20 + float(stage.phase_number - 1) * (0.20 / 9.0)
	if stage.phase_number == 10:
		stage.difficulty *= 1.15
		if map_id == "verdant_reach": stage.boss_id = &"minotaur"
	return stage
