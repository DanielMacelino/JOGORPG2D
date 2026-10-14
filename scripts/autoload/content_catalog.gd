extends Node

const CLASS_DATA = preload("res://scripts/data/class_data.gd")
const ABILITY_DATA = preload("res://scripts/data/ability_data.gd")
const ENEMY_DATA = preload("res://scripts/data/enemy_data.gd")
const EQUIPMENT_DATA = preload("res://scripts/data/equipment_data.gd")
const MAP_DATA = preload("res://scripts/data/map_data.gd")
const WAVE_DATA = preload("res://scripts/data/wave_data.gd")
const CLASS_ORDER: Array[StringName] = [&"warrior", &"mage", &"ranger", &"assassin", &"druid", &"paladin"]
const MAP_ORDER: Array[StringName] = CampaignRules.MAP_ORDER

var classes: Dictionary = {}
var abilities: Dictionary = {}
var enemies: Dictionary = {}
var equipment: Dictionary = {}
var maps: Dictionary = {}
var waves: Dictionary = {}
var relics: Array[Dictionary] = []
var forge_recipes: Array[Dictionary] = []
var forge_index: Dictionary = {}
var achievements: Array[Dictionary] = []
var upgrades: Array[Dictionary] = []
var bounties: Array[Dictionary] = []

func _ready() -> void:
	_build_classes()
	_build_abilities()
	preload("res://scripts/data/ability_expansion.gd").populate(abilities)
	_build_enemies()
	_build_equipment()
	preload("res://scripts/data/regional_equipment.gd").populate(equipment)
	preload("res://scripts/data/equipment_expansion.gd").populate(equipment, classes)
	_build_maps()
	_build_waves()
	_build_relics()
	_build_forge_recipes()
	preload("res://scripts/data/equipment_expansion.gd").populate_recipes(forge_recipes, equipment)
	for recipe in forge_recipes: forge_index[str(recipe.id)] = recipe
	_build_achievements()
	_build_upgrades()
	_build_bounties()

func _resource(script: Script, fields: Dictionary) -> Resource:
	var item: Resource = script.new()
	for key in fields:
		item.set(key, fields[key])
	return item

func class_ids() -> Array[StringName]:
	return CLASS_ORDER.duplicate()

func map_ids() -> Array[StringName]:
	return MAP_ORDER.duplicate()

# ═══════════════════════════════════════════════════════════
# CLASSES
# ═══════════════════════════════════════════════════════════
func _build_classes() -> void:
	classes["warrior"] = _resource(CLASS_DATA, {"id": &"warrior", "display_name": "Sentinela", "description": "Uma muralha viva: enorme reserva de vida, baixo dano e provocação para atrair o cerco.", "accent": Color("#e4ba79"), "max_health": 420.0, "damage": 8.0, "defense": 6.0, "speed": 180.0, "attack_cooldown": 1.0, "attack_range": 112.0, "projectile_speed": 460.0, "attack_style": &"melee", "threat_priority": 4.0, "starting_ability": &"iron_will", "starter_weapon": &"field_blade", "cost_gold": 0, "cost_crystals": 0})
	classes["mage"] = _resource(CLASS_DATA, {"id": &"mage", "display_name": "Tecelã", "description": "Pouca vida, magia poderosa em área e ataques a longa distância. Precisa manter espaço.", "accent": Color("#96deef"), "max_health": 80.0, "damage": 30.0, "defense": 0.0, "speed": 215.0, "attack_cooldown": 0.95, "attack_range": 430.0, "splash_radius": 90.0, "projectile_speed": 480.0, "attack_style": &"magic", "starting_ability": &"arcane_focus", "starter_weapon": &"moon_staff", "cost_gold": 0, "cost_crystals": 0})
	classes["ranger"] = _resource(CLASS_DATA, {"id": &"ranger", "display_name": "Batedora", "description": "Uma torrente de flechas: ataque muito rápido, dano médio e movimento veloz. Vida tão baixa quanto a Tecelã.", "accent": Color("#d0e5a0"), "max_health": 80.0, "damage": 13.0, "defense": 0.0, "speed": 310.0, "attack_cooldown": 0.25, "attack_range": 400.0, "projectile_speed": 760.0, "attack_style": &"ranged", "starting_ability": &"keen_eye", "starter_weapon": &"thorn_bow", "cost_gold": 0, "cost_crystals": 0})
	classes["assassin"] = _resource(CLASS_DATA, {"id": &"assassin", "display_name": "Lâmina da Noite", "description": "Pouca vida e adagas extremamente rápidas. Mesmo dano por golpe da Batedora, mas precisa lutar perto.", "accent": Color("#d8b1e7"), "max_health": 72.0, "damage": 13.0, "defense": 1.0, "speed": 290.0, "attack_cooldown": 0.22, "attack_range": 105.0, "projectile_speed": 460.0, "attack_style": &"melee", "starting_ability": &"shadow_step", "starter_weapon": &"twin_daggers", "cost_gold": 450, "cost_crystals": 6})
	classes["druid"] = _resource(CLASS_DATA, {"id": &"druid", "display_name": "Guardião da Seiva", "description": "Conjurador frágil de longo alcance. Invoca lobos de seiva temporários e desperta guardiões da floresta.", "accent": Color("#a9ebaa"), "max_health": 85.0, "damage": 26.0, "defense": 0.0, "speed": 210.0, "attack_cooldown": 1.10, "attack_range": 400.0, "splash_radius": 68.0, "projectile_speed": 440.0, "attack_style": &"magic", "starting_ability": &"wild_growth", "starter_weapon": &"root_staff", "cost_gold": 700, "cost_crystals": 9})
	classes["paladin"] = _resource(CLASS_DATA, {"id": &"paladin", "display_name": "Arauto do Sol", "description": "Guerreiro equilibrado: vida média, armadura sólida, dano médio e passo constante.", "accent": Color("#ffe2a1"), "max_health": 190.0, "damage": 17.0, "defense": 4.0, "speed": 220.0, "attack_cooldown": 0.68, "attack_range": 128.0, "projectile_speed": 460.0, "attack_style": &"melee", "starting_ability": &"holy_oath", "starter_weapon": &"oath_hammer", "cost_gold": 950, "cost_crystals": 12})

# ═══════════════════════════════════════════════════════════
# HABILIDADES
# ═══════════════════════════════════════════════════════════
func _add_ability(id: String, title: String, description: String, rarity: String, fields: Dictionary = {}) -> void:
	var values := {"id": StringName(id), "display_name": title, "description": description, "rarity": StringName(rarity)}
	values.merge(fields, true)
	abilities[id] = _resource(ABILITY_DATA, values)

