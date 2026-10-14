# Direção visual de Ashenwild

Floresta de Vespera: verde de pinho, musgo, marfim gasto e cobre. A arte usa silhuetas e planos recortados; detalhes claros indicam rostos, armas, ruínas e objetos de interesse. Cores de raridade seguem a mesma legenda nos catálogos e nas escolhas de nível.

- `scripts/ui/wild_theme.gd`: paleta, fontes, botões e controles.
- `assets/art/forest_panorama.svg`: ilustração do acampamento, desenhada para a composição do menu.
- `assets/art/home-portal.png`: pintura da nova home, seguindo a referência enviada. O título, ações, recursos, identidade e cinco cartões são controles do Godot; veja [a arte, o prompt e a composição](REGIOES_E_HOME.md).
- `assets/art/portraits/` e `assets/art/enemies/`: personagens usados no menu, no bestiário e na partida. As proporções são preservadas.
- `assets/art/icons/`: ícones de navegação e controles da interface.
- `assets/art/equipment/`: onze ícones de equipamentos, com armas próprias de cada classe e proporções preservadas.
- `scripts/ui/inventory_panel.gd` e `equipment_orbit.gd`: arsenal com personagem central, seis espaços ao redor e inventário lateral. Os filtros Todos, Armas, Elmos, Armaduras, Botas, Anéis e Amuletos também podem ser ativados clicando nos espaços. Equipar atualiza a lista e os espaços de equipamento sem reconstruir a página.
- `scripts/ui/ability_art.gd`: desenhos compartilhados pelas habilidades e pelas escolhas de nível.
- `scripts/world/forest_ground.gd`: trilha, chão, pedras, vegetação e círculo de ruínas. As posições e colisões originais de árvores e pedras foram preservadas.

Os menus ativos usam painéis desenhados pelo Godot e não dependem dos recortes da antiga folha `image.png`. O material antigo continua no projeto como referência. Georgia e Segoe UI têm alternativas de fontes para outros sistemas.

A interface adapta a composição à janela: cartões de classe em três colunas no desktop e uma em telas estreitas, controles compactos na partida e rolagem para catálogos longos. O menu também reduz a composição em janelas baixas.

Validação visual no Godot 4.7.2: páginas com progresso inicial e desbloqueado, partida, pausa e escolhas de nível em 1280×720, 1920×1080, 960×540, 540×900 e 390×844. Também foram conferidos texto a 120%, movimento e combate com as três classes e apresentação do chefe. A revisão final e o teste de combate terminaram sem erros ou avisos; os testes usaram uma cópia do projeto com armazenamento separado.

Prévias históricas do layout anterior: [menu](visuais/menu.png), [classes](visuais/classes.png) e [partida](visuais/partida.png).

A expansão mantém a mesma linguagem nos três novos viajantes, na árvore de talentos e nas novas criaturas. As seis regiões têm paletas e elementos próprios: vegetação, lápides, obsidiana, colunas, neve e juncos. Veja [a árvore](visuais/talentos.png), [as classes recrutáveis](visuais/classes-novas.png), [o Bosque da Geada](visuais/bosque-da-geada.png) e [o Charco Esquecido](visuais/charco-esquecido.png).

O novo arsenal segue a referência de personagem cercado por equipamentos e lista lateral, usando verde escuro, bordas douradas e cores de raridade. Em telas estreitas, as duas áreas ficam empilhadas. Esta alteração foi validada sem capturas de tela: testes de filtros, botões, equipamento separado por classe, persistência e limites dos controles em 1280×720, 960×540 e 390×844, com save isolado.

A revisão de contraste acrescenta contornos escuros nas criaturas, no personagem e nos projéteis, marcações quentes para inimigos e turquesa para aliados. Ouro e experiência têm bases escuras; os ataques sinalizados têm bordas completas mais claras. Textos secundários e bordas dos painéis também estão mais claros. As invocações preservam a proporção da arte e exibem seu tempo restante. Os cartões de habilidades ajustam a altura ao texto e ao total acumulado, verificados por medidas em desktop e tela estreita, sem imagens.
