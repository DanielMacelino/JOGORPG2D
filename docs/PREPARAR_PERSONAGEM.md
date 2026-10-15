# Preparar personagem

Os seis atalhos usam ilustrações próprias, reunidas em `assets/art/prepare-destinations.png`. Os recortes são definidos em `scripts/ui/menu/prepare_destinations.gd`, com margens internas para não misturar os quadros. O enquadramento de cada destino preserva as proporções da pintura e destaca o objeto principal acima das legendas.

| Atalho | Fundo |
| --- | --- |
| Personagem | Sala com pedestal, equipamentos e estandartes, com o asset estático da classe selecionada sobre o cenário |
| Arsenal | Armas, armaduras, escudos, botas e acessórios organizados em um arsenal |
| Talentos | Árvore fictícia com dezenas de nós e caminhos conectados |
| Melhorias | Pedestais ascendentes e símbolos de fortalecimento de atributos |
| Forja | Bigorna, martelo, metal incandescente, lingotes e fornalha |
| Relíquias | Lanterna, amuleto, grimório e bússola em um santuário de artefatos |

O retrato principal do Sentinela usa o mesmo componente de retrato estático dos demais personagens, com o recorte grande de `perso_tank.png`. O cenário da sala é um TextureRect separado, com filtragem linear; os personagens preservam a filtragem nearest e ficam parados no menu. O Arauto mantém a representação existente enquanto não recebe um novo asset.

O retângulo EQUIPAMENTO mostra a contagem e pequenos quadrados com os itens realmente equipados. A ordem é arma, elmo, armadura, botas, anel e amuleto, omitindo espaços vazios. Os quadros têm cor de raridade e tooltip com nome/atributos. Os dados vêm do inventário e do conjunto da classe exibida; trocar de personagem substitui também os ícones. A contagem não inclui itens ausentes, incompatíveis ou guardados sem equipar.

`tests/prepare_destinations.gd` verifica os seis fundos independentes, retrato nativo do Sentinela, seis slots equipados, troca para o inventário de outra classe, tooltips, limites dos ícones, legendas e navegação dos seis atalhos em seis resoluções e duas escalas. O armazenamento dos testes é isolado.

## Geração da arte

Ferramenta: imagegen integrada. Arquivo final: `assets/art/prepare-destinations.png`. A arte não contém textos ou botões; a interface e as áreas de clique continuam nativas.

Prompt final:

> Use case: stylized-concept. Asset type: production background illustration atlas for SIX clickable dark-fantasy RPG preparation menu cards. One wide landscape image, aspect ratio 12:5. EXACT regular grid THREE COLUMNS by TWO ROWS, six equal landscape cells, each card aspect ratio 8:5. NO gutters, NO borders, NO text, NO letters, NO numbers, NO buttons or other UI. Each cell must depict a DIFFERENT clearly recognizable destination, in the same finely hand-painted gothic RPG style with restrained teal-black shadows, tarnished brass, warm firelight and luminous magic. Keep important subjects in the UPPER TWO THIRDS of every cell, bottom third dark quiet for game labels. TOP LEFT CHARACTER: a stone dressing alcove with an empty round hero pedestal, hooded cloak and armor on stands, six hanging class banners; no actual human character, leave the pedestal empty for a native sprite overlay. TOP MIDDLE ARSENAL: a rich and orderly weapons armory, rack of swords, axe, bow with arrows, magical staff, shields and shelves of helmets, boots, armor and rings, clearly an inventory full of varied equipment. TOP RIGHT TALENTS: an unmistakable gigantic magical SKILL TREE diagram inside an ancient circular stone sanctuary, a central glowing gold node branching into dozens of connected blue, green and gold nodes, radial interconnected pathways, fictional non-text ability glyphs, no real letters. BOTTOM LEFT UPGRADES: a fantasy training and permanent empowerment shrine, a progression of ascending stone plinths with increasingly luminous crystals, a powerful engraved gauntlet, a heart-shaped ruby and winged boots displayed as stat-training equipment, golden motes ascending; no forge or anvil. BOTTOM MIDDLE FORGE: unmistakable working blacksmith forge, prominent iron ANVIL and large smithing HAMMER in foreground, glowing orange heated sword resting on anvil, roaring brick furnace and tongs in background, scattered metal ingots. BOTTOM RIGHT RELICS: sacred ancient artifact vault, three separate small pedestals with a glowing enchanted lantern, ornate crimson heart amulet, a floating ancient tome and small gilded compass, mystical teal and amber light, mossy stone. Every scene visually coherent, detailed and distinct, NO people, no random objects, no photorealism, not modern flat icons. Textures and materials carefully painted, clear silhouettes even at 300 pixels wide. Fill each exact grid cell edge-to-edge with its scene; do not blend scenes across cell boundaries.