func _build_abilities() -> void:
	# Habilidades de início de classe (unlock_only)
	_add_ability("iron_will", "Vontade de Ferro", "Defesa +2, vida máxima +10% e provocação automática a cada 6 s.", "uncommon", {"stat": &"iron_will", "unlock_only": true})
	_add_ability("arcane_focus", "Foco Arcano", "Dano mágico +12%.", "uncommon", {"stat": &"arcane_focus", "unlock_only": true})
	_add_ability("keen_eye", "Olho Aguçado", "Crítico +8% e alcance +10%.", "uncommon", {"stat": &"keen_eye", "unlock_only": true})

	_add_ability("shadow_step", "Passo das Sombras", "Crítico +8% e velocidade de movimento +8%.", "uncommon", {"stat": &"shadow_step", "unlock_only": true})
	_add_ability("wild_growth", "Chamado da Seiva", "Invoca 2 lobos aliados por 14 s, a cada 18 s. Eles perseguem e atacam os monstros.", "uncommon", {"stat": &"wild_growth", "unlock_only": true})
	_add_ability("holy_oath", "Juramento Solar", "Defesa +2 e vida máxima +8%.", "uncommon", {"stat": &"holy_oath", "unlock_only": true})

	# Habilidades comuns
	_add_ability("swift_feet", "Passos Velozes", "Velocidade de movimento +8%. Esquivar se torna mais fácil.", "common", {"stat": &"speed", "stat_amount": 0.08})
	_add_ability("vital_bloom", "Seiva Vital", "Vida máxima +18% e cura 20% da vida.", "common", {"stat": &"health", "stat_amount": 0.18})
	_add_ability("keen_edge", "Lâmina Afiada", "Dano de todos os ataques +16%.", "common", {"stat": &"damage", "stat_amount": 0.16})
	_add_ability("iron_skin", "Pele de Ferro", "Defesa +3. Cada ponto de defesa reduz o dano recebido.", "common", {"stat": &"defense", "stat_amount": 3.0})
	_add_ability("hunters_pace", "Ritmo de Caçador", "Velocidade +6% e velocidade de ataque +5%.", "common", {"stat": &"speed", "stat_amount": 0.06})

	# Habilidades incomuns
	_add_ability("rapid_hands", "Mãos Rápidas", "Velocidade de ataque +16% por escolha. Os bônus se somam.", "uncommon", {"stat": &"attack_speed", "stat_amount": 0.16})
	_add_ability("thorn_aura", "Círculo de Espinhos", "Aura de espinhos fere inimigos que se aproximam.", "uncommon", {"damage_multiplier": 0.38, "cooldown_multiplier": 1.0, "radius": 100.0})
	_add_ability("lifesteal", "Vampirismo", "Roubo de vida +4% por escolha. Cura até 1,5% da vida máxima por segundo.", "uncommon", {"stat": &"lifesteal", "stat_amount": 0.04})
	_add_ability("berserker", "Fúria do Berserk", "Quanto menos vida, mais dano: até +25% com 20% de vida.", "uncommon", {"stat": &"berserker", "stat_amount": 0.25})

	# Habilidades raras
	_add_ability("ember_orb", "Orbe de Brasa", "Projéteis de fogo explodem em área ao atingir o alvo.", "rare", {"damage_multiplier": 0.72, "cooldown_multiplier": 1.3, "radius": 94.0})
	_add_ability("lucky_find", "Sorte de Vespera", "Ouro e experiência recebidos +20%.", "rare", {"stat": &"fortune", "stat_amount": 0.2})
	_add_ability("frost_nova", "Nova de Gelo", "Congela brevemente inimigos próximos ao sofrer dano.", "rare", {"stat": &"frost_nova", "stat_amount": 0.0})
	_add_ability("echo_strike", "Golpe Eco", "Cada ataque tem 20% de chance de golpear duas vezes.", "rare", {"stat": &"echo_strike", "stat_amount": 0.2})

	# Habilidades épicas
	_add_ability("storm_arc", "Arco de Tempestade", "Um raio salta entre três inimigos causando dano massivo.", "epic", {"damage_multiplier": 1.1, "cooldown_multiplier": 2.2, "radius": 220.0})
	_add_ability("second_wind", "Segundo Fôlego", "Recupera 45% da vida máxima instantaneamente.", "epic", {"stat": &"heal", "stat_amount": 0.45})
	_add_ability("blade_storm", "Tempestade de Lâminas", "Golpes circulares periódicos. Cada nível soma dano e alcance e reduz o intervalo.", "epic", {"stat": &"blade_storm"})
	_add_ability("time_warp", "Dobra do Tempo", "Lentidão +10% por nível durante 4 s, até 50%. Cada nível reduz o intervalo.", "epic", {"stat": &"time_warp", "stat_amount": 0.1})

	# Habilidades lendárias
	_add_ability("starfall", "Chuva de Estrelas", "Um cometa astral explode e varre uma grande área.", "legendary", {"damage_multiplier": 2.4, "cooldown_multiplier": 2.8, "radius": 150.0})
	_add_ability("phoenix_flame", "Chama Fênix", "Uma ressurreição por expedição: 40% de vida no nível 1, +12% de vida por nível adicional.", "legendary", {"stat": &"phoenix"})
	_add_ability("void_rift", "Rasgo do Vazio", "Abre uma fissura que suga e destrói inimigos próximos.", "legendary", {"damage_multiplier": 3.0, "cooldown_multiplier": 4.0, "radius": 180.0})
	_configure_ability_pools()

