# Novos modelos dos personagens

| Folha | Personagem |
| --- | --- |
| perso_tank.png | Sentinela |
| perso_mage.png | Tecelã |
| perso_arqueiro.png | Batedora |
| perso_seiva.png | Guardião da Seiva |
| perso_loki.png | Lâmina da Noite |

Os originais estão em `assets/art/characters/sheets/`. O Arauto do Sol mantém o modelo articulado anterior até receber sua folha.

`character_sheet.gd` define recortes e pontos de apoio individuais: as imagens são painéis de referência, não grades regulares. Espera, caminhada, corrida com bônus de velocidade, ataque básico, conjuração especial, reação a dano e queda usam suas poses próprias. A morte toca uma vez e mantém o último quadro; reanimar restaura o estado normal. As imagens originais permanecem intactas.

Arqueira, Guardião e Loki têm quadriculado opaco. As texturas preparadas removem o fundo conectado às bordas e os pixels neutros muito claros dentro de arcos e espaços entre os membros. A borda misturada ao branco é descontaminada usando a cor dos pixels sólidos próximos e recuperando a transparência, sem simplesmente apagar o contorno. A barba de tom creme é preservada. A rotina compartilhada está em `sheet_background.gd`; os chefes brancos usam apenas a remoção conectada às bordas.

Em combate, `scenes/characters/sheet_character.tscn` fornece um Sprite2D reutilizável, sem colisões adicionais. AtlasTexture usa recortes limitados e filtro nearest. Escala uniforme, pivôs e espelhamento mantêm os pés no chão. Sentinela e Tecelã recebem os modelos de arma equipados nas mãos vazias da folha, incluindo o escudo correspondente do Sentinela. Batedora, Guardião e Lâmina usam as armas já desenhadas em suas poses. Atributos e efeitos de todos os equipamentos continuam funcionando.

Seleção de personagens, preparação, Arsenal, talentos e salas online usam o retrato estático maior da própria folha. Esses recortes têm 313–377 pixels de altura; os quadros menores de animação têm aproximadamente 100–116 pixels e ficam para o combate. Os retratos de menu não atualizam animação nem alternam poses, evitando saltos e reduzindo a ampliação. HUD e equipe usam recortes de rosto, preservando a proporção. Nenhum menu recebe uma folha inteira com títulos ou paleta de cores.

Na página inicial, o cartão PERSONAGEM abre a central de preparação com classes, Arsenal, talentos, melhorias, forja e relíquias. O botão PREPARAR PERSONAGEM redundante foi removido. Dentro da central, a seleção de classes continua acessível, e voltar mantém o histórico de navegação.

O cooperativo sincroniza o tipo de ataque e o tempo de queda, além dos estados de animação existentes. Protocolo `ashenwild-coop-14`: todos os participantes precisam da mesma versão. Texturas são preparadas e guardadas em cache antes da partida.

Validação: `tests/player_sheet_models.gd`, regressão de menus/progressão e teste ENet com atraso, variação e perda de pacotes. Testes de progresso usam armazenamento isolado. Esta atualização não altera atributos, colisões ou saves e não exporta executáveis.
