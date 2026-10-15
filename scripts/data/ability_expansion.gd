extends RefCounted
## Six class-specific schools plus six shared schools, with seven tiers each: 294 skills.
const SCHOOLS := {
 "warrior": [["Reserva do Bastião", "bulwark", {"health_pct": 0.12, "defense": 0.6}], ["Muralha de Espinhos", "retribution", {"defense": 1.5, "thorns": 0.04}], ["Pulso de Ferro", "second_wind", {"health_pct": 0.10, "regen": 0.12}], ["Golpe de Falange", "razor_dance", {"cleave_targets": 1.0, "damage_pct": 0.04}], ["Marcha do Guardião", "iron_skin", {"health_pct": 0.08, "speed_pct": 0.03}], ["Disciplina do Cerco", "rapid_hands", {"attack_speed_pct": 0.08, "defense": 0.8}]],
 "mage": [["Geometria Arcana", "arcane_expansion", {"damage_pct": 0.10, "splash_radius": 8.0}], ["Horizonte Astral", "distant_star", {"range_pct": 0.10, "projectile_pierce": 1.0}], ["Corrente do Éter", "arcane_haste", {"attack_speed_pct": 0.10, "crit_chance": 0.02}], ["Manto Estelar", "iron_skin", {"health_pct": 0.08, "defense": 0.6}], ["Ressonância Celeste", "starfall", {"damage_pct": 0.12, "bonus_gold_xp": 0.03}], ["Passo do Cometa", "swift_feet", {"speed_pct": 0.06, "range_pct": 0.08}]],
 "ranger": [["Cordas de Tempestade", "wind_string", {"attack_speed_pct": 0.12, "range_pct": 0.05}], ["Ponta de Agulha", "fletching", {"projectile_pierce": 1.0, "damage_pct": 0.05}], ["Olhar da Rapina", "steady_aim", {"damage_pct": 0.06, "crit_chance": 0.03}], ["Trilha do Vendaval", "swift_feet", {"speed_pct": 0.07, "pickup_radius": 20.0}], ["Mira do Eclipse", "keen_eye", {"crit_chance": 0.04, "range_pct": 0.07}], ["Caçada Dourada", "lucky_find", {"damage_pct": 0.10, "bonus_gold_xp": 0.04}]],
 "assassin": [["Fio de Sangue", "razor_dance", {"cleave_targets": 1.0, "damage_pct": 0.05}], ["Cadência da Noite", "deadly_rhythm", {"attack_speed_pct": 0.14}], ["Pegadas do Vazio", "shadow_step", {"speed_pct": 0.06, "pickup_radius": 15.0}], ["Pacto Escarlate", "night_hunger", {"crit_chance": 0.04, "lifesteal": 0.004}], ["Couro de Penumbra", "iron_skin", {"health_pct": 0.06, "defense": 0.8}], ["Emboscada Silenciosa", "keen_edge", {"damage_pct": 0.10, "attack_speed_pct": 0.06}]],
 "druid": [["Cortejo da Seiva", "wolf_pack", {"summon_count": 1.0, "summon_duration": 1.0}], ["Raízes Eternas", "wild_growth", {"summon_duration": 2.0, "health_pct": 0.04}], ["Feras Ancestrais", "ancient_guardian", {"summon_damage_pct": 0.15}], ["Instinto da Matilha", "living_bark", {"summon_speed_pct": 0.10, "speed_pct": 0.03}], ["Círculo do Bosque", "roots_snare", {"summon_damage_pct": 0.12, "summon_duration": 1.0}], ["Seiva da Renovação", "vital_bloom", {"health_pct": 0.10, "regen": 0.15}]],
 "paladin": [["Couraça da Alvorada", "solar_armor", {"thorns": 0.05, "health_pct": 0.10}], ["Martelo do Meio-Dia", "oath_edge", {"damage_pct": 0.07, "attack_speed_pct": 0.07}], ["Voto da Recuperação", "restoring_light", {"defense": 1.0, "regen": 0.20}], ["Selo da Vitalidade", "lifesteal", {"lifesteal": 0.003, "damage_pct": 0.07}], ["Falange Radiante", "sunfire", {"cleave_targets": 1.0, "health_pct": 0.08}], ["Juízo da Aurora", "keen_edge", {"damage_pct": 0.09, "range_pct": 0.05}]],
 "shared": [["Fôlego do Viajante", "vital_bloom", {"health_pct": 0.08}], ["Ritmo da Jornada", "rapid_hands", {"attack_speed_pct": 0.08}], ["Passo da Estrada", "swift_feet", {"speed_pct": 0.05}], ["Corte Preciso", "keen_edge", {"damage_pct": 0.08}], ["Instinto de Fortuna", "lucky_find", {"bonus_gold_xp": 0.08, "pickup_radius": 12.0}], ["Abrigo da Vigília", "iron_skin", {"defense": 1.0, "regen": 0.10}]]}
static func populate(abilities: Dictionary) -> void:
	for owner in SCHOOLS:
		for school_index in SCHOOLS[owner].size():
			var school: Array = SCHOOLS[owner][school_index]
			for tier in ItemTiers.ORDER.size():
				var skill := AbilityData.new()
				skill.id = StringName("skill_%s_%d_%d" % [owner, school_index, tier])
				skill.school_id = "skill_%s_%d" % [owner, school_index]
				skill.display_name = "%s - %s" % [school[0], ItemTiers.label(ItemTiers.ORDER[tier])]
				skill.rarity = StringName(ItemTiers.ORDER[tier])
				skill.icon_id = StringName(school[1])
				skill.required_difficulty = ItemTiers.REQUIRED_DIFFICULTIES[tier]
				skill.required_run_level = [1, 2, 4, 7, 10, 14, 18][tier]
				if owner != "shared": skill.class_ids.append(StringName(owner))
				for key in school[2]:
					var amount: float = float(school[2][key]) * ItemTiers.SKILL_SCALE[tier]
					if key in ["cleave_targets", "projectile_pierce", "summon_count"]: amount = maxf(1.0, floorf(amount))
					skill.bonuses[key] = amount
				skill.description = _describe(skill.bonuses) + " por escolha."
				abilities[str(skill.id)] = skill
static func _describe(bonuses: Dictionary) -> String:
	var names := {"health_pct": "vida máxima", "defense": "defesa", "thorns": "retaliação", "regen": "vida/s", "cleave_targets": "alvos por ataque", "damage_pct": "dano", "speed_pct": "movimento", "attack_speed_pct": "ataque", "splash_radius": "área", "range_pct": "alcance", "projectile_pierce": "perfuração", "crit_chance": "crítico", "bonus_gold_xp": "ouro/XP", "pickup_radius": "coleta", "lifesteal": "roubo de vida", "summon_count": "brotos", "summon_duration": "s de invocação", "summon_damage_pct": "dano invocado", "summon_speed_pct": "ataque invocado"}
	var fixed := ["defense", "regen", "cleave_targets", "splash_radius", "projectile_pierce", "pickup_radius", "summon_count", "summon_duration"]
	var parts := PackedStringArray()
	for key in bonuses:
		var amount := float(bonuses[key]) * (1 if fixed.has(key) else 100)
		parts.append("+%s%s %s" % [("%.1f" % amount).trim_suffix(".0"), "" if fixed.has(key) else "%", names[key]])
	return ", ".join(parts)