func _configure_ability_pools() -> void:
	var base_bonuses := {
		"iron_will": {"defense": 2.0, "health_pct": 0.10}, "arcane_focus": {"damage_pct": 0.12},
		"keen_eye": {"crit_chance": 0.08, "range_pct": 0.10}, "shadow_step": {"crit_chance": 0.08, "speed_pct": 0.08},
		"holy_oath": {"defense": 2.0, "health_pct": 0.08}, "swift_feet": {"speed_pct": 0.08},
		"vital_bloom": {"health_pct": 0.18}, "keen_edge": {"damage_pct": 0.16}, "iron_skin": {"defense": 3.0},
		"hunters_pace": {"speed_pct": 0.06, "attack_speed_pct": 0.05}, "rapid_hands": {"attack_speed_pct": 0.16},
		"lifesteal": {"lifesteal": 0.04}, "lucky_find": {"bonus_gold_xp": 0.20}}
	for id in base_bonuses:
		abilities[id].bonuses = base_bonuses[id]
	var owners := {
		"iron_will": ["warrior"], "arcane_focus": ["mage"], "keen_eye": ["ranger"], "shadow_step": ["assassin"], "wild_growth": ["druid"], "holy_oath": ["paladin"],
		"thorn_aura": ["warrior", "druid", "paladin"], "berserker": ["warrior", "assassin", "paladin"],
		"ember_orb": ["mage", "druid"], "frost_nova": ["mage"], "echo_strike": ["ranger", "assassin", "paladin"],
		"storm_arc": ["mage"], "blade_storm": ["warrior", "assassin", "paladin"], "time_warp": ["mage"], "starfall": ["mage"], "void_rift": ["mage"]}
	for id in owners:
		for owner in owners[id]:
			abilities[id].class_ids.append(StringName(owner))
	_add_ability("far_sight", "Olhar Distante", "Alcance dos ataques +12% por escolha.", "common", {"bonuses": {"range_pct": 0.12}})
	_add_ability("critical_eye", "Ponto Fraco", "Chance de crítico +6 pontos percentuais por escolha.", "uncommon", {"bonuses": {"crit_chance": 0.06}})
	_add_ability("field_medicine", "Respiro de Vespera", "Regeneração +0,5 de vida por segundo por escolha.", "uncommon", {"bonuses": {"regen": 0.5}})
	_add_ability("wide_harvest", "Mãos do Explorador", "Alcance de coleta +30 por escolha.", "common", {"bonuses": {"pickup_radius": 30.0}})
	_class_ability("bulwark", "Coração de Bastião", "Vida máxima +24% por escolha.", "common", "warrior", {"health_pct": 0.24})
	_class_ability("hold_the_line", "Sustentar a Linha", "Defesa +4 por escolha.", "uncommon", "warrior", {"defense": 4.0})
	_class_ability("retribution", "Armadura de Espinhos", "Devolve 30% do dano recebido aos inimigos próximos por nível.", "rare", "warrior", {"thorns": 0.30})
	_class_ability("challenge_shout", "Grito de Desafio", "Provoca monstros em área e aplica lentidão. Cada nível amplia a área e a duração.", "rare", "warrior")
	_class_ability("distant_star", "Estrela Distante", "Dano +10% e alcance +12% por escolha.", "common", "mage", {"damage_pct": 0.10, "range_pct": 0.12})
	_class_ability("arcane_expansion", "Expansão Arcana", "Raio das explosões básicas +16 por escolha.", "uncommon", "mage", {"splash_radius": 16.0})
	_class_ability("arcane_haste", "Fluxo Arcano", "Velocidade de ataque +16% por escolha.", "uncommon", "mage", {"attack_speed_pct": 0.16})
	_class_ability("glacial_ring", "Prisão Glacial", "Explosão gelada no alvo distante. Cada nível soma dano, área e lentidão.", "rare", "mage")
	_class_ability("wind_string", "Corda do Vendaval", "Velocidade de ataque +16% e movimento +4% por escolha.", "common", "ranger", {"attack_speed_pct": 0.16, "speed_pct": 0.04})
	_class_ability("fletching", "Flechas Perfurantes", "Cada flecha atravessa mais 1 inimigo por escolha.", "uncommon", "ranger", {"projectile_pierce": 1.0})
	_class_ability("steady_aim", "Mira Precisa", "Dano +12% e crítico +4 pontos percentuais por escolha.", "uncommon", "ranger", {"damage_pct": 0.12, "crit_chance": 0.04})
	_class_ability("volley", "Rajada de Vespera", "Leque de flechas periódico. Cada nível acrescenta uma flecha e aumenta o dano.", "rare", "ranger")
	_class_ability("deadly_rhythm", "Ritmo Mortal", "Velocidade de ataque +16% por escolha.", "common", "assassin", {"attack_speed_pct": 0.16})
	_class_ability("razor_dance", "Dança das Adagas", "Ataques acertam mais 1 alvo e ganham +6% de dano por escolha.", "uncommon", "assassin", {"cleave_targets": 1.0, "damage_pct": 0.06})
	_class_ability("night_hunger", "Fome da Noite", "Dano +12% e roubo de vida +2% por escolha. Cura até 1,5% da vida máxima/s.", "uncommon", "assassin", {"damage_pct": 0.12, "lifesteal": 0.02})
	_class_ability("shadow_burst", "Ecos da Noite", "Golpe periódico nos inimigos próximos. Cada nível soma um alvo e dano.", "rare", "assassin")
	_class_ability("wolf_pack", "Matilha da Seiva", "Mais 1 lobo e +2 s de duração das invocações por escolha.", "common", "druid", {"summon_count": 1.0, "summon_duration": 2.0})
	_class_ability("living_bark", "Pacto da Floresta", "Dano das invocações +18% e velocidade de ataque delas +10% por escolha.", "uncommon", "druid", {"summon_damage_pct": 0.18, "summon_speed_pct": 0.10})
	_class_ability("ancient_guardian", "Guardiões de Casca", "Invoca um guardião por 14 s. Níveis somam dano e duração; níveis 3 e 5 acrescentam um guardião.", "rare", "druid")
	_class_ability("roots_snare", "Abraço das Raízes", "Raízes ferem e retardam os monstros próximos. Cada nível soma dano, área e lentidão.", "uncommon", "druid")
	_class_ability("solar_armor", "Aço da Aurora", "Vida +10% e defesa +2 por escolha.", "common", "paladin", {"health_pct": 0.10, "defense": 2.0})
	_class_ability("oath_edge", "Peso do Juramento", "Dano +12% e velocidade de ataque +8% por escolha.", "uncommon", "paladin", {"damage_pct": 0.12, "attack_speed_pct": 0.08})
	_class_ability("sunfire", "Arco Solar", "Golpe em área periódico. Cada nível soma dano e alcance.", "rare", "paladin")
	_class_ability("restoring_light", "Luz Restauradora", "Vida máxima +8% e regeneração +0,6 de vida/s por escolha.", "uncommon", "paladin", {"health_pct": 0.08, "regen": 0.6})

func _class_ability(id: String, title: String, description: String, rarity: String, owner: String, bonuses: Dictionary = {}) -> void:
	_add_ability(id, title, description, rarity, {"bonuses": bonuses})
	abilities[id].class_ids.append(StringName(owner))

# ═══════════════════════════════════════════════════════════
# INIMIGOS
# ═══════════════════════════════════════════════════════════
func _add_enemy(id: String, title: String, hp: float, damage: float, speed: float, xp: int, gold: int, range: float = 34.0, elite: bool = false, boss: bool = false, tips: String = "", style: StringName = &"melee", tint: Color = Color("#c5a070")) -> void:
	enemies[id] = _resource(ENEMY_DATA, {"id": StringName(id), "art_id": StringName(id), "display_name": title, "max_health": hp, "damage": damage, "speed": speed, "xp": xp, "gold": gold, "attack_range": range, "elite": elite, "boss": boss, "tips": tips, "attack_style": style, "projectile_color": tint})

