# Preparar personagem

A página segue a referência fornecida: cabeçalho com retorno e moedas, painel da classe à esquerda, seis módulos à direita e resumo na base. Em telas menores, o painel fica acima dos módulos e os cartões passam de duas colunas para uma. Textos maiores aumentam a altura dos cartões conforme necessário.

O retrato, nome, nível e descrição acompanham a classe selecionada. Vida, dano e passo são os atributos base da classe, identificados no painel. Equipamentos e pontos disponíveis vêm do save da classe; o destino usa a região e fase selecionadas. O contador de equipamento usa seis espaços, conforme o inventário do jogo.

Personagem, Arsenal, Talentos, Melhorias, Forja, Relíquias e Ver personagem abrem suas respectivas páginas. A interface permanece em controles nativos do Godot, sem textos incorporados nas imagens.

## Arte

Foram criadas duas pinturas com a ferramenta integrada `image_gen` e copiadas para o projeto:

- [prepare-sentinel.png](../assets/art/prepare-sentinel.png): retrato do Sentinela. As demais classes usam seus retratos existentes.
- [prepare-workshop.png](../assets/art/prepare-workshop.png): oficina, usada com recortes distintos nos módulos Arsenal, Melhorias e Forja.

Os outros módulos reutilizam a pintura da floresta e os ícones existentes. Não foram feitas capturas de tela do jogo.

### Prompt da oficina

> Use case: stylized-concept. Asset type: landscape background painting for Arsenal, Forge and Upgrades navigation cards in Ashenwild. Match the latest attached prepare character screen atmosphere: painterly dark fantasy, deep forest green shadows, weathered amber gold highlights. A medieval ruined woodland workshop: weapons resting on a wooden workbench on the left, a large anvil and small glowing forge on the right, candles, stone arches and hanging tools. No people. Wide coherent scene, restrained light, detailed natural textures, readable silhouettes. Lower third very dark and quiet to allow live interface text. No text, lettering, interface, frames, logos or watermark. 1536x1024 landscape.

### Prompt do Sentinela

> Use case: stylized-concept. Asset type: vertical full-body Sentinel character painting for Ashenwild prepare character panel. Reference: latest user attached prepare screen, left character illustration. A solitary knight in weathered ivory steel plate armor with a closed helmet, muted red cloak, carrying a tall kite shield with a restrained gold diamond emblem and a sword. Full figure including boots, standing on a round mossy stone platform in ancient dark green woodland ruins, a hanging burgundy banner on the left. Painterly dark fantasy, detailed grounded materials, subdued forest green and warm antique gold palette, readable armor silhouette, no exaggerated proportions, no cartoon. Character centered with generous space above helmet and below feet, boots above lower 15 percent. Vertical 1024x1536. No text, typography, UI, panel borders, watermark or logo.

## Verificação

`tests/regional_features.gd` verifica oito resoluções com texto a 100% e 120%, largura da página e cartões, espaço para descrições, identidade das seis classes e funcionamento dos seis atalhos. O harness usa um save separado: `powershell -ExecutionPolicy Bypass -File tests/run_regression.ps1`.
