# Mundos

A página segue a referência de atlas: mapa em pergaminho ao fundo, seis regiões em cards compactos à esquerda e um painel com borda dupla e cantos ornamentados à direita. O panorama usa um recorte próprio do mapa para cada região. Os nomes, chefes e achados regionais vêm do catálogo existente.

As dez fases são marcos desenhados pela Godot: vilarejos, torres, fortalezas e altares, com um portal na fase 5 e uma fortaleza soberana na fase 10. Os telhados acompanham o bioma. Conclusões recebem marcas verdes; a seleção tem aro dourado e uma pulsação discreta; bloqueios usam cadeados e cores apagadas. Não há estrelas de desempenho fictícias. Abaixo ficam a legenda dos quatro trechos da jornada, o objetivo, o guardião, três recompensas e a entrada na fase.

O seletor mantém as dificuldades existentes e mostra o avanço de cada campanha. As dificuldades futuras ficam bloqueadas até completar as dez fases dos seis mundos na anterior: 60 fases. Repetir uma fase não conta como uma conclusão diferente. A próxima dificuldade começa em zero sem apagar as conclusões da anterior.

É possível inspecionar uma região bloqueada sem alterar a fase jogável salva. Selecionar uma fase disponível persiste o destino. O botão de início valida novamente a disponibilidade e lança a região/fase exibida, mesmo se outro destino estava salvo antes da inspeção.

Em telas estreitas, as abas Mundos e Fases e Missão alternam o conteúdo. Em janelas baixas, o cabeçalho, o panorama e os detalhes ficam mais compactos. Na resolução de referência, 1024 × 578, a legenda e as recompensas permanecem visíveis. Apenas janelas muito baixas, menores que 470 pixels, omitem detalhes secundários. A página não usa rolagem. A previsão do chefe mostra a faixa real de ouro com o multiplicador da fase, cristais e equipamento regional possível; os ganhos das ondas são adicionais.

`tests/worlds_screen.gd` verifica seis resoluções e duas escalas, o fundo de atlas, os biomas dos marcos, recompensas e legenda visíveis, áreas de clique, limites da janela, inspeção bloqueada, seleção e início reais, persistência, navegação e a passagem de 59 para 60 fases antes da liberação da nova dificuldade. Os testes usam armazenamento isolado. Não são necessárias capturas de tela.

## Arte do atlas

Arquivo: `assets/art/world-atlas.png`. Criado com a ferramenta integrada de imagegen. A imagem é apenas cenário; textos, progresso, botões, marcos e bloqueios são elementos nativos. O arquivo usa filtragem linear para preservar o detalhe da ilustração em diferentes tamanhos.

O conteúdo da página e o preenchimento dos painéis usam 100% de opacidade. O fundo externo não atravessa o painel das fases nem as recompensas. As ilustrações do próprio panorama e das miniaturas continuam visíveis nas áreas destinadas à arte.

Prompt final:

> Use case: stylized-concept. Asset type: production game background illustration for a dark fantasy RPG world-selection interface, landscape 16:9. Create ONLY an illustrated fantasy cartographic map, without ANY typography, letters, numbers, UI panels, borders, controls, labels or icons. Traditional ink and muted watercolor painted on aged olive tan parchment, fine black hand-drawn mountain contours and clusters of evergreen trees, winding blue-green river diagonally from upper right towards lower center, tiny gothic ruined castles, a cemetery and crypts beside the river in the right center, a volcanic crater upper right, snow-covered mountain forests near the top, marshes at bottom right. The map fills the entire canvas edge-to-edge; enough detail to crop for regional banners. Leftmost quarter shaded naturally dark teal by forest shadows, with a very small hooded traveler holding a warm lantern at bottom left, as in an old adventure atlas. Earthy restrained colors, warm faded parchment, dark ink, moss green forests, teal river, delicate antique engraving details, atmospheric yet clear silhouettes. Flat aerial illustrated map, not a realistic aerial photograph or a 3D rendered world. Main map features concentrated on the right two-thirds so dark interface panels will be readable over it. No text or decorative compass.