func _build_enemies() -> void:
	_add_enemy("slime", "Gosma de Musgo", 18.0, 4.0, 57.0, 3, 1, 32.0, false, false, "Lenta e frágil. Golpes em área limpam os enxames.")
	_add_enemy("goblin", "Catador", 24.0, 5.0, 79.0, 4, 1, 34.0, false, false, "Avança em grupos para cercar o caminho.")
	_add_enemy("wolf", "Lobo Cinzento", 20.0, 5.0, 117.0, 4, 1, 34.0, false, false, "Rápido e frágil. Elimine-o antes de atravessar a matilha.")
	_add_enemy("archer", "Flecha Perdida", 22.0, 5.0, 55.0, 5, 2, 235.0, false, false, "Mantém distância. Seus projéteis deixam espaço para esquivar.", &"ranged", Color("#c6b68c"))
	_add_enemy("mage", "Bruxo da Seiva", 28.0, 6.0, 47.0, 6, 2, 255.0, false, false, "Dispara centelhas e marca o chão com seiva corrosiva. Saia do círculo antes da explosão.", &"ranged", Color("#a4c27b"))
	_add_enemy("elite", "Rastreador Alfa", 90.0, 10.0, 81.0, 18, 8, 40.0, true, false, "Mais resistente, mas sua queda rende experiência extra.")
	_add_enemy("goblin_king", "Rei do Espinheiro", 520.0, 16.0, 71.0, 85, 100, 56.0, false, true, "Contorne sua investida e limpe os reforços.")
	_add_enemy("skeleton", "Vigia Ósseo", 28.0, 6.0, 68.0, 4, 1, 34.0, false, false, "Os ossos marcham em fileiras. Abra uma passagem com ataques em área.")
	_add_enemy("bat", "Morcego das Sombras", 15.0, 4.0, 143.0, 3, 1, 30.0, false, false, "Quase não tem vida, mas alcança rapidamente o jogador.")
	_add_enemy("zombie", "Caminhante Podre", 42.0, 7.0, 41.0, 6, 2, 35.0, false, false, "Lento e resistente. Não fique preso entre vários caminhantes.")
	_add_enemy("bone_archer", "Arqueiro da Cripta", 23.0, 6.0, 50.0, 5, 2, 250.0, false, false, "Flechas antigas cruzam o cemitério. Mova-se entre os disparos.", &"ranged", Color("#cfc7ab"))
	_add_enemy("crypt_wisp", "Lume Funerário", 20.0, 6.0, 82.0, 5, 2, 230.0, false, false, "Uma alma leve que lança luz espectral à distância.", &"ranged", Color("#9cc9c1"))
	_add_enemy("dark_mage", "Necromante Menor", 88.0, 10.0, 50.0, 20, 9, 270.0, true, false, "Projéteis espectrais e muita resistência. Elimine-o antes do cerco.", &"ranged", Color("#b9a9d0"))
	_add_enemy("death_lord", "Guardião do Ossuário", 570.0, 17.0, 61.0, 95, 120, 62.0, false, true, "Sua foice alcança longe. Contorne o guardião e deixe os mortos para trás.")
	_add_enemy("cinder_imp", "Diabrete de Brasa", 21.0, 5.0, 88.0, 4, 1, 32.0, false, false, "Pequeno e apressado. Cai rápido sob fogo concentrado.")
	_add_enemy("ash_hound", "Cão de Cinza", 24.0, 6.0, 124.0, 4, 1, 35.0, false, false, "Persegue pelas fendas. Evite correr diretamente para a matilha.")
	_add_enemy("ember_beetle", "Besouro Incandescente", 36.0, 6.0, 54.0, 5, 2, 34.0, false, false, "Carapaça pesada e passos lentos. Agrupe-os antes de atacar.")
	_add_enemy("fire_witch", "Feiticeira da Cinza", 27.0, 7.0, 49.0, 6, 2, 265.0, false, false, "Lança brasas de longe. Os disparos alaranjados são sua maior ameaça.", &"ranged", Color("#e6a36d"))
	_add_enemy("obsidian_guard", "Vigia de Obsidiana", 46.0, 8.0, 57.0, 7, 3, 40.0, false, false, "Uma muralha de pedra negra. Esquive e ataque pelos lados.")
	_add_enemy("molten_knight", "Cavaleiro Fundido", 105.0, 11.0, 69.0, 23, 10, 44.0, true, false, "Ataques repetidos quebram sua carapaça incandescente.")
	_add_enemy("lava_lord", "Coração da Caldeira", 610.0, 18.0, 55.0, 105, 140, 68.0, false, true, "Uma massa de rocha e fogo. Ataque durante suas aproximações lentas.")
	_add_enemy("bloodling", "Servo Rubro", 22.0, 6.0, 94.0, 4, 1, 32.0, false, false, "A fome o traz em grupos. Elimine-os em sequência para abrir passagem.")
	_add_enemy("fallen_guard", "Guarda Caído", 39.0, 7.0, 69.0, 6, 2, 39.0, false, false, "A armadura ainda protege o cadáver. Tenha espaço para recuar.")
	_add_enemy("cult_archer", "Besteiro do Véu", 27.0, 7.0, 53.0, 6, 2, 280.0, false, false, "Disparos precisos de longe. Aproxime-se em diagonal.", &"ranged", Color("#d4ad9a"))
	_add_enemy("blood_mage", "Sacerdote Rubro", 30.0, 8.0, 49.0, 7, 3, 265.0, false, false, "Dispara magia de sangue. Não permaneça parado diante dele.", &"ranged", Color("#d9949c"))
	_add_enemy("dusk_knight", "Cavaleiro do Crepúsculo", 110.0, 12.0, 76.0, 24, 11, 46.0, true, false, "Passos rápidos sob armadura pesada. Um alvo valioso entre a multidão.")
	_add_enemy("vampire_king", "Rei Sem Aurora", 640.0, 18.0, 84.0, 115, 160, 58.0, false, true, "Rápido como a sombra. Mantenha o caminho livre e continue atacando.")
	_add_enemy("ice_slime", "Gosma de Geada", 22.0, 5.0, 52.0, 4, 1, 32.0, false, false, "Lenta, brilhante e numerosa. Desfaça os grupos antes que fechem o caminho.")
	_add_enemy("snow_wolf", "Lobo de Neve", 25.0, 6.0, 128.0, 5, 1, 35.0, false, false, "A matilha mais rápida do norte. Nunca pare no meio dela.")
	_add_enemy("frost_spider", "Aranha de Cristal", 29.0, 7.0, 96.0, 5, 2, 34.0, false, false, "Patas leves cruzam os corredores. Pouca vida, muitos atacantes.")
	_add_enemy("ice_archer", "Caçador da Geada", 28.0, 7.0, 54.0, 6, 2, 285.0, false, false, "Flechas azuladas atravessam o bosque. Desvie em movimento contínuo.", &"ranged", Color("#b4dbe1"))
	_add_enemy("frost_shaman", "Xamã do Inverno", 33.0, 8.0, 47.0, 7, 3, 270.0, false, false, "Concentra o frio em projéteis. Derrube-o antes de se afastar demais.", &"ranged", Color("#87c7dd"))
	_add_enemy("frost_brute", "Colosso da Geada", 112.0, 12.0, 64.0, 25, 12, 47.0, true, false, "Lento e robusto. Reserve seus golpes fortes para o colosso.")
	_add_enemy("frost_guardian", "Ancião do Inverno", 670.0, 19.0, 65.0, 125, 180, 66.0, false, true, "Uma criatura de gelo e raízes. Sua presença atrai a matilha do bosque.")
	_add_enemy("bogling", "Filho do Lodo", 23.0, 6.0, 71.0, 4, 1, 33.0, false, false, "O lodo toma forma em muitos pequenos corpos. Ataque vários por vez.")
	_add_enemy("swamp_leech", "Sanguessuga do Charco", 18.0, 5.0, 113.0, 4, 1, 30.0, false, false, "Pequena e voraz. Não deixe o enxame encostar.")
	_add_enemy("reed_stalker", "Espreitador dos Juncos", 30.0, 7.0, 105.0, 6, 2, 37.0, false, false, "Avança por entre os juncos. Separe-o das criaturas mais lentas.")
	_add_enemy("spore_shaman", "Arauto dos Esporos", 32.0, 8.0, 44.0, 7, 3, 250.0, false, false, "Projéteis amarelados brotam de seu cajado. Elimine à distância.", &"ranged", Color("#cbd37c"))
	_add_enemy("mire_toad", "Sapo do Brejo", 48.0, 8.0, 58.0, 7, 3, 40.0, false, false, "Pesado e resistente. Limpe os pequenos antes de enfrentar o sapo.")
	_add_enemy("mire_titan", "Gigante do Brejo", 115.0, 13.0, 61.0, 26, 12, 49.0, true, false, "Musgo e lama cobrem um corpo enorme. Contorne-o sem perder o ritmo.")
	_add_enemy("mire_queen", "Rainha do Charco", 690.0, 20.0, 62.0, 135, 200, 68.0, false, true, "A soberana anfíbia protege o charco. Enxames cercam seus passos pesados.")

