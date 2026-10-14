extends RefCounted
## Display-only copy; ownership, unlocks and expedition rules remain in the catalog/save.
const EFFECTS := {
	"blood_pact": ["−20% de vida máxima", "+25% de dano causado"],
	"golden_compass": ["+35% de ouro coletado", "Mais encontros com itens especiais"],
	"iron_heart": ["+6 de defesa", "Sem regeneração natural de vida"],
	"cursed_eye": ["+15% de chance de crítico", "Inimigos 10% mais rápidos"],
	"void_shard": ["Explosão de vazio a cada 5 abates"],
	"ancient_tome": ["Habilidades 30% mais fortes", "+50% de XP exigido pelas habilidades"],
	"soul_lantern": ["Recupera 0,5 de vida por abate"],
	"mirror_shield": ["Reflete 20% do dano recebido"],
	"time_crystal": ["Lentidão por 3 s no início de cada onda"],
	"deaths_coin": ["+15 de ouro ao derrotar uma elite"],
	"phoenix_feather": ["Evita a morte com 1 de vida", "Uma ativação por expedição"],
	"shadow_cloak": ["15% de chance de invisibilidade ao sofrer dano", "Invisibilidade dura 1 s"]
}
const QUOTES := {
	"blood_pact": "O preço da força é alto, mas o sangue sempre paga.",
	"golden_compass": "Nem todo caminho leva para casa. Alguns levam à fortuna.",
	"iron_heart": "Aquilo que não se quebra também precisa aprender a sentir.",
	"cursed_eye": "Enxergar além do véu é permitir que ele enxergue de volta.",
	"void_shard": "Até o silêncio deixa cicatrizes.",
	"ancient_tome": "O saber exige tempo. O poder exige ainda mais.",
	"soul_lantern": "Nenhuma centelha se perde enquanto houver quem a carregue.",
	"mirror_shield": "A violência sempre encontra o caminho de volta.",
	"time_crystal": "Um instante pode ser tudo o que resta.",
	"deaths_coin": "Uma dívida que nem a morte esquece.",
	"phoenix_feather": "O fim é apenas a primeira das cinzas.",
	"shadow_cloak": "A noite protege aqueles que aprendem a desaparecer."
}

static func texture(id: String, owned: bool = true) -> Texture2D:
	var path := "res://assets/art/relics/%s.svg" % (id if owned else "locked")
	return load(path) as Texture2D if ResourceLoader.exists(path) else preload("res://assets/art/relics/locked.svg")
