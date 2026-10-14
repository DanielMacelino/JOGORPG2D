# Tela de Registros

A página usa a referência enviada pelo usuário: fundo de floresta e castelo sob o luar, cabeçalho com bússola e Voltar, moedas, três cartões ilustrados na primeira linha e Estatísticas abaixo à esquerda. Os cartões têm ornamentos dourados, ícones vetoriais, títulos em marfim, setas e brilho suave no hover e foco de teclado.

Os contadores vêm do save: espécies descobertas no Bestiário, conquistas desbloqueadas e contratos de caça concluídos. Os denominadores usam o catálogo atual do jogo, em vez dos números ilustrativos da referência. Os botões abrem as páginas existentes; Voltar retorna a Registros.

O layout tem três colunas a partir de 900 pixels úteis, duas a partir de 580 e uma nas telas menores. A altura dos cartões acompanha o texto para evitar cortes. O fundo é exclusivo desta página; as folhas e partículas existentes continuam funcionando.

Implementação: `scripts/ui/menu/records_screen.gd`, roteamento em `scripts/main.gd` e fundo em `scripts/ui/menu/menu_background.gd`. O ícone de Bestiário é `assets/art/icons/records-bestiary.svg`.

As cinco ilustrações abaixo foram criadas com a ferramenta integrada imagegen e salvas no projeto. O anexo serviu como referência para as quatro primeiras; a arte de Bestiário foi a referência da variante de Caçadas. Não foram feitas capturas da tela do jogo.

## Prompts finais

`assets/art/records-background.png`

> Create ONLY the background artwork from the attached reference for a dark fantasy RPG records menu. Remove all UI, cards, borders, lettering, icons and numbers. Landscape 16:9 painting. Match the composition and palette closely: dark teal wooded valley, cliffs and river with reflected moonlight, ruined gothic castle on far upper right lit by a crescent moon, a cloaked traveler holding a warm lantern at far lower left, silhouetted tree branches framing edges. Left upper half very dark and quiet to accommodate UI, scenery opens toward lower right. Painterly detailed realistic fantasy concept art, restrained antique gold lights, no portal, no dragons, no text or interface.

`assets/art/records-bestiary.png`

> Create a single wide 16:9 dark fantasy game menu card illustration matching the attached reference's Bestiário card. No UI, lettering, icons, borders or numbers. A formidable dark forest dragon, sharp horned reptilian armored head and shoulder close-up on the right two thirds, turned toward the right, black and aged bronze scales, evergreen forest and silvery mist behind. Left third dark shadowed forest with little detail, for text overlay. Sophisticated realistic painterly fantasy, dark teal, moss, muted antique gold, dramatic natural rim light. Full bleed artwork.

`assets/art/records-achievements.png`

> Create a single wide 16:9 dark fantasy game menu card illustration matching the attached reference's Conquistas card. No UI, text, icons, borders or numbers. A weathered long black and antique gold heraldic banner hangs from a pole in a ruined castle courtyard on the right half, intricate abstract sun sigil (no lettering), distant gothic walls and forested hills, warm amber sunset seen through storm clouds. Left half deep shadow and subdued detail for interface overlays. Sophisticated realistic painterly fantasy matching muted teal and antique gold palette. Full bleed artwork.

`assets/art/records-statistics.png`

> Create a single wide 16:9 dark fantasy game menu card illustration matching the attached reference's Estatísticas card. No UI, lettering, icons, borders or numbers. Close-up of an explorer's wooden table on the right half with parchment map (drawn geography only, no words), a slim steel sword lying diagonally on map, compass, worn books, coins, warm candle at upper far right, dark gothic room. Left half deep dark shadow for interface overlays. Sophisticated realistic painterly fantasy in deep teal and amber candle light, antique gold accents, clear material textures. Full bleed artwork.

`assets/art/records-bounties.png`

> Create a matching variant of this artwork for the Caçadas menu card of the same fantasy RPG. A full winged dark forest dragon now perches on ruined stone on the right two thirds: raised enormous leathery wings, horns, armored neck, eyes with subtle antique gold glint, misty dark teal forest and ruined towers behind. Keep the left third very dark and quiet for UI text. Match the detailed realistic painterly technique and antique gold / teal mood of the supplied image. Wide 16:9, full bleed artwork only. No text, lettering, logos, icons or interface borders.

## Verificação

`tests/run_regression.ps1` verifica a largura e o ajuste dos cartões em oito resoluções e duas escalas da interface, os contadores reais, os quatro destinos e o retorno a Registros. O teste usa uma cópia temporária e save separado.