# ═══════════════════════════════════════════════════════════
# EQUIPAMENTOS
# ═══════════════════════════════════════════════════════════
func _build_equipment() -> void:
	# Armas por classe
	_add_equipment("field_blade", "Lâmina de Vigília", "weapon", "common", "A espada curta das sentinelas de Vespera. +3 de dano.", "damage", 3.0, "warrior")
	_add_equipment("moon_staff", "Cajado de Luar", "weapon", "common", "Um fio de centelha antiga. +3 de dano.", "damage", 3.0, "mage")
	_add_equipment("thorn_bow", "Arco de Espinheiro", "weapon", "common", "Madeira viva, corda de tendão. +3 de dano.", "damage", 3.0, "ranger")
	# Armas raras
	_add_equipment("flame_sword", "Espada Flamejante", "weapon", "rare", "Forjada nas brasas eternas. +8 de dano e aura de fogo.", "damage", 8.0, "warrior")
	_add_equipment("void_staff", "Cetro do Vazio", "weapon", "epic", "Canaliza energia do plano astral. +12 de dano mágico.", "damage", 12.0, "mage")
	_add_equipment("shadow_bow", "Arco da Sombra", "weapon", "rare", "Flechas que atravessam inimigos. +7 de dano e penetração.", "damage", 7.0, "ranger")

	_add_equipment("twin_daggers", "Adagas de Vigília", "weapon", "common", "Duas lâminas discretas. +3 de dano.", "damage", 3.0, "assassin")
	_add_equipment("root_staff", "Cajado de Raiz", "weapon", "common", "Madeira viva em espiral. +3 de dano.", "damage", 3.0, "druid")
	_add_equipment("oath_hammer", "Martelo do Juramento", "weapon", "common", "Um voto gravado em aço. +3 de dano.", "damage", 3.0, "paladin")
	_add_equipment("night_fangs", "Presas da Noite", "weapon", "rare", "A sombra afia suas lâminas. +8 de dano.", "damage", 8.0, "assassin")
	_add_equipment("elderwood_staff", "Cajado do Ancião", "weapon", "epic", "O coração da floresta pulsa no cajado. +12 de dano.", "damage", 12.0, "druid")
	_add_equipment("dawn_hammer", "Martelo da Aurora", "weapon", "rare", "A luz retorna a cada golpe. +9 de dano.", "damage", 9.0, "paladin")
	_add_equipment("night_hood", "Capuz da Noite", "helmet", "uncommon", "Seda escura, olhar atento. +14 de vida.", "health", 14.0, "assassin")
	_add_equipment("antler_crown", "Coroa de Galhos", "helmet", "uncommon", "A mata reconhece seu guardião. +16 de vida.", "health", 16.0, "druid")
	_add_equipment("dawn_helm", "Elmo da Aurora", "helmet", "uncommon", "O primeiro raio repousa no aço. +22 de vida.", "health", 22.0, "paladin")
	_add_equipment("shadow_vest", "Colete do Véu", "armor", "rare", "Couro leve que acompanha a esquiva. +20 de vida.", "health", 20.0, "assassin")
	_add_equipment("grove_mantle", "Manto do Bosque", "armor", "rare", "Folhas antigas formam sua proteção. +26 de vida.", "health", 26.0, "druid")
	_add_equipment("sunplate", "Couraça Solar", "armor", "epic", "A armadura da ordem esquecida. +38 de vida.", "health", 38.0, "paladin")

	# Capacetes
	_add_equipment("warden_helm", "Elmo da Vigília", "helmet", "common", "A copa de ferro ainda guarda o calor da forja. +12 de vida.", "health", 12.0, "warrior")
	_add_equipment("ash_circlet", "Diadema Cinéreo", "helmet", "common", "Runas que protegem o pensamento. +8 de vida.", "health", 8.0, "mage")
	_add_equipment("bark_hood", "Capuz de Casca", "helmet", "common", "Folhas e couro escondem seu rosto. +10 de vida.", "health", 10.0, "ranger")
	_add_equipment("obsidian_helm", "Elmo de Obsidiana", "helmet", "rare", "Forjado da rocha vulcânica. +20 de vida e +2 de defesa.", "health", 20.0, "warrior")
	_add_equipment("starweave_hood", "Capuz Estelar", "helmet", "uncommon", "Tecido com fios de luz astral. +15 de vida.", "health", 15.0, "mage")

	# Armaduras
	_add_equipment("rootplate", "Couraça de Raiz", "armor", "uncommon", "Raízes antigas reforçam a armadura. +24 de vida.", "health", 24.0, "warrior")
	_add_equipment("starweave_robe", "Manto Estelar", "armor", "uncommon", "Seda tecida com poeira astral. +14 de vida.", "health", 14.0, "mage")
	_add_equipment("leafmail", "Cota de Folhas", "armor", "uncommon", "Escamas vegetais flexíveis. +18 de vida.", "health", 18.0, "ranger")
	_add_equipment("dragonscale", "Escama de Dragão", "armor", "epic", "Armadura lendária. +35 de vida e +3 de defesa.", "health", 35.0, "warrior")

	# Botas
	_add_equipment("wind_boots", "Botas do Vendaval", "boots", "uncommon", "+7% de velocidade de movimento.", "speed_pct", 0.07)
	_add_equipment("sentinel_greaves", "Grevas do Bastião", "boots", "common", "Passos firmes entre os espinhos. +5% de velocidade.", "speed_pct", 0.05, "warrior")
	_add_equipment("mistwalkers", "Sandálias de Névoa", "boots", "common", "O chão mal percebe sua passagem. +6% de velocidade.", "speed_pct", 0.06, "mage")
	_add_equipment("trail_treads", "Botas do Rastro", "boots", "common", "Nenhum galho denuncia seu caminho. +8% de velocidade.", "speed_pct", 0.08, "ranger")
	_add_equipment("void_walkers", "Andantes do Vazio", "boots", "epic", "Passos que dobram o espaço. +15% de velocidade.", "speed_pct", 0.15)

	# Anéis
	_add_equipment("ember_signet", "Sinete da Brasa", "ring", "rare", "+8% de dano e um brilho de fogo.", "damage_pct", 0.08)
	_add_equipment("iron_oath", "Anel do Juramento", "ring", "rare", "+6% de dano. O voto das sentinelas.", "damage_pct", 0.06, "warrior")
	_add_equipment("moonstone_ring", "Anel de Pedra Lunar", "ring", "rare", "+7% de dano mágico.", "damage_pct", 0.07, "mage")
	_add_equipment("hawk_eye_ring", "Anel do Falcão", "ring", "rare", "+6% de dano crítico.", "damage_pct", 0.06, "ranger")
	_add_equipment("ring_of_ages", "Anel das Eras", "ring", "legendary", "+12% de todo o dano causado.", "damage_pct", 0.12)

	# Amuletos
	_add_equipment("oak_charm", "Amuleto de Carvalho", "amulet", "uncommon", "+18 de vida máxima.", "health", 18.0)
	_add_equipment("watcher_medallion", "Medalhão do Vigia", "amulet", "uncommon", "+16 de vida máxima.", "health", 16.0, "warrior")
	_add_equipment("astral_pendant", "Pendente Astral", "amulet", "uncommon", "+12 de vida máxima.", "health", 12.0, "mage")
	_add_equipment("elder_charm", "Amuleto do Ancião", "amulet", "uncommon", "+15 de vida máxima.", "health", 15.0, "ranger")
	_add_equipment("ancient_talisman", "Talismã Ancestral", "amulet", "legendary", "+30 de vida e +5% de dano.", "health", 30.0)

func _add_equipment(id: String, title: String, slot: String, rarity: String, description: String, stat: String, amount: float, class_id: String = "") -> void:
	equipment[id] = _resource(EQUIPMENT_DATA, {"id": StringName(id), "display_name": title, "slot": StringName(slot), "class_id": StringName(class_id), "rarity": StringName(rarity), "description": description, "stat": StringName(stat), "stat_amount": amount})

# ═══════════════════════════════════════════════════════════
# MAPAS
# ═══════════════════════════════════════════════════════════
func _build_maps() -> void:
	maps["verdant_reach"] = _resource(MAP_DATA, {"id": &"verdant_reach", "display_name": "Ermos de Vespera", "description": "Musgo, matilhas e catadores nos caminhos da floresta antiga.", "theme": &"forest", "duration": 144.0, "boss_id": &"goblin_king", "elite_id": &"elite", "difficulty": 1, "stage_index": 0, "accent": Color("#a5b482"), "unlocked_by_default": true, "enemy_pool": _pool([&"slime", &"goblin", &"wolf", &"archer", &"mage"])})
	maps["hollow_cairn"] = _resource(MAP_DATA, {"id": &"hollow_cairn", "display_name": "Colina Oca", "description": "Mortos caminham entre lápides e os lumes iluminam as criptas.", "theme": &"graveyard", "duration": 156.0, "boss_id": &"death_lord", "elite_id": &"dark_mage", "difficulty": 1.16, "stage_index": 1, "accent": Color("#b8b1c2"), "unlocked_by_default": false, "enemy_pool": _pool([&"skeleton", &"bat", &"zombie", &"bone_archer", &"crypt_wisp"])})
	maps["ember_crater"] = _resource(MAP_DATA, {"id": &"ember_crater", "display_name": "Cratera Rubra", "description": "Cinza, brasas e carapaças de obsidiana cercam a caldeira.", "theme": &"volcanic", "duration": 168.0, "boss_id": &"lava_lord", "elite_id": &"molten_knight", "difficulty": 1.32, "stage_index": 2, "accent": Color("#d6a078"), "unlocked_by_default": false, "enemy_pool": _pool([&"cinder_imp", &"ash_hound", &"ember_beetle", &"fire_witch", &"obsidian_guard"])})
	maps["black_keep"] = _resource(MAP_DATA, {"id": &"black_keep", "display_name": "Castelo Sem Aurora", "description": "O culto rubro e seus guardas ocupam os salões sem sol.", "theme": &"castle", "duration": 180.0, "boss_id": &"vampire_king", "elite_id": &"dusk_knight", "difficulty": 1.5, "stage_index": 3, "accent": Color("#c897a3"), "unlocked_by_default": false, "enemy_pool": _pool([&"bloodling", &"bat", &"fallen_guard", &"cult_archer", &"blood_mage"])})
	maps["frostwood"] = _resource(MAP_DATA, {"id": &"frostwood", "display_name": "Bosque da Geada", "description": "Neve cobre as raízes; a matilha branca protege um inverno eterno.", "theme": &"frost", "duration": 188.0, "boss_id": &"frost_guardian", "elite_id": &"frost_brute", "difficulty": 1.65, "stage_index": 4, "accent": Color("#a2c7d0"), "unlocked_by_default": false, "enemy_pool": _pool([&"ice_slime", &"snow_wolf", &"frost_spider", &"ice_archer", &"frost_shaman"])})
	maps["sunken_mire"] = _resource(MAP_DATA, {"id": &"sunken_mire", "display_name": "Charco Esquecido", "description": "Lama, juncos e esporos ocultam a coroa da rainha anfíbia.", "theme": &"swamp", "duration": 196.0, "boss_id": &"mire_queen", "elite_id": &"mire_titan", "difficulty": 1.8, "stage_index": 5, "accent": Color("#b9c38a"), "unlocked_by_default": false, "enemy_pool": _pool([&"bogling", &"swamp_leech", &"reed_stalker", &"spore_shaman", &"mire_toad"])})

# ═══════════════════════════════════════════════════════════
# WAVES
# ═══════════════════════════════════════════════════════════
func _build_waves() -> void:
	waves[1] = _resource(WAVE_DATA, {"wave_number": 1, "duration": 60.0, "spawn_interval": 1.5, "elite_chance": 0.02, "enemy_pool": _pool([&"slime", &"goblin"])})
	waves[2] = _resource(WAVE_DATA, {"wave_number": 2, "duration": 60.0, "spawn_interval": 1.3, "elite_chance": 0.05, "enemy_pool": _pool([&"slime", &"goblin", &"wolf"])})
	waves[3] = _resource(WAVE_DATA, {"wave_number": 3, "duration": 75.0, "spawn_interval": 1.1, "elite_chance": 0.08, "enemy_pool": _pool([&"goblin", &"wolf", &"archer"])})
	waves[4] = _resource(WAVE_DATA, {"wave_number": 4, "duration": 75.0, "spawn_interval": 0.9, "elite_chance": 0.12, "enemy_pool": _pool([&"wolf", &"archer", &"skeleton"])})
	waves[5] = _resource(WAVE_DATA, {"wave_number": 5, "duration": 90.0, "spawn_interval": 0.75, "elite_chance": 0.15, "enemy_pool": _pool([&"archer", &"skeleton", &"mage"]), "boss_id": &"goblin_king"})
	waves[6] = _resource(WAVE_DATA, {"wave_number": 6, "duration": 90.0, "spawn_interval": 0.6, "elite_chance": 0.20, "enemy_pool": _pool([&"skeleton", &"mage", &"wolf"])})
	waves[7] = _resource(WAVE_DATA, {"wave_number": 7, "duration": 120.0, "spawn_interval": 0.5, "elite_chance": 0.25, "enemy_pool": _pool([&"goblin", &"archer", &"mage", &"skeleton"])})
	waves[8] = _resource(WAVE_DATA, {"wave_number": 8, "duration": 0.0, "spawn_interval": 0.4, "elite_chance": 0.35, "enemy_pool": _pool([&"wolf", &"skeleton", &"mage"]), "boss_id": &"goblin_king"})

func _pool(values: Array) -> Array[StringName]:
	var result: Array[StringName] = []
	for value in values:
		result.append(StringName(value))
	return result

# ═══════════════════════════════════════════════════════════
# RELÍQUIAS — Modificadores permanentes de run
# ═══════════════════════════════════════════════════════════
func _build_relics() -> void:
	relics = [
		{"id": "blood_pact", "name": "Pacto de Sangue", "desc": "Vida máxima -20%, mas todo dano causado é +25% maior.", "icon": "🩸", "rarity": "rare", "unlock": "boss_killer", "effect": "damage_up_life_down"},
		{"id": "golden_compass", "name": "Bússola de Ouro", "desc": "Ouro coletado +35%. Itens especiais aparecem mais vezes.", "icon": "🧭", "rarity": "uncommon", "unlock": "rich", "effect": "gold_bonus"},
		{"id": "iron_heart", "name": "Coração de Ferro", "desc": "Defesa +6. Você para de regenerar vida naturalmente.", "icon": "⚙️", "rarity": "uncommon", "unlock": "first_blood", "effect": "defense_no_regen"},
		{"id": "cursed_eye", "name": "Olho Amaldiçoado", "desc": "Chance de crítico +15%, mas inimigos ficam 10% mais rápidos.", "icon": "👁️", "rarity": "rare", "unlock": "survivor_10", "effect": "crit_faster_enemies"},
		{"id": "void_shard", "name": "Fragmento do Vazio", "desc": "Cada 5 inimigos mortos libera uma explosão de vazio.", "icon": "💠", "rarity": "epic", "unlock": "beast_hunter", "effect": "void_explosion"},
		{"id": "ancient_tome", "name": "Tomo Ancestral", "desc": "Habilidades sobem de nível com 50% mais xp requerido, mas ficam 30% mais fortes.", "icon": "📖", "rarity": "rare", "unlock": "lore_seeker", "effect": "ability_boost"},
		{"id": "soul_lantern", "name": "Lanterna da Alma", "desc": "Cada inimigo morto cura 0.5 de vida.", "icon": "🏮", "rarity": "uncommon", "unlock": "first_blood", "effect": "soul_heal"},
		{"id": "mirror_shield", "name": "Escudo Espelho", "desc": "20% do dano recebido é refletido ao atacante.", "icon": "🛡️", "rarity": "epic", "unlock": "boss_killer", "effect": "reflect"},
		{"id": "time_crystal", "name": "Cristal do Tempo", "desc": "No início de cada wave, todos os inimigos ficam lentos por 3 segundos.", "icon": "🔷", "rarity": "rare", "unlock": "wave_master", "effect": "wave_slow"},
		{"id": "deaths_coin", "name": "Moeda da Morte", "desc": "Ao derrotar elites, +15 de ouro garantido.", "icon": "🪙", "rarity": "uncommon", "unlock": "elite_hunter", "effect": "elite_gold"},
		{"id": "phoenix_feather", "name": "Pena de Fênix", "desc": "Uma vez por expedição, evita a morte com 1 de vida.", "icon": "🪶", "rarity": "legendary", "unlock": "legend", "effect": "death_prevention"},
		{"id": "shadow_cloak", "name": "Manto de Sombra", "desc": "Ao tomar dano, 15% de chance de ficar invisível por 1 segundo.", "icon": "🌑", "rarity": "epic", "unlock": "boss_killer", "effect": "shadow_dodge"},
	]

# ═══════════════════════════════════════════════════════════
# FORJA — Receitas de crafting
# ═══════════════════════════════════════════════════════════
func _build_forge_recipes() -> void:
	forge_recipes = [
		{
			"id": "forge_flame_sword", "result": "flame_sword", "result_name": "Espada Flamejante",
			"ingredients": [{"id": "field_blade", "name": "Lâmina de Vigília", "qty": 1}],
			"crystal_cost": 2, "gold_cost": 150,
			"desc": "Tempere a Lâmina de Vigília nas brasas eternas.",
			"rarity_result": "rare"
		},
		{
			"id": "forge_void_staff", "result": "void_staff", "result_name": "Cetro do Vazio",
			"ingredients": [{"id": "moon_staff", "name": "Cajado de Luar", "qty": 1}],
			"crystal_cost": 3, "gold_cost": 200,
			"desc": "Canalize energia do plano astral no Cajado de Luar.",
			"rarity_result": "epic"
		},
		{
			"id": "forge_shadow_bow", "result": "shadow_bow", "result_name": "Arco da Sombra",
			"ingredients": [{"id": "thorn_bow", "name": "Arco de Espinheiro", "qty": 1}],
			"crystal_cost": 2, "gold_cost": 160,
			"desc": "Envolva o Arco de Espinheiro na escuridão.",
			"rarity_result": "rare"
		},
		{
			"id": "forge_obsidian_helm", "result": "obsidian_helm", "result_name": "Elmo de Obsidiana",
			"ingredients": [{"id": "warden_helm", "name": "Elmo da Vigília", "qty": 1}],
			"crystal_cost": 2, "gold_cost": 120,
			"desc": "Reforce o Elmo da Vigília com rocha vulcânica.",
			"rarity_result": "rare"
		},
		{
			"id": "forge_dragonscale", "result": "dragonscale", "result_name": "Escama de Dragão",
			"ingredients": [
				{"id": "rootplate", "name": "Couraça de Raiz", "qty": 1},
				{"id": "obsidian_helm", "name": "Elmo de Obsidiana", "qty": 1}
			],
			"crystal_cost": 5, "gold_cost": 400,
			"desc": "A armadura mais resistente. Requer materiais raros.",
			"rarity_result": "epic"
		},
		{
			"id": "forge_void_walkers", "result": "void_walkers", "result_name": "Andantes do Vazio",
			"ingredients": [{"id": "wind_boots", "name": "Botas do Vendaval", "qty": 1}],
			"crystal_cost": 3, "gold_cost": 180,
			"desc": "Infunda as Botas do Vendaval com energia do vazio.",
			"rarity_result": "epic"
		},
		{
			"id": "forge_ring_of_ages", "result": "ring_of_ages", "result_name": "Anel das Eras",
			"ingredients": [
				{"id": "ember_signet", "name": "Sinete da Brasa", "qty": 1},
				{"id": "iron_oath", "name": "Anel do Juramento", "qty": 1}
			],
			"crystal_cost": 6, "gold_cost": 500,
			"desc": "Funda dois anéis poderosos em um artefato lendário.",
			"rarity_result": "legendary"
		},
		{
			"id": "forge_ancient_talisman", "result": "ancient_talisman", "result_name": "Talismã Ancestral",
			"ingredients": [{"id": "oak_charm", "name": "Amuleto de Carvalho", "qty": 2}],
			"crystal_cost": 4, "gold_cost": 300,
			"desc": "Combine dois Amuletos de Carvalho em um talismã ancestral.",
			"rarity_result": "legendary"
		},
	]

# ═══════════════════════════════════════════════════════════
# CONQUISTAS
# ═══════════════════════════════════════════════════════════
func _build_achievements() -> void:
	achievements = [
		# Combate
		{"id": "first_blood", "title": "PRIMEIRO SANGUE", "desc": "Derrote seu primeiro inimigo.", "reward_gold": 50, "reward_crystals": 0, "reward_relic": "", "icon": "⚔️", "category": "combat"},
		{"id": "slayer_100", "title": "CEIFADOR", "desc": "Derrote 100 inimigos no total.", "reward_gold": 100, "reward_crystals": 0, "reward_relic": "soul_lantern", "icon": "💀", "category": "combat"},
		{"id": "slayer_1000", "title": "LORDE DA BATALHA", "desc": "Derrote 1.000 inimigos no total.", "reward_gold": 300, "reward_crystals": 1, "reward_relic": "", "icon": "⚔️", "category": "combat"},
		{"id": "elite_hunter", "title": "CAÇADOR DE ELITES", "desc": "Derrote 10 inimigos de elite.", "reward_gold": 120, "reward_crystals": 0, "reward_relic": "deaths_coin", "icon": "🎯", "category": "combat"},
		{"id": "boss_killer", "title": "MATADOR DE REIS", "desc": "Derrote o Rei do Espinheiro.", "reward_gold": 200, "reward_crystals": 2, "reward_relic": "blood_pact", "icon": "👑", "category": "combat"},
		{"id": "no_damage_wave", "title": "FANTASMA", "desc": "Complete uma wave inteira sem tomar dano.", "reward_gold": 150, "reward_crystals": 1, "reward_relic": "", "icon": "👻", "category": "combat"},

		# Sobrevivência
		{"id": "survivor_10", "title": "SOBREVIVENTE", "desc": "Complete 10 ondas no total.", "reward_gold": 200, "reward_crystals": 0, "reward_relic": "cursed_eye", "icon": "🌊", "category": "survival"},
		{"id": "survivor_5", "title": "RESISTENTE", "desc": "Alcance a onda 5 em qualquer região.", "reward_gold": 80, "reward_crystals": 0, "reward_relic": "", "icon": "🛡️", "category": "survival"},
		{"id": "wave_master", "title": "MESTRE DAS ONDAS", "desc": "Alcance a onda 5 com Sentinela, Tecelã e Batedora.", "reward_gold": 300, "reward_crystals": 2, "reward_relic": "time_crystal", "icon": "🌊", "category": "survival"},
		{"id": "speed_run", "title": "CORISCO", "desc": "Complete 5 waves em menos de 4 minutos.", "reward_gold": 200, "reward_crystals": 1, "reward_relic": "", "icon": "⚡", "category": "survival"},

		# Riqueza
		{"id": "rich", "title": "MERCENÁRIO", "desc": "Acumule 1.000 de Ouro.", "reward_gold": 0, "reward_crystals": 1, "reward_relic": "golden_compass", "icon": "💰", "category": "wealth"},
		{"id": "very_rich", "title": "TESOUREIRO", "desc": "Acumule 5.000 de Ouro.", "reward_gold": 0, "reward_crystals": 3, "reward_relic": "", "icon": "🏦", "category": "wealth"},

		# Habilidades
		{"id": "beast_hunter", "title": "CAÇADOR DE BESTAS", "desc": "Derrote todos os tipos de inimigos comuns e elites.", "reward_gold": 200, "reward_crystals": 1, "reward_relic": "void_shard", "icon": "🗡️", "category": "mastery"},
		{"id": "lore_seeker", "title": "ESTUDIOSO", "desc": "Desbloqueie 5 habilidades diferentes em uma única partida.", "reward_gold": 150, "reward_crystals": 0, "reward_relic": "ancient_tome", "icon": "📖", "category": "mastery"},
		{"id": "legend", "title": "LENDA DE VESPERA", "desc": "Conquiste todas as 6 regiões.", "reward_gold": 500, "reward_crystals": 5, "reward_relic": "phoenix_feather", "icon": "⭐", "category": "mastery"},
		{"id": "warrior_mastery", "title": "SENTINELA MESTRE", "desc": "Complete 5 expedições como Sentinela.", "reward_gold": 250, "reward_crystals": 1, "reward_relic": "", "icon": "🗡️", "category": "mastery"},
		{"id": "mage_mastery", "title": "TECELÃ MESTRE", "desc": "Complete 5 expedições como Tecelã.", "reward_gold": 250, "reward_crystals": 1, "reward_relic": "", "icon": "✨", "category": "mastery"},
		{"id": "ranger_mastery", "title": "BATEDORA MESTRE", "desc": "Complete 5 expedições como Batedora.", "reward_gold": 250, "reward_crystals": 1, "reward_relic": "", "icon": "🏹", "category": "mastery"},

		{"id": "assassin_mastery","title": "LÂMINA MESTRE","desc": "Complete 5 expedições como Lâmina da Noite.","reward_gold": 250,"reward_crystals": 1,"reward_relic": "","icon": "","category": "mastery"},
		{"id": "druid_mastery","title": "GUARDIÃO MESTRE","desc": "Complete 5 expedições como Guardião da Seiva.","reward_gold": 250,"reward_crystals": 1,"reward_relic": "","icon": "","category": "mastery"},
		{"id": "paladin_mastery","title": "ARAUTO MESTRE","desc": "Complete 5 expedições como Arauto do Sol.","reward_gold": 250,"reward_crystals": 1,"reward_relic": "","icon": "","category": "mastery"},
		{"id": "region_hollow_cairn","title": "SILÊNCIO NAS CRIPTAS","desc": "Conquiste a Colina Oca.","reward_gold": 120,"reward_crystals": 1,"reward_relic": "","icon": "","category": "survival"},
		{"id": "region_ember_crater","title": "BRASA DOMADA","desc": "Conquiste a Cratera Rubra.","reward_gold": 160,"reward_crystals": 1,"reward_relic": "","icon": "","category": "survival"},
		{"id": "region_black_keep","title": "A AURORA RETORNA","desc": "Conquiste o Castelo Sem Aurora.","reward_gold": 200,"reward_crystals": 2,"reward_relic": "","icon": "","category": "survival"},
		{"id": "region_frostwood","title": "DEGELO","desc": "Conquiste o Bosque da Geada.","reward_gold": 240,"reward_crystals": 2,"reward_relic": "","icon": "","category": "survival"},
		{"id": "region_sunken_mire","title": "COROA DO CHARCO","desc": "Conquiste o Charco Esquecido.","reward_gold": 280,"reward_crystals": 3,"reward_relic": "","icon": "","category": "survival"},

		# Forja
		{"id": "first_forge", "title": "APRENDIZ DE FERREIRO", "desc": "Forje seu primeiro item.", "reward_gold": 100, "reward_crystals": 0, "reward_relic": "", "icon": "🔨", "category": "forge"},
		{"id": "master_forge", "title": "MESTRE FERREIRO", "desc": "Forje um item lendário.", "reward_gold": 300, "reward_crystals": 2, "reward_relic": "mirror_shield", "icon": "⚒️", "category": "forge"},
	]

# ═══════════════════════════════════════════════════════════
# UPGRADES PERMANENTES
# ═══════════════════════════════════════════════════════════
func _build_upgrades() -> void:
	upgrades = [
		{"id": "vitality", "name": "Sangue Antigo", "desc": "Vida máxima +5% por nível. Resistência que atravessa gerações.", "icon": "❤️", "base_cost": 80, "max_level": 10, "stat": "max_health_pct", "value_per_level": 0.05},
		{"id": "might", "name": "Aço Temperado", "desc": "Dano inicial +4% por nível. Golpes que ecoam pela floresta.", "icon": "⚔️", "base_cost": 95, "max_level": 10, "stat": "damage_pct", "value_per_level": 0.04},
		{"id": "fortune", "name": "Mão de Mercador", "desc": "Ouro e experiência +5% por nível. A sorte favorece os preparados.", "icon": "💰", "base_cost": 110, "max_level": 8, "stat": "fortune_pct", "value_per_level": 0.05},
		{"id": "resilience", "name": "Pele de Pedra", "desc": "Defesa +1 por nível. Cada ponto reduz o dano recebido diretamente.", "icon": "🛡️", "base_cost": 120, "max_level": 8, "stat": "defense_flat", "value_per_level": 1.0},
		{"id": "swiftness", "name": "Passos do Vento", "desc": "Velocidade de movimento +3% por nível. Velocidade é sobrevivência.", "icon": "💨", "base_cost": 90, "max_level": 10, "stat": "speed_pct", "value_per_level": 0.03},
		{"id": "crit_mastery", "name": "Fio do Caos", "desc": "Chance de crítico +2% por nível. Todo golpe pode ser fatal.", "icon": "🎯", "base_cost": 130, "max_level": 5, "stat": "crit_chance", "value_per_level": 0.02},
		{"id": "xp_boost", "name": "Memória Ancestral", "desc": "Experiência ganha +6% por nível. O passado fortalece o futuro.", "icon": "📚", "base_cost": 100, "max_level": 8, "stat": "xp_pct", "value_per_level": 0.06},
		{"id": "attack_speed", "name": "Ritmo do Predador", "desc": "Velocidade de ataque +3% por nível. Mais golpes por segundo.", "icon": "⚡", "base_cost": 115, "max_level": 8, "stat": "attack_speed_pct", "value_per_level": 0.03},
	]

# ═══════════════════════════════════════════════════════════
# CAÇADAS / BOUNTIES
# ═══════════════════════════════════════════════════════════
func _build_bounties() -> void:
	bounties = [
		{"id": "bounty_wolf", "title": "CAÇA AO LOBO", "desc": "Elimine 20 Lobos Cinzentos.", "target": "wolf", "target_count": 20, "reward_gold": 120, "reward_crystals": 1, "icon": "🐺", "difficulty": "normal"},
		{"id": "bounty_goblin", "title": "LIMPEZA DO BOSQUE", "desc": "Elimine 30 Catadores.", "target": "goblin", "target_count": 30, "reward_gold": 100, "reward_crystals": 0, "icon": "👺", "difficulty": "normal"},
		{"id": "bounty_elite", "title": "ELITE PERIGOSA", "desc": "Elimine 5 Rastreadores Alfa.", "target": "elite", "target_count": 5, "reward_gold": 200, "reward_crystals": 2, "icon": "💀", "difficulty": "hard"},
		{"id": "bounty_archer", "title": "SILENCIAR OS ARQUEIROS", "desc": "Elimine 15 Flechas Perdidas.", "target": "archer", "target_count": 15, "reward_gold": 80, "reward_crystals": 0, "icon": "🏹", "difficulty": "easy"},
		{"id": "bounty_mage", "title": "CAÇA AO BRUXO", "desc": "Elimine 10 Bruxos da Seiva.", "target": "mage", "target_count": 10, "reward_gold": 150, "reward_crystals": 1, "icon": "🔮", "difficulty": "normal"},
		{"id": "bounty_boss", "title": "REGICIDA", "desc": "Derrote o Rei do Espinheiro novamente.", "target": "goblin_king", "target_count": 1, "reward_gold": 400, "reward_crystals": 3, "icon": "👑", "difficulty": "legendary"},
	]

# ═══════════════════════════════════════════════════════════
# UTILITÁRIOS
# ═══════════════════════════════════════════════════════════
func get_relic(id: String) -> Dictionary:
	for r in relics:
		if r.id == id:
			return r
	return {}

func get_achievement(id: String) -> Dictionary:
	for a in achievements:
		if a.id == id:
			return a
	return {}

func get_upgrade(id: String) -> Dictionary:
	for u in upgrades:
		if u.id == id:
			return u
	return {}

func get_forge_recipe(id: String) -> Dictionary:
	return forge_index.get(id, {})
